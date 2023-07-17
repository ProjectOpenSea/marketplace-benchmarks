// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";

contract BlurV2TypeHashes {
    mapping(address => uint256) public nonces;

    bytes32 public constant DOMAIN_SEPARATOR =
        0xdd526a4e59bb74d0e4e4ab849ded32647b3bcf1df3acc01f4c21e76a8018c7c9;

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address trader,address collection,bytes32 listingsRoot,uint256 numberOfListings,uint256 expirationTime,uint8 assetType,FeeRate makerFee,uint256 salt,uint8 orderType,uint256 nonce)FeeRate(address recipient,uint16 rate)"
        );

    bytes32 FEE_TYPEHASH = keccak256("FeeRate(address recipient,uint16 rate)");
}
