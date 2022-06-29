// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

/* Fee method: protocol fee or split fee. */
enum FeeMethod {
    ProtocolFee,
    SplitFee
}

/**
 * Side: buy or sell.
 */
enum Side {
    Buy,
    Sell
}

/**
 * Currently supported kinds of sale: fixed price, Dutch auction.
 * English auctions cannot be supported without stronger escrow guarantees.
 * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
 */
enum SaleKind {
    FixedPrice,
    DutchAuction
}

/* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
enum HowToCall {
    Call,
    DelegateCall
}
