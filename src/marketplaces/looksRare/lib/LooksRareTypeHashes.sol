// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OrderTypes } from "./OrderTypes.sol";

contract LooksRareTypeHashes {
    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    bytes32 public constant DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0xda9101ba92939daf4bb2e18cd5f942363b9297fbc3232c9dd964abb1fb70ed71, // keccak256("LooksRareExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                1,
                0x59728544B08AB483533076417FbBB2fD0B17CE3a // mainnet LooksRare exchange address
            )
        );

    function _deriveOrderDigest(OrderTypes.MakerOrder memory makerOrder)
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
