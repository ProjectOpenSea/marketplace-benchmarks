// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (metatx/ERC2771Forwarder.sol)

pragma solidity ^0.8.19;

import {ECDSAUpgradeable} from "../utils/cryptography/ECDSAUpgradeable.sol";
import {EIP712Upgradeable} from "../utils/cryptography/EIP712Upgradeable.sol";
import {NoncesUpgradeable} from "../utils/NoncesUpgradeable.sol";
import {AddressUpgradeable} from "../utils/AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev A forwarder compatible with ERC2771 contracts. See {ERC2771Context}.
 *
 * This forwarder operates on forward requests that include:
 *
 * * `from`: An address to operate on behalf of. It is required to be equal to the request signer.
 * * `to`: The address that should be called.
 * * `value`: The amount of native token to attach with the requested call.
 * * `gas`: The amount of gas limit that will be forwarded with the requested call.
 * * `nonce`: A unique transaction ordering identifier to avoid replayability and request invalidation.
 * * `deadline`: A timestamp after which the request is not executable anymore.
 * * `data`: Encoded `msg.data` to send with the requested call.
 *
 * Relayers are able to submit batches if they are processing a high volume of requests. With high
 * throughput, relayers may run into limitations of the chain such as limits on the number of
 * transactions in the mempool. In these cases the recommendation is to distribute the load among
 * multiple accounts.
 *
 * ==== Security Considerations
 *
 * If a relayer submits a forward request, it should be willing to pay up to 100% of the gas amount
 * specified in the request. This contract does not implement any kind of retribution for this gas,
 * and it is assumed that there is an out of band incentive for relayers to pay for execution on
 * behalf of signers. Often, the relayer is operated by a project that will consider it a user
 * acquisition cost.
 *
 * By offering to pay for gas, relayers are at risk of having that gas used by an attacker toward
 * some other purpose that is not aligned with the expected out of band incentives. If you operate a
 * relayer, consider whitelisting target contracts and function selectors. When relaying ERC-721 or
 * ERC-1155 transfers specifically, consider rejecting the use of the `data` field, since it can be
 * used to execute arbitrary code.
 */
contract ERC2771ForwarderUpgradeable is Initializable, EIP712Upgradeable, NoncesUpgradeable {
    using ECDSAUpgradeable for bytes32;

    struct ForwardRequestData {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint48 deadline;
        bytes data;
        bytes signature;
    }

    bytes32 internal constant _FORWARD_REQUEST_TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"
        );

    /**
     * @dev Emitted when a `ForwardRequest` is executed.
     *
     * NOTE: An unsuccessful forward request could be due to an invalid signature, an expired deadline,
     * or simply a revert in the requested call. The contract guarantees that the relayer is not able to force
     * the requested call to run out of gas.
     */
    event ExecutedForwardRequest(address indexed signer, uint256 nonce, bool success);

    /**
     * @dev The request `from` doesn't match with the recovered `signer`.
     */
    error ERC2771ForwarderInvalidSigner(address signer, address from);

    /**
     * @dev The `requestedValue` doesn't match with the available `msgValue`.
     */
    error ERC2771ForwarderMismatchedValue(uint256 requestedValue, uint256 msgValue);

    /**
     * @dev The request `deadline` has expired.
     */
    error ERC2771ForwarderExpiredRequest(uint48 deadline);

    /**
     * @dev See {EIP712-constructor}.
     */
    function __ERC2771Forwarder_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC2771Forwarder_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev Returns `true` if a request is valid for a provided `signature` at the current block timestamp.
     *
     * A transaction is considered valid when it hasn't expired (deadline is not met), and the signer
     * matches the `from` parameter of the signed request.
     *
     * NOTE: A request may return false here but it won't cause {executeBatch} to revert if a refund
     * receiver is provided.
     */
    function verify(ForwardRequestData calldata request) public view virtual returns (bool) {
        (bool alive, bool signerMatch, ) = _validate(request);
        return alive && signerMatch;
    }

    /**
     * @dev Executes a `request` on behalf of `signature`'s signer using the ERC-2771 protocol. The gas
     * provided to the requested call may not be exactly the amount requested, but the call will not run
     * out of gas. Will revert if the request is invalid or the call reverts, in this case the nonce is not consumed.
     *
     * Requirements:
     *
     * - The request value should be equal to the provided `msg.value`.
     * - The request should be valid according to {verify}.
     */
    function execute(ForwardRequestData calldata request) public payable virtual {
        // We make sure that msg.value and request.value match exactly.
        // If the request is invalid or the call reverts, this whole function
        // will revert, ensuring value isn't stuck.
        if (msg.value != request.value) {
            revert ERC2771ForwarderMismatchedValue(request.value, msg.value);
        }

        if (!_execute(request, true)) {
            revert AddressUpgradeable.FailedInnerCall();
        }
    }

    /**
     * @dev Batch version of {execute} with optional refunding and atomic execution.
     *
     * In case a batch contains at least one invalid request (see {verify}), the
     * request will be skipped and the `refundReceiver` parameter will receive back the
     * unused requested value at the end of the execution. This is done to prevent reverting
     * the entire batch when a request is invalid or has already been submitted.
     *
     * If the `refundReceiver` is the `address(0)`, this function will revert when at least
     * one of the requests was not valid instead of skipping it. This could be useful if
     * a batch is required to get executed atomically (at least at the top-level). For example,
     * refunding (and thus atomicity) can be opt-out if the relayer is using a service that avoids
     * including reverted transactions.
     *
     * Requirements:
     *
     * - The sum of the requests' values should be equal to the provided `msg.value`.
     * - All of the requests should be valid (see {verify}) when `refundReceiver` is the zero address.
     *
     * NOTE: Setting a zero `refundReceiver` guarantees an all-or-nothing requests execution only for
     * the first-level forwarded calls. In case a forwarded request calls to a contract with another
     * subcall, the second-level call may revert without the top-level call reverting.
     */
    function executeBatch(ForwardRequestData[] calldata requests, address payable refundReceiver)
        public
        payable
        virtual
    {
        bool atomic = refundReceiver == address(0);

        uint256 requestsValue;
        uint256 refundValue;

        for (uint256 i; i < requests.length; ++i) {
            requestsValue += requests[i].value;
            bool success = _execute(requests[i], atomic);
            if (!success) {
                refundValue += requests[i].value;
            }
        }

        // The batch should revert if there's a mismatched msg.value provided
        // to avoid request value tampering
        if (requestsValue != msg.value) {
            revert ERC2771ForwarderMismatchedValue(requestsValue, msg.value);
        }

        // Some requests with value were invalid (possibly due to frontrunning).
        // To avoid leaving ETH in the contract this value is refunded.
        if (refundValue != 0) {
            // We know refundReceiver != address(0) && requestsValue == msg.value
            // meaning we can ensure refundValue is not taken from the original contract's balance
            // and refundReceiver is a known account.
            AddressUpgradeable.sendValue(refundReceiver, refundValue);
        }
    }

    /**
     * @dev Validates if the provided request can be executed at current block timestamp with
     * the given `request.signature` on behalf of `request.signer`.
     */
    function _validate(ForwardRequestData calldata request)
        internal
        view
        virtual
        returns (
            bool alive,
            bool signerMatch,
            address signer
        )
    {
        signer = _recoverForwardRequestSigner(request);
        return (request.deadline >= block.timestamp, signer == request.from, signer);
    }

    /**
     * @dev Recovers the signer of an EIP712 message hash for a forward `request` and its corresponding `signature`.
     * See {ECDSA-recover}.
     */
    function _recoverForwardRequestSigner(ForwardRequestData calldata request) internal view virtual returns (address) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _FORWARD_REQUEST_TYPEHASH,
                        request.from,
                        request.to,
                        request.value,
                        request.gas,
                        nonces(request.from),
                        request.deadline,
                        keccak256(request.data)
                    )
                )
            ).recover(request.signature);
    }

    /**
     * @dev Validates and executes a signed request returning the request call `success` value.
     *
     * Internal function without msg.value validation.
     *
     * Requirements:
     *
     * - The caller must have provided enough gas to forward with the call.
     * - The request must be valid (see {verify}) if the `requireValidRequest` is true.
     *
     * Emits an {ExecutedForwardRequest} event.
     *
     * IMPORTANT: Using this function doesn't check that all the `msg.value` was sent, potentially
     * leaving value stuck in the contract.
     */
    function _execute(ForwardRequestData calldata request, bool requireValidRequest)
        internal
        virtual
        returns (bool success)
    {
        (bool alive, bool signerMatch, address signer) = _validate(request);

        // Need to explicitly specify if a revert is required since non-reverting is default for
        // batches and reversion is opt-in since it could be useful in some scenarios
        if (requireValidRequest) {
            if (!alive) {
                revert ERC2771ForwarderExpiredRequest(request.deadline);
            }

            if (!signerMatch) {
                revert ERC2771ForwarderInvalidSigner(signer, request.from);
            }
        }

        // Ignore an invalid request because requireValidRequest = false
        if (signerMatch && alive) {
            // Nonce should be used before the call to prevent reusing by reentrancy
            uint256 currentNonce = _useNonce(signer);

            (success, ) = request.to.call{gas: request.gas, value: request.value}(
                abi.encodePacked(request.data, request.from)
            );

            _checkForwardedGas(gasleft(), request);

            emit ExecutedForwardRequest(signer, currentNonce, success);
        }
    }

    /**
     * @dev Checks if the requested gas was correctly forwarded to the callee.
     *
     * As a consequence of https://eips.ethereum.org/EIPS/eip-150[EIP-150]:
     * - At most `gasleft() - floor(gasleft() / 64)` is forwarded to the callee.
     * - At least `floor(gasleft() / 64)` is kept in the caller.
     *
     * It reverts consuming all the available gas if the forwarded gas is not the requested gas.
     *
     * IMPORTANT: The `gasLeft` parameter should be measured exactly at the end of the forwarded call.
     * Any gas consumed in between will make room for bypassing this check.
     */
    function _checkForwardedGas(uint256 gasLeft, ForwardRequestData calldata request) private pure {
        // To avoid insufficient gas griefing attacks, as referenced in https://ronan.eth.limo/blog/ethereum-gas-dangers/
        //
        // A malicious relayer can attempt to shrink the gas forwarded so that the underlying call reverts out-of-gas
        // but the forwarding itself still succeeds. In order to make sure that the subcall received sufficient gas,
        // we will inspect gasleft() after the forwarding.
        //
        // Let X be the gas available before the subcall, such that the subcall gets at most X * 63 / 64.
        // We can't know X after CALL dynamic costs, but we want it to be such that X * 63 / 64 >= req.gas.
        // Let Y be the gas used in the subcall. gasleft() measured immediately after the subcall will be gasleft() = X - Y.
        // If the subcall ran out of gas, then Y = X * 63 / 64 and gasleft() = X - Y = X / 64.
        // Under this assumption req.gas / 63 > gasleft() is true is true if and only if
        // req.gas / 63 > X / 64, or equivalently req.gas > X * 63 / 64.
        // This means that if the subcall runs out of gas we are able to detect that insufficient gas was passed.
        //
        // We will now also see that req.gas / 63 > gasleft() implies that req.gas >= X * 63 / 64.
        // The contract guarantees Y <= req.gas, thus gasleft() = X - Y >= X - req.gas.
        // -    req.gas / 63 > gasleft()
        // -    req.gas / 63 >= X - req.gas
        // -    req.gas >= X * 63 / 64
        // In other words if req.gas < X * 63 / 64 then req.gas / 63 <= gasleft(), thus if the relayer behaves honestly
        // the forwarding does not revert.
        if (gasLeft < request.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
