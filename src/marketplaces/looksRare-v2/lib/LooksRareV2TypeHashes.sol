// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OrderStructs } from "./OrderStructs.sol";

contract LooksRareV2TypeHashes {
    using OrderStructs for OrderStructs.Maker;

    bytes32 public constant DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x9e6bc51ef68b436657c5fe7a273ea9121a02b234cc81ad1e04892649c9168c6a, // keccak256("LooksRareProtocol")
                0xad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5, // keccak256(bytes("2"))
                1,
                0x0000000000E655fAe4d56241588680F86E3b2377 // mainnet LooksRare protocol address
            )
        );

    function _deriveOrderDigest(OrderStructs.Maker memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        bytes32 orderHash = makerOrder.hash();
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)
            );
    }
}
