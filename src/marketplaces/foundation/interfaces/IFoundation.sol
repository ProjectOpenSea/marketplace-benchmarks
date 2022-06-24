// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IFoundation {
    function setBuyPrice(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external;

    function buyV2(
        address nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        address payable buyReferrer
    ) external payable;
}
