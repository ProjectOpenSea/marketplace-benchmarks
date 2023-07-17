// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

struct TakeAsk {
    Order[] orders;
    Exchange[] exchanges;
    FeeRate takerFee;
    bytes signatures;
    address tokenRecipient;
}

struct TakeAskSingle {
    Order order;
    Exchange exchange;
    FeeRate takerFee;
    bytes signature;
    address tokenRecipient;
}

struct TakeBid {
    Order[] orders;
    Exchange[] exchanges;
    FeeRate takerFee;
    bytes signatures;
}

struct TakeBidSingle {
    Order order;
    Exchange exchange;
    FeeRate takerFee;
    bytes signature;
}

enum AssetType {
    ERC721,
    ERC1155
}

enum OrderType {
    ASK,
    BID
}

struct Exchange {
    // Size: 0x80
    uint256 index; // 0x00
    bytes32[] proof; // 0x20
    Listing listing; // 0x40
    Taker taker; // 0x60
}

struct Listing {
    // Size: 0x80
    uint256 index; // 0x00
    uint256 tokenId; // 0x20
    uint256 amount; // 0x40
    uint256 price; // 0x60
}

struct Taker {
    // Size: 0x40
    uint256 tokenId; // 0x00
    uint256 amount; // 0x20
}

struct Order {
    // Size: 0x100
    address trader; // 0x00
    address collection; // 0x20
    bytes32 listingsRoot; // 0x40
    uint256 numberOfListings; // 0x60
    uint256 expirationTime; // 0x80
    AssetType assetType; // 0xa0
    FeeRate makerFee; // 0xc0
    uint256 salt; // 0xe0
}

struct Fees {
    // Size: 0x40
    FeeRate protocolFee; // 0x00
    FeeRate takerFee; // 0x20
}

struct FeeRate {
    // Size: 0x40
    address recipient; // 0x00
    uint16 rate; // 0x20
}
