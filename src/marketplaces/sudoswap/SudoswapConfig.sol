pragma solidity ^0.8.0;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { SetupCall, TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IPairFactory} from "./interfaces/IPairFactory.sol";

contract SudoswapConfig is BaseMarketConfig {

    IPairFactory constant PAIR_FACTORY = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    IRouter constant ROUTER = IRouter(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329);

    function name() external pure override returns (string memory) {
        return "sudoswap";
    }

    function market() public pure override returns (address) {
        return address(PAIR_FACTORY);
    }


}
