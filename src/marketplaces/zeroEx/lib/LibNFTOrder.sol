// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev A library for common NFT order operations.
library LibNFTOrder {
    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    enum TradeDirection {
        SELL_NFT,
        BUY_NFT
    }

    struct Property {
        address propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    // "Base struct" for ERC721Order and ERC1155, used
    // by the abstract contract `NFTOrders`.
    struct NFTOrder {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        address erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields align with those of NFTOrder
    struct ERC721Order {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        address erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc721Token;
        uint256 erc721TokenId;
        Property[] erc721TokenProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTOrder
    struct ERC1155Order {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        address erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }
}
