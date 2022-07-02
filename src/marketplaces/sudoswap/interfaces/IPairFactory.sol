pragma solidity ^0.8.0;

import { IPair } from "./IPair.sol";

interface IPairFactory {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function createPairETH(
        address _nft,
        address _bondingCurve,
        address payable _assetRecipient,
        PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (IPair pair);

    struct CreateERC20PairParams {
        address token;
        address nft;
        address bondingCurve;
        address payable assetRecipient;
        PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function createPairERC20(CreateERC20PairParams calldata params)
        external
        returns (IPair pair);

    function owner() external view returns (address);

    function changeProtocolFeeMultiplier(uint256 _protocolFeeMultiplier)
        external;

    function setRouterAllowed(address _router, bool isAllowed) external;
}
