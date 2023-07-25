// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Vm } from "forge-std/Vm.sol";

import { StdCheats } from "forge-std/StdCheats.sol";

import { Merkle } from "./lib/Merkle.sol";

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";

import { TestERC20 } from "../../../test/tokens/TestERC20.sol";

import "../../Types.sol";

import "./lib/Structs.sol";

import "./lib/BlurV2TypeHashes.sol";

import { Oracle } from "./lib/Oracle.sol";

import { IBlurExchangeV2 } from "./interfaces/IBlurExchangeV2.sol";

interface IBeth {
    function deposit() external payable;
}

address constant VM_ADDRESS = address(
    uint160(uint256(keccak256("hevm cheat code")))
);
Vm constant vm = Vm(VM_ADDRESS);

contract BlurV2Config is BaseMarketConfig, BlurV2TypeHashes, StdCheats, Merkle {
    error ExpiredOracleSignature();
    error UnauthorizedOracle();
    error InvalidOracleSignature();

    // The oracle signs as an EOA, but the code for producing oracle signatures
    // is also etched there.
    uint256 internal oraclePk;
    address payable internal oracle;
    Oracle oracleContract;

    constructor() BaseMarketConfig() {
        oraclePk = 0x07ac1e;
        oracle = payable(vm.addr(oraclePk));
        vm.allowCheatcodes(oracle);
        deployCodeTo("out/Oracle.sol/Oracle.json", oracle);
        oracleContract = Oracle(oracle);

        vm.label(approvalTarget, "blurDelegate");
        vm.label(oracle, "fakeBlurOracle");
        vm.label(address(blur), "blurExchangeV2");
    }

    function name() external pure override returns (string memory) {
        return "BlurV2";
    }

    function market() public pure override returns (address) {
        return address(blur);
    }

    IBlurExchangeV2 internal constant blur =
        IBlurExchangeV2(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5);

    IBeth internal constant beth =
        IBeth(0x0000000000A39bb272e79075ade125fd351887Ac);

    // The "execution delegate" — functions similarly to a conduit.
    address internal constant approvalTarget =
        0x2f18F339620a63e43f0839Eeb18D7de1e1Be4DfB;

    TestERC20 internal constant weth =
        TestERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    TestERC20 internal constant bethTestERC20 =
        TestERC20(0x0000000000A39bb272e79075ade125fd351887Ac);

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            approvalTarget
        );
    }

    function beforeAllPrepareMarketplaceCall(
        address,
        address,
        address[] calldata,
        address[] calldata
    ) external view override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](1);

        address blurOwner = blur.owner();

        // Approve the oracle as a signer.
        setupCalls[0] = SetupCall(
            blurOwner,
            address(blur),
            abi.encodeWithSelector(
                IBlurExchangeV2.setOracle.selector,
                oracle,
                true
            )
        );

        return setupCalls;
    }

    function buildExchange(
        uint256 index,
        bytes32[] memory proof,
        Listing memory listing,
        Taker memory taker
    ) internal pure returns (Exchange memory exchangeStruct) {
        exchangeStruct.index = index;
        exchangeStruct.proof = proof;
        exchangeStruct.listing = listing;
        exchangeStruct.taker = taker;

        return exchangeStruct;
    }

    function buildListing(
        uint256 index,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) internal pure returns (Listing memory listingStruct) {
        listingStruct.index = index;
        listingStruct.tokenId = tokenId;
        listingStruct.amount = amount;
        listingStruct.price = price;

        return listingStruct;
    }

    function buildTaker(uint256 tokenId, uint256 amount)
        internal
        pure
        returns (Taker memory takerStruct)
    {
        takerStruct.tokenId = tokenId;
        takerStruct.amount = amount;

        return takerStruct;
    }

    function buildOrder(
        address offerer,
        address collection,
        bytes32 listingsRoot,
        uint256 numberOfListings,
        uint256 expirationTime,
        AssetType assetType,
        FeeRate memory makerFee,
        uint256 salt
    ) internal pure returns (Order memory orderStruct) {
        orderStruct.trader = offerer;
        orderStruct.collection = collection;
        orderStruct.listingsRoot = listingsRoot;
        orderStruct.numberOfListings = numberOfListings;
        orderStruct.expirationTime = expirationTime;
        orderStruct.assetType = assetType;
        orderStruct.makerFee = makerFee;
        orderStruct.salt = salt;

        return orderStruct;
    }

    function buildFees(FeeRate memory protocolFee, FeeRate memory takerFee)
        internal
        pure
        returns (Fees memory feesStruct)
    {
        feesStruct.protocolFee = protocolFee;
        feesStruct.takerFee = takerFee;

        return feesStruct;
    }

    function buildFeeRate(address recipient, uint256 rate)
        internal
        pure
        returns (FeeRate memory feeRateStruct)
    {
        feeRateStruct.recipient = recipient;
        feeRateStruct.rate = uint16(rate);

        return feeRateStruct;
    }

    // Cribbed from blur.
    function _hashToSign(bytes32 hash) private pure returns (bytes32) {
        return keccak256(bytes.concat(bytes2(0x1901), DOMAIN_SEPARATOR, hash));
    }

    function buildListingsRoot(Exchange[] memory exchanges)
        internal
        pure
        returns (bytes32 listingsRoot)
    {
        bytes32[] memory listingHashes;
        if (exchanges.length < 2) {
            listingHashes = new bytes32[](2);
            // Murky needs two.
            listingHashes[0] = blur.hashListing(exchanges[0].listing);
            listingHashes[1] = blur.hashListing(exchanges[0].listing);
            listingsRoot = getRoot(listingHashes);
        } else {
            listingHashes = new bytes32[](exchanges.length);
            for (uint256 i; i < exchanges.length; ++i) {
                listingHashes[i] = blur.hashListing(exchanges[i].listing);
            }
            listingsRoot = getRoot(listingHashes);
        }

        return listingsRoot;
    }

    function buildProofArray(Exchange[] memory exchanges, uint256 node)
        internal
        pure
        returns (bytes32[] memory proofArray)
    {
        bytes32[] memory listingHashes;
        if (exchanges.length < 2) {
            listingHashes = new bytes32[](2);
            listingHashes[0] = blur.hashListing(exchanges[0].listing);
            listingHashes[1] = blur.hashListing(exchanges[0].listing);

            proofArray = getProof(listingHashes, 0);
        } else {
            listingHashes = new bytes32[](exchanges.length);
            for (uint256 i; i < exchanges.length; ++i) {
                listingHashes[i] = blur.hashListing(exchanges[i].listing);
            }

            proofArray = getProof(listingHashes, node);
        }
    }

    struct BuildArgumentsInfra {
        Order order;
        Order[] orders;
        Exchange exchange;
        Exchange[] exchanges;
        FeeRate feeRate;
        bytes orderSignature;
        bytes32 oracleHash;
    }

    function buildArgumentsTakeAskSingle(
        TestOrderContext memory context,
        address nftToken,
        uint256 identifier,
        AssetType assetType,
        uint256 tokenAmount
    )
        internal
        view
        returns (TakeAskSingle memory takeAskSingle, bytes memory signature)
    {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](0),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](0),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        // Create the order.
        infra.order = buildOrder(
            context.offerer, // The seller of an NFT is the "trader" here.
            nftToken, // This is "collection" in Blur parlance.
            bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
            2, // Number of listings, 2 to make Murky happy.
            block.timestamp + 1000, // expirationTime
            assetType, // assetType
            buildFeeRate(address(0), 0), // feeRate
            gasleft() // salt
        );

        infra.exchange = buildExchange(
            0, // index
            new bytes32[](0), // proof (set below)
            buildListing(
                0, // index (presumably of the listing in the Order)
                identifier, // tokenId
                1, // amount
                tokenAmount // price
            ),
            buildTaker(
                identifier, // tokenId
                1 // amount
            )
        );

        infra.exchanges = new Exchange[](1);
        infra.exchanges[0] = infra.exchange;

        infra.exchange.proof = buildProofArray(infra.exchanges, 0);
        infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

        {
            infra.orderSignature = _getOrderSignature(
                context.offerer,
                infra.order,
                OrderType.ASK
            );
        }

        takeAskSingle = TakeAskSingle({
            order: infra.order,
            exchange: infra.exchange,
            takerFee: infra.feeRate,
            signature: infra.orderSignature,
            tokenRecipient: context.fulfiller
        });

        {
            infra.oracleHash = blur.hashTakeAskSingle(
                takeAskSingle,
                context.fulfiller
            );

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeAskSingle, signature);
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 nativeTokenAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeAskSingle memory takeAskSingle,
            bytes memory oracleSignature
        ) = buildArgumentsTakeAskSingle(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC721,
                nativeTokenAmount
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAskSingle.selector,
                takeAskSingle,
                oracleSignature
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 memory nft,
        uint256 nativeTokenAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeAskSingle memory takeAskSingle,
            bytes memory oracleSignature
        ) = buildArgumentsTakeAskSingle(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC1155,
                nativeTokenAmount
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAskSingle.selector,
                takeAskSingle,
                oracleSignature
            )
        );
    }

    // It's not possible to purchase NFTs with tokens other than ETH or Blur's
    // proprietary version of WETH.
    // See https://etherscan.io/address/0xb38827497daf7f28261910e33e22219de087c8f5#code#F1#L594.
    function getPayload_BuyOfferedERC721WithBETH(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeAskSingle memory takeAskSingle,
            bytes memory oracleSignature
        ) = buildArgumentsTakeAskSingle(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC721,
                erc20.amount
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAskSinglePool.selector,
                takeAskSingle,
                oracleSignature,
                erc20.amount
            )
        );
    }

    function buildArgumentsTakeBidSingle(
        TestOrderContext memory context,
        address nftToken,
        uint256 identifier,
        AssetType assetType,
        uint256 tokenAmount
    )
        internal
        view
        returns (TakeBidSingle memory takeBidSingle, bytes memory signature)
    {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](0),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](0),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        // Create the order.
        infra.order = buildOrder(
            context.offerer, // The seller of an NFT is the "trader" here.
            nftToken, // This is "collection" in Blur parlance.
            bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
            2, // Number of listings, 2 to make Murky happy.
            block.timestamp + 1000, // expirationTime
            assetType, // assetType
            buildFeeRate(address(0), 0), // feeRate
            gasleft() // salt
        );

        infra.exchange = buildExchange(
            0, // index
            new bytes32[](0), // proof (set below)
            buildListing(
                0, // index (presumably of the listing in the Order)
                identifier, // tokenId
                1, // amount
                tokenAmount // price
            ),
            buildTaker(
                identifier, // tokenId
                1 // amount
            )
        );

        infra.exchanges = new Exchange[](1);
        infra.exchanges[0] = infra.exchange;

        infra.exchange.proof = buildProofArray(infra.exchanges, 0);
        infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

        {
            infra.orderSignature = _getOrderSignature(
                context.offerer,
                infra.order,
                OrderType.BID
            );
        }

        takeBidSingle = TakeBidSingle({
            order: infra.order,
            exchange: infra.exchange,
            takerFee: infra.feeRate,
            signature: infra.orderSignature
        });

        {
            infra.oracleHash = blur.hashTakeBidSingle(
                takeBidSingle,
                context.fulfiller
            );

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeBidSingle, signature);
    }

    function getPayload_BuyOfferedBETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeBidSingle memory takeBidSingle,
            bytes memory oracleSignature
        ) = buildArgumentsTakeBidSingle(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC721,
                erc20.amount
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeBidSingle.selector,
                takeBidSingle,
                oracleSignature
            )
        );
    }

    function buildArgumentsDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        AssetType assetType,
        uint256[] memory tokenAmounts
    ) internal view returns (TakeAsk memory takeAsk, bytes memory signature) {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](1),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](nfts.length),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        for (uint256 i; i < nfts.length; ++i) {
            // Create an order.
            infra.order = buildOrder(
                contexts[i].offerer, // The seller of an NFT is the "trader" here.
                nfts[i].token, // This is "collection" in Blur parlance.
                bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
                2, // Number of listings, 2 to make Murky happy.
                block.timestamp + 1000, // expirationTime
                assetType, // assetType
                buildFeeRate(address(0), 0), // feeRate
                gasleft() // salt
            );

            infra.exchange = buildExchange(
                i, // index
                new bytes32[](0), // proof (set below)
                buildListing(
                    0, // index (presumably of the listing in the Order)
                    nfts[i].identifier, // tokenId
                    1, // amount
                    tokenAmounts[i] // price
                ),
                buildTaker(
                    nfts[i].identifier, // tokenId
                    1 // amount
                )
            );

            infra.exchanges = new Exchange[](1);
            infra.exchanges[0] = infra.exchange;

            infra.exchange.proof = buildProofArray(infra.exchanges, 0);
            infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

            {
                bytes memory singleSignature = _getOrderSignature(
                    contexts[i].offerer,
                    infra.order,
                    OrderType.ASK
                );

                infra.orderSignature = abi.encodePacked(
                    infra.orderSignature,
                    singleSignature
                );
            }

            // Add the order to the orders array.
            infra.orders[i] = infra.order;
            // Add the exchange to the exchanges array.
            infra.exchanges[i] = infra.exchange;
        }

        takeAsk = TakeAsk({
            orders: infra.orders,
            exchanges: infra.exchanges,
            takerFee: infra.feeRate,
            signatures: infra.orderSignature,
            tokenRecipient: contexts[0].fulfiller
        });

        {
            infra.oracleHash = blur.hashTakeAsk(takeAsk, contexts[0].fulfiller);

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeAsk, signature);
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata nativeTokenAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        uint256 nativeTokenAmount;

        for (uint256 i; i < nativeTokenAmounts.length; ++i) {
            nativeTokenAmount += nativeTokenAmounts[i];
        }

        (
            TakeAsk memory takeAsk,
            bytes memory oracleSignature
        ) = buildArgumentsDistinctOrders(
                contexts,
                nfts,
                AssetType.ERC721,
                nativeTokenAmounts
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAsk.selector,
                takeAsk,
                oracleSignature
            )
        );
    }

    function buildArgumentsBuyTen(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        AssetType assetType,
        uint256 tokenAmount
    ) internal view returns (TakeAsk memory takeAsk, bytes memory signature) {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](nfts.length),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](nfts.length),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        // Create the order.
        infra.order = buildOrder(
            context.offerer, // The seller of an NFT is the "trader" here.
            nfts[0].token, // This is "collection" in Blur parlance.
            bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
            10, // Number of listings.
            block.timestamp + 1000, // expirationTime
            assetType, // assetType
            buildFeeRate(address(0), 0), // feeRate
            gasleft() // salt
        );

        for (uint256 i; i < nfts.length; ++i) {
            infra.exchange = buildExchange(
                0, // index of the order
                new bytes32[](0), // proof (set below)
                buildListing(
                    i, // index (presumably of the listing in the Order)
                    nfts[i].identifier, // tokenId
                    1, // amount
                    tokenAmount / nfts.length // price
                ),
                buildTaker(
                    nfts[i].identifier, // tokenId
                    1 // amount
                )
            );

            infra.exchanges[i] = infra.exchange;
        }

        for (uint256 i; i < nfts.length; ++i) {
            infra.exchanges[i].proof = buildProofArray(infra.exchanges, i);
        }

        infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

        {
            infra.orderSignature = _getOrderSignature(
                context.offerer,
                infra.order,
                OrderType.ASK
            );
        }

        infra.orders[0] = infra.order;

        takeAsk = TakeAsk({
            orders: infra.orders,
            exchanges: infra.exchanges,
            takerFee: infra.feeRate,
            signatures: infra.orderSignature,
            tokenRecipient: context.fulfiller
        });

        {
            infra.oracleHash = blur.hashTakeAsk(takeAsk, context.fulfiller);

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeAsk, signature);
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 nativeTokenAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeAsk memory takeAsk,
            bytes memory oracleSignature
        ) = buildArgumentsBuyTen(
                context,
                nfts,
                AssetType.ERC721,
                nativeTokenAmount
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAsk.selector,
                takeAsk,
                oracleSignature
            )
        );
    }

    function _getOrderSignature(
        address signer,
        Order memory order,
        OrderType side
    ) internal view returns (bytes memory signature) {
        bytes32 orderHash = blur.hashOrder(order, side);
        bytes32 orderHashToSign = _hashToSign(orderHash);

        (uint8 v, bytes32 r, bytes32 s) = _sign(signer, orderHashToSign);

        signature = abi.encodePacked(r, s, v);
    }
}
