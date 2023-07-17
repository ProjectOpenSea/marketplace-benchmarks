// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Vm } from "forge-std/Vm.sol";

address constant VM_ADDRESS = address(
    uint160(uint256(keccak256("hevm cheat code")))
);
Vm constant vm = Vm(VM_ADDRESS);

contract Oracle {
    error ExpiredOracleSignature();
    error InvalidOracleSignature();

    uint256 constant Bytes1_shift = 0xf8;
    uint256 constant Bytes4_shift = 0xe0;

    uint256 public oraclePk = 0x07ac1e;
    address payable internal oracle = payable(vm.addr(oraclePk));

    function produceOracleSignature(bytes32 _hash, uint32 blockNumber)
        public
        view
        returns (bytes memory signature)
    {
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
        }

        if (blockNumber + 0 < block.number) {
            revert ExpiredOracleSignature();
        }

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
