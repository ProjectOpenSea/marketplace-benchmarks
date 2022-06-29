// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Market } from "./MarketConstants.sol";

interface IX2Y2Marketplace {
    function run1(
        Market.Order memory order,
        Market.SettleShared memory shared,
        Market.SettleDetail memory detail
    ) external returns (uint256);

    function run(Market.RunInput memory input) external payable;

    function updateSigners(address[] memory toAdd, address[] memory toRemove)
        external;
}
