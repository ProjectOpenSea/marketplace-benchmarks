// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

import "./WyvernEnums.sol";

/* An ECDSA signature. */
struct Sig {
    /* v parameter */
    uint8 v;
    /* r parameter */
    bytes32 r;
    /* s parameter */
    bytes32 s;
}

/* An order on the exchange. */
struct Order {
    /* Exchange address, intended as a versioning mechanism. */
    address exchange;
    /* Order maker address. */
    address maker;
    /* Order taker address, if specified. */
    address taker;
    /* Maker relayer fee of the order, unused for taker order. */
    uint256 makerRelayerFee;
    /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
    uint256 takerRelayerFee;
    /* Maker protocol fee of the order, unused for taker order. */
    uint256 makerProtocolFee;
    /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
    uint256 takerProtocolFee;
    /* Order fee recipient or zero address for taker order. */
    address feeRecipient;
    /* Fee method (protocol token or split fee). */
    FeeMethod feeMethod;
    /* Side (buy/sell). */
    Side side;
    /* Kind of sale. */
    SaleKind saleKind;
    /* Target. */
    address target;
    /* HowToCall. */
    HowToCall howToCall;
    /* Calldata. */
    bytes _calldata;
    /* Calldata replacement pattern, or an empty byte array for no replacement. */
    bytes replacementPattern;
    /* Static call target, zero-address for no static call. */
    address staticTarget;
    /* Static call extra data. */
    bytes staticExtradata;
    /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
    address paymentToken;
    /* Base price of the order (in paymentTokens). */
    uint256 basePrice;
    /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
    uint256 extra;
    /* Listing timestamp. */
    uint256 listingTime;
    /* Expiration timestamp - 0 for no expiry. */
    uint256 expirationTime;
    /* Order salt, used to prevent duplicate hashes. */
    uint256 salt;
    /* NOTE: uint counter is an additional component of the order but is read from storage */
}
