// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Vm } from "forge-std/Vm.sol";

import "./Constants.sol";
import { TakeAsk, TakeBid, TakeAskSingle, TakeBidSingle, FeeRate, Order, OrderType, AssetType, Listing } from "./Structs.sol";

import { BaseMarketConfig } from "../../../BaseMarketConfig.sol";

address constant VM_ADDRESS = address(
    uint160(uint256(keccak256("hevm cheat code")))
);
Vm constant vm = Vm(VM_ADDRESS);

contract Oracle {
    error ExpiredOracleSignature();
    error UnauthorizedOracle();
    error InvalidOracleSignature();

    uint256 internal oraclePk = 0x0fac1e;
    address payable internal oracle = payable(vm.addr(oraclePk));

    function produceOracleSignature(bytes32 _hash, uint32 blockNumber)
        public
        view
        returns (bytes memory signature)
    {
        // uint256 constant OracleSignatures_size = 0x59;
        // uint256 constant OracleSignatures_s_offset = 0x20;
        // uint256 constant OracleSignatures_v_offset = 0x40;
        // uint256 constant OracleSignatures_blockNumber_offset = 0x41;
        // uint256 constant OracleSignatures_oracle_offset = 0x45;

        bytes32 digest = keccak256(abi.encodePacked(_hash, blockNumber));

        bytes memory toBeSigned = abi.encodePacked(digest, blockNumber, oracle);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            oraclePk,
            bytes32(toBeSigned)
        );

        signature = abi.encodePacked(r, s, v, blockNumber, oracle);

        verifyOracleSignature(_hash, signature);

        return signature;
    }

    function verifyOracleSignature(bytes32 _hash, bytes memory oracleSignature)
        public
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint32 blockNumber;

        bytes memory signature = oracleSignature;
        assembly {
            r := mload(add(0x20, signature))
            s := mload(add(0x40, signature))
            v := shr(Bytes1_shift, mload(add(0x60, signature)))
            blockNumber := shr(Bytes4_shift, mload(add(0x61, signature)))
            // oracle := shr(Bytes20_shift, calldataload(add(signatureOffset, OracleSignatures_oracle_offset)))
        }

        if (blockNumber + 0 < block.number) {
            revert ExpiredOracleSignature();
        }

        // If there's an issue on chain and not in this function, it's probably
        // related to oracle identity or auth.
        // if (oracles[oracle] == 0) {
        //     revert UnauthorizedOracle();
        // }
        if (
            !_verify(
                oracle,
                keccak256(abi.encodePacked(_hash, blockNumber)),
                v,
                r,
                s
            )
        ) {
            revert InvalidOracleSignature();
        }
    }

    /**
     * @notice Verify signature of digest
     * @param signer Address of expected signer
     * @param digest Signature digest
     * @param v v parameter
     * @param r r parameter
     * @param s s parameter
     */
    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (bool valid) {
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner != address(0) && recoveredSigner == signer) {
            valid = true;
        }
    }
}
