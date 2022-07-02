pragma solidity ^0.8.0;

import "solmate/tokens/ERC20.sol";

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { SetupCall, TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";
import { IPair } from "./interfaces/IPair.sol";
import { IRouter } from "./interfaces/IRouter.sol";
import { IPairFactory } from "./interfaces/IPairFactory.sol";

contract SudoswapConfig is BaseMarketConfig {
    IPairFactory constant PAIR_FACTORY =
        IPairFactory(0xb16c1342E617A5B6E4b631EB114483FDB289c0A4);
    IRouter constant ROUTER =
        IRouter(0x5ba23BEAb987463a64BD05575D3D4a947DfDe32E);
    address constant LINEAR_CURVE = 0x5B6aC51d9B1CeDE0068a1B26533CAce807f883Ee;

    uint128 constant DELTA = 1;
    uint128 constant NFT_PRICE = 100; // the price at which NFTs are being bought/sold
    uint128 constant TOKEN_POOL_SPOT_PRICE = NFT_PRICE;
    uint128 constant NFT_POOL_SPOT_PRICE = TOKEN_POOL_SPOT_PRICE - DELTA;

    IPair erc20TokenPool; // owned by seller, who sells ERC20 to buy ERC721
    IPair ethNftPool; // owned by seller, who sells ERC721 to buy ETH
    IPair erc20NftPool; // owned by seller, who sells ERC721 to buy ERC20
    address erc20Address;
    address erc721Address;
    address currentMarket; // the current address that stores the listed ERC721

    IPair[10] ethNftPoolsForDistinct;

    function name() external pure override returns (string memory) {
        return "sudoswap";
    }

    function market() public view override returns (address) {
        return currentMarket;
    }

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            ROUTER
        );
    }

    function beforeAllPrepareMarketplaceCall(
        address seller,
        address,
        address[] calldata erc20Addresses,
        address[] calldata erc721Addresses
    ) external override returns (SetupCall[] memory setupCalls) {
        // record tokens
        erc20Address = erc20Addresses[0];
        erc721Address = erc721Addresses[0];

        // set protocol fee to zero
        setupCalls = new SetupCall[](2);
        setupCalls[0] = SetupCall({
            sender: PAIR_FACTORY.owner(),
            target: address(PAIR_FACTORY),
            data: abi.encodeWithSelector(
                IPairFactory.changeProtocolFeeMultiplier.selector,
                0
            )
        });

        // whitelist the new router
        setupCalls[1] = SetupCall({
            sender: PAIR_FACTORY.owner(),
            target: address(PAIR_FACTORY),
            data: abi.encodeWithSelector(
                IPairFactory.setRouterAllowed.selector,
                address(ROUTER),
                true
            )
        });

        // deploy pools
        uint256[] memory empty;

        erc20TokenPool = PAIR_FACTORY.createPairERC20(
            IPairFactory.CreateERC20PairParams({
                token: erc20Addresses[0],
                nft: erc721Addresses[0],
                bondingCurve: LINEAR_CURVE,
                assetRecipient: payable(seller),
                poolType: IPairFactory.PoolType.TOKEN,
                delta: DELTA,
                fee: 0,
                spotPrice: TOKEN_POOL_SPOT_PRICE,
                initialNFTIDs: empty,
                initialTokenBalance: 0
            })
        );

        ethNftPool = PAIR_FACTORY.createPairETH(
            erc721Addresses[0],
            LINEAR_CURVE,
            payable(seller),
            IPairFactory.PoolType.NFT,
            DELTA,
            0,
            NFT_POOL_SPOT_PRICE,
            empty
        );

        for (uint256 i = 0; i < 10; i++) {
            ethNftPoolsForDistinct[i] = PAIR_FACTORY.createPairETH(
                erc721Addresses[0],
                LINEAR_CURVE,
                payable(seller),
                IPairFactory.PoolType.NFT,
                DELTA,
                0,
                NFT_POOL_SPOT_PRICE + uint128(i),
                empty
            );
        }

        erc20NftPool = PAIR_FACTORY.createPairERC20(
            IPairFactory.CreateERC20PairParams({
                token: erc20Addresses[0],
                nft: erc721Addresses[0],
                bondingCurve: LINEAR_CURVE,
                assetRecipient: payable(seller),
                poolType: IPairFactory.PoolType.NFT,
                delta: DELTA,
                fee: 0,
                spotPrice: NFT_POOL_SPOT_PRICE,
                initialNFTIDs: empty,
                initialTokenBalance: 0
            })
        );
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external override returns (TestOrderPayload memory execution) {
        if (!context.listOnChain || nft.token != erc721Address)
            _notImplemented();

        // update market address so tests know where the ERC721 will be escrowed
        currentMarket = address(ethNftPool);

        // construct submitOrder payload
        // offerer transfers ERC721 to ethNftPool
        execution.submitOrder = TestCallParameters({
            target: nft.token,
            value: 0,
            data: abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                context.offerer,
                address(ethNftPool),
                nft.identifier
            )
        });

        // construct executeOrder payload
        // fulfiller calls pair directly to swap
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nft.identifier;
        execution.executeOrder = TestCallParameters({
            target: address(ethNftPool),
            value: ethAmount,
            data: abi.encodeWithSelector(
                IPair.swapTokenForSpecificNFTs.selector,
                nftIds,
                type(uint256).max,
                context.fulfiller,
                false,
                address(0)
            )
        });
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external override returns (TestOrderPayload memory execution) {
        if (
            !context.listOnChain ||
            nft.token != erc721Address ||
            erc20.token != erc20Address ||
            erc20.amount != NFT_PRICE
        ) _notImplemented();

        // update market address so tests know where the ERC721 will be escrowed
        currentMarket = address(erc20NftPool);

        // construct submitOrder payload
        // offerer transfers ERC721 to erc20NftPool
        execution.submitOrder = TestCallParameters({
            target: nft.token,
            value: 0,
            data: abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                context.offerer,
                address(erc20NftPool),
                nft.identifier
            )
        });

        // construct executeOrder payload
        // fulfiller calls router
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nft.identifier;

        IRouter.PairSwapSpecific[]
            memory swapList = new IRouter.PairSwapSpecific[](1);
        swapList[0] = IRouter.PairSwapSpecific({
            pair: address(erc20NftPool),
            nftIds: nftIds
        });
        execution.executeOrder = TestCallParameters({
            target: address(ROUTER),
            value: 0,
            data: abi.encodeWithSelector(
                IRouter.swapERC20ForSpecificNFTs.selector,
                swapList,
                erc20.amount,
                context.fulfiller,
                type(uint256).max
            )
        });
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external override returns (TestOrderPayload memory execution) {
        if (
            !context.listOnChain ||
            nft.token != erc721Address ||
            erc20.token != erc20Address ||
            erc20.amount != NFT_PRICE
        ) _notImplemented();

        // update market address so tests know where the ERC20 will be escrowed
        currentMarket = address(erc20TokenPool);

        // construct submitOrder payload
        // offerer transfers ERC20 to erc20TokenPool
        execution.submitOrder = TestCallParameters({
            target: erc20.token,
            value: 0,
            data: abi.encodeWithSelector(
                ERC20.transfer.selector,
                address(erc20TokenPool),
                erc20.amount
            )
        });

        // construct executeOrder payload
        // fulfiller calls router
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nft.identifier;

        IRouter.PairSwapSpecific[]
            memory swapList = new IRouter.PairSwapSpecific[](1);
        swapList[0] = IRouter.PairSwapSpecific({
            pair: address(erc20TokenPool),
            nftIds: nftIds
        });
        execution.executeOrder = TestCallParameters({
            target: address(ROUTER),
            value: 0,
            data: abi.encodeWithSelector(
                IRouter.swapNFTsForToken.selector,
                swapList,
                0,
                context.fulfiller,
                type(uint256).max
            )
        });
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external override returns (TestOrderPayload memory execution) {
        if (!context.listOnChain) _notImplemented();

        // update market address so tests know where the ERC721 will be escrowed
        currentMarket = address(ethNftPool);

        address nftAddress = nfts[0].token;

        uint256[] memory ids = new uint256[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            ids[i] = nfts[i].identifier;
        }

        // construct submitOrder payload
        // offerer transfers 10 ERC721s to ethNftPool
        execution.submitOrder = TestCallParameters({
            target: address(ROUTER),
            value: 0,
            data: abi.encodeWithSignature(
                "depositNFTs(address,uint256[],address)",
                nftAddress,
                ids,
                address(ethNftPool)
            )
        });

        // construct executeOrder payload
        // fulfiller calls pair directly to swap
        execution.executeOrder = TestCallParameters({
            target: address(ethNftPool),
            value: ethAmount,
            data: abi.encodeWithSelector(
                IPair.swapTokenForSpecificNFTs.selector,
                ids,
                type(uint256).max,
                context.fulfiller,
                false,
                address(0)
            )
        });
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        if (!contexts[0].listOnChain) _notImplemented();

        address[] memory pools = new address[](nfts.length);
        uint256[] memory ids = new uint256[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            pools[i] = address(ethNftPoolsForDistinct[i]);
            ids[i] = nfts[i].identifier;
        }

        execution.submitOrder = TestCallParameters({
            target: address(ROUTER),
            value: 0,
            data: abi.encodeWithSignature(
                "depositNFTs(address,uint256[],address[])",
                nfts[0].token,
                ids,
                pools
            )
        });

        // construct executeOrder payload
        // fulfiller calls router

        IRouter.PairSwapSpecific[]
            memory swapList = new IRouter.PairSwapSpecific[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            uint256[] memory singleId = new uint256[](1);
            singleId[0] = nfts[i].identifier;
            swapList[i] = IRouter.PairSwapSpecific({
                pair: address(ethNftPoolsForDistinct[i]),
                nftIds: singleId
            });
        }

        uint256 totalEthAmount = 0;
        for (uint256 i = 0; i < ethAmounts.length; i++) {
            totalEthAmount += ethAmounts[i];
        }

        execution.executeOrder = TestCallParameters({
            target: address(ROUTER),
            value: totalEthAmount,
            data: abi.encodeWithSelector(
                IRouter.swapETHForSpecificNFTs.selector,
                swapList,
                contexts[0].offerer,
                contexts[0].fulfiller,
                type(uint256).max
            )
        });
    }
}
