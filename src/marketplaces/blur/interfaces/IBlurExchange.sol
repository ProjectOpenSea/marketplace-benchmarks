// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Input } from "../lib/OrderStructs.sol";

interface IBlurExchange {
    function open() external;

    function execute(Input calldata sell, Input calldata buy) external payable;
}
