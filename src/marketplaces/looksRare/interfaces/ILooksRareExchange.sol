// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OrderTypes } from "../lib/OrderTypes.sol";

interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external;

    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external;

    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external;
}
