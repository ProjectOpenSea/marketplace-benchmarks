// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

import "./WyvernStructs.sol";
import "./ArrayUtils.sol";

uint256 constant EIP712_Order_size = 0x180;
uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_OrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;
uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

contract WyvernTypeHashes {
    bytes32 internal constant _NAME_HASH =
        0x9a2ed463836165738cfa54208ff6e7847fd08cbaac309aac057086cb0a144d13;
    bytes32 internal constant _VERSION_HASH =
        0xe2fd538c762ee69cab09ccd70e2438075b7004dd87577dc3937e9fcc8174bb64;
    bytes32 internal constant _EIP_712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 internal constant _ORDER_TYPEHASH =
        0xdba08a88a748f356e8faf8578488343eab21b1741728779c9dcfdc782bc800f8;
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    address internal constant wyvernAddress =
        0x7f268357A8c2552623316e2562D90e642bB538E5;

    constructor() {
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();
    }

    /**
     * @dev Derive the domain separator for EIP-712 signatures.
     * @return The domain separator.
     */
    function _deriveDomainSeparator() internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH,
                    1,
                    wyvernAddress
                )
            );
    }

    function _deriveEIP712Digest(bytes32 orderHash)
        internal
        view
        returns (bytes32 value)
    {
        bytes32 domainSeparator = _DOMAIN_SEPARATOR;
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(EIP712_OrderHash_offset, orderHash)

            // Hash the relevant region (65 bytes).
            value := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_OrderHash_offset, 0)
        }
    }

    function hashOrder(Order memory order, uint256 counter)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = 800;
        bytes memory array = new bytes(size);
        uint256 index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes32(index, _ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.target);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order._calldata)
        );
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.replacementPattern)
        );
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.staticExtradata)
        );
        index = ArrayUtils.unsafeWriteAddressWord(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        index = ArrayUtils.unsafeWriteUint(index, counter);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }
}
