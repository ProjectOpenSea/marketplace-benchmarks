// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

import { FeeMethod, Side, SaleKind, HowToCall } from "../lib/WyvernEnums.sol";

interface WyvernInterface {
    function atomicMatch_(
        address[14] calldata addrs,
        uint256[18] calldata uints,
        uint8[8] calldata feeMethodsSidesKindsHowToCalls,
        bytes calldata calldataBuy,
        bytes calldata calldataSell,
        bytes calldata replacementPatternBuy,
        bytes calldata replacementPatternSell,
        bytes calldata staticExtradataBuy,
        bytes calldata staticExtradataSell,
        uint8[2] calldata vs,
        bytes32[5] calldata rssMetadata
    ) external payable;

    function approveOrder_(
        address[7] calldata addrs,
        uint256[9] calldata uints,
        FeeMethod feeMethod,
        Side side,
        SaleKind saleKind,
        HowToCall howToCall,
        bytes calldata _calldata,
        bytes calldata replacementPattern,
        bytes calldata staticExtradata,
        bool orderbookInclusionDesired
    ) external;
}
