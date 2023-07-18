// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LooksRareV2TypeHashes } from "./lib/LooksRareV2TypeHashes.sol";
import { OrderStructs } from "./lib/OrderStructs.sol";
import { QuoteType } from "./lib/QuoteType.sol";
import { CollectionType } from "./lib/CollectionType.sol";
import { ILooksRareProtocol } from "./interfaces/ILooksRareProtocol.sol";
import { ITransferManager } from "./interfaces/ITransferManager.sol";
import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20, SetupCall } from "../../Types.sol";

contract LooksRareV2Config is BaseMarketConfig, LooksRareV2TypeHashes {
    /**
     * @dev A struct to merge the 5 calldata variables to prevent stack too deep error.
     * @param takerBids Taker bids to be used as function argument when calling LooksRare V2
     * @param makerAsks Maker asks to be used as function argument when calling LooksRare V2
     * @param makerSignatures Maker signatures to be used as function argument when calling LooksRare V2
     * @param merkleTrees Merkle trees to be used as function argument when calling LooksRare V2
     * @param ethValue The ETH value to be passed as msg.value when calling LooksRare V2
     */
    struct ManyItemsCalldataParams {
        OrderStructs.Taker[] takerBids;
        OrderStructs.Maker[] makerAsks;
        bytes[] makerSignatures;
        OrderStructs.MerkleTree[] merkleTrees;
        uint256 ethValue;
    }

    function name() external pure override returns (string memory) {
        return "LooksRare V2";
    }

    function market() public pure override returns (address) {
        return address(LOOKS_RARE);
    }

    address internal constant ETH = address(0);
    address internal constant NO_AFFILIATE = address(0);
    address internal constant OWNER =
        0xBfb6669Ef4C4c71ae6E722526B1B8d7d9ff9a019;
    address internal constant TRANSFER_MANAGER =
        0x000000000060C4Ca14CfC4325359062ace33Fe3D;
    ILooksRareProtocol internal constant LOOKS_RARE =
        ILooksRareProtocol(0x0000000000E655fAe4d56241588680F86E3b2377);

    // /*//////////////////////////////////////////////////////////////
    //                         Generic Helpers
    // //////////////////////////////////////////////////////////////*/

    function buildMakerOrder(
        QuoteType quoteType,
        uint256 orderNonce,
        address maker,
        address currency,
        uint256 price,
        CollectionType collectionType,
        address collection,
        uint256 amount,
        uint256 itemId
    ) internal view returns (OrderStructs.Maker memory makerOrder) {
        uint256[] memory itemIds = new uint256[](1);
        itemIds[0] = itemId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        makerOrder = OrderStructs.Maker({
            quoteType: quoteType,
            globalNonce: 0,
            subsetNonce: 0,
            orderNonce: orderNonce,
            strategyId: 0,
            collectionType: collectionType,
            collection: collection,
            currency: currency,
            signer: maker,
            startTime: block.timestamp,
            endTime: block.timestamp + 1,
            price: price,
            itemIds: itemIds,
            amounts: amounts,
            additionalParameters: ""
        });
    }

    function buildTakerOrder(address taker)
        internal
        pure
        returns (OrderStructs.Taker memory takerOrder)
    {
        takerOrder = OrderStructs.Taker({
            recipient: taker,
            additionalParameters: ""
        });
    }

    function buildMakerSignature(OrderStructs.Maker memory makerOrder)
        internal
        view
        returns (bytes memory makerSignature)
    {
        bytes32 digest = _deriveOrderDigest(makerOrder);
        (uint8 v, bytes32 r, bytes32 s) = _sign(makerOrder.signer, digest);
        makerSignature = abi.encodePacked(r, s, v);
    }

    function buildManyItemsCalldataParams(uint256 length)
        internal
        pure
        returns (ManyItemsCalldataParams memory params)
    {
        params.makerAsks = new OrderStructs.Maker[](length);
        params.takerBids = new OrderStructs.Taker[](length);
        params.makerSignatures = new bytes[](length);
        params.merkleTrees = new OrderStructs.MerkleTree[](length);
    }

    // /*//////////////////////////////////////////////////////////////
    //                         Setup
    // //////////////////////////////////////////////////////////////*/

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = TRANSFER_MANAGER;
        buyerErc1155ApprovalTarget = sellerErc1155ApprovalTarget = TRANSFER_MANAGER;
        buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            LOOKS_RARE
        );
    }

    function beforeAllPrepareMarketplaceCall(
        address seller,
        address buyer,
        address[] calldata currencies,
        address[] calldata
    ) external pure override returns (SetupCall[] memory) {
        uint256 currenciesLength = currencies.length;

        SetupCall[] memory setupCalls = new SetupCall[](currenciesLength + 2);
        for (uint256 i = 0; i < currenciesLength; i++) {
            // Allow necessary currencies
            setupCalls[i] = SetupCall(
                OWNER,
                address(LOOKS_RARE),
                abi.encodeWithSelector(
                    ILooksRareProtocol.updateCurrencyStatus.selector,
                    currencies[i],
                    true
                )
            );
        }

        address[] memory operators = new address[](1);
        operators[0] = address(LOOKS_RARE);

        setupCalls[currenciesLength] = SetupCall(
            seller,
            TRANSFER_MANAGER,
            abi.encodeWithSelector(
                ITransferManager.grantApprovals.selector,
                operators
            )
        );

        setupCalls[currenciesLength + 1] = SetupCall(
            buyer,
            TRANSFER_MANAGER,
            abi.encodeWithSelector(
                ITransferManager.grantApprovals.selector,
                operators
            )
        );

        return setupCalls;
    }

    // /*//////////////////////////////////////////////////////////////
    //                     Test Payload Calls
    // //////////////////////////////////////////////////////////////*/

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Ask,
            orderNonce: 0,
            maker: context.offerer,
            currency: ETH,
            price: ethAmount,
            collectionType: CollectionType.ERC721,
            collection: nft.token,
            amount: 1,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            ethAmount,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerBid.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Ask,
            orderNonce: 0,
            maker: context.offerer,
            currency: ETH,
            price: ethAmount,
            collectionType: CollectionType.ERC1155,
            collection: nft.token,
            amount: nft.amount,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            ethAmount,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerBid.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Ask,
            orderNonce: 0,
            maker: context.offerer,
            currency: erc20.token,
            price: erc20.amount,
            collectionType: CollectionType.ERC721,
            collection: nft.token,
            amount: 1,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerBid.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedERC721WithWETH(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Ask,
            orderNonce: 0,
            maker: context.offerer,
            currency: erc20.token,
            price: erc20.amount,
            collectionType: CollectionType.ERC721,
            collection: nft.token,
            amount: 1,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerBid.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 calldata erc20
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Ask,
            orderNonce: 0,
            maker: context.offerer,
            currency: erc20.token,
            price: erc20.amount,
            collectionType: CollectionType.ERC1155,
            collection: nft.token,
            amount: nft.amount,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerBid.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Bid,
            orderNonce: 0,
            maker: context.offerer,
            currency: erc20.token,
            price: erc20.amount,
            collectionType: CollectionType.ERC721,
            collection: nft.token,
            amount: 1,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerAsk.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedWETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Bid,
            orderNonce: 0,
            maker: context.offerer,
            currency: erc20.token,
            price: erc20.amount,
            collectionType: CollectionType.ERC721,
            collection: nft.token,
            amount: 1,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerAsk.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem1155 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Bid,
            orderNonce: 0,
            maker: context.offerer,
            currency: erc20.token,
            price: erc20.amount,
            collectionType: CollectionType.ERC1155,
            collection: nft.token,
            amount: nft.amount,
            itemId: nft.identifier
        });
        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerAsk.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        // Set itemIds and amounts outside of buildMakerOrder
        OrderStructs.Maker memory makerOrder = buildMakerOrder({
            quoteType: QuoteType.Ask,
            orderNonce: 0,
            maker: context.offerer,
            currency: ETH,
            price: ethAmount,
            collectionType: CollectionType.ERC721,
            collection: nfts[0].token,
            amount: 0,
            itemId: 0
        });
        makerOrder.itemIds = new uint256[](nfts.length);
        makerOrder.amounts = new uint256[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            makerOrder.itemIds[i] = nfts[i].identifier;
            makerOrder.amounts[i] = 1;
        }

        OrderStructs.Taker memory takerOrder = buildTakerOrder(
            context.fulfiller
        );
        bytes memory makerSignature = buildMakerSignature(makerOrder);
        OrderStructs.MerkleTree memory merkleTree;

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            ethAmount,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeTakerBid.selector,
                takerOrder,
                makerOrder,
                makerSignature,
                merkleTree,
                NO_AFFILIATE
            )
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        require(
            contexts.length == nfts.length && nfts.length == ethAmounts.length,
            "LooksRareV2Config::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
        );

        ManyItemsCalldataParams memory params = buildManyItemsCalldataParams(
            contexts.length
        );

        for (uint256 i = 0; i < contexts.length; i++) {
            params.makerAsks[i] = buildMakerOrder({
                quoteType: QuoteType.Ask,
                orderNonce: i,
                maker: contexts[i].offerer,
                currency: ETH,
                price: ethAmounts[i],
                collectionType: CollectionType.ERC721,
                collection: nfts[i].token,
                amount: 1,
                itemId: nfts[i].identifier
            });
            params.makerSignatures[i] = buildMakerSignature(
                params.makerAsks[i]
            );
            params.takerBids[i] = buildTakerOrder(contexts[i].fulfiller);
            params.ethValue += ethAmounts[i];
        }

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            params.ethValue,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeMultipleTakerBids.selector,
                params.takerBids,
                params.makerAsks,
                params.makerSignatures,
                params.merkleTrees,
                NO_AFFILIATE,
                false
            )
        );
    }

    function getPayload_BuyOfferedManyERC721WithErc20DistinctOrders(
        TestOrderContext[] calldata contexts,
        address erc20Address,
        TestItem721[] calldata nfts,
        uint256[] calldata erc20Amounts
    ) external view override returns (TestOrderPayload memory execution) {
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        require(
            contexts.length == nfts.length &&
                nfts.length == erc20Amounts.length,
            "LooksRareV2Config::getPayload_BuyOfferedManyERC721WithErc20DistinctOrders: invalid input"
        );

        ManyItemsCalldataParams memory params = buildManyItemsCalldataParams(
            contexts.length
        );

        for (uint256 i = 0; i < contexts.length; i++) {
            params.makerAsks[i] = buildMakerOrder({
                quoteType: QuoteType.Ask,
                orderNonce: i,
                maker: contexts[i].offerer,
                currency: erc20Address,
                price: erc20Amounts[i],
                collectionType: CollectionType.ERC721,
                collection: nfts[i].token,
                amount: 1,
                itemId: nfts[i].identifier
            });
            params.makerSignatures[i] = buildMakerSignature(
                params.makerAsks[i]
            );
            params.takerBids[i] = buildTakerOrder(contexts[i].fulfiller);
        }

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeMultipleTakerBids.selector,
                params.takerBids,
                params.makerAsks,
                params.makerSignatures,
                params.merkleTrees,
                NO_AFFILIATE,
                false
            )
        );
    }

    function getPayload_BuyOfferedManyERC721WithWETHDistinctOrders(
        TestOrderContext[] calldata contexts,
        address erc20Address,
        TestItem721[] calldata nfts,
        uint256[] calldata erc20Amounts
    ) external view override returns (TestOrderPayload memory execution) {
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        require(
            contexts.length == nfts.length &&
                nfts.length == erc20Amounts.length,
            "LooksRareV2Config::getPayload_BuyOfferedManyERC721WithWETHDistinctOrders: invalid input"
        );

        ManyItemsCalldataParams memory params = buildManyItemsCalldataParams(
            contexts.length
        );

        for (uint256 i = 0; i < contexts.length; i++) {
            params.makerAsks[i] = buildMakerOrder({
                quoteType: QuoteType.Ask,
                orderNonce: i,
                maker: contexts[i].offerer,
                currency: erc20Address,
                price: erc20Amounts[i],
                collectionType: CollectionType.ERC721,
                collection: nfts[i].token,
                amount: 1,
                itemId: nfts[i].identifier
            });
            params.makerSignatures[i] = buildMakerSignature(
                params.makerAsks[i]
            );
            params.takerBids[i] = buildTakerOrder(contexts[i].fulfiller);
        }

        execution.executeOrder = TestCallParameters(
            address(LOOKS_RARE),
            0,
            abi.encodeWithSelector(
                ILooksRareProtocol.executeMultipleTakerBids.selector,
                params.takerBids,
                params.makerAsks,
                params.makerSignatures,
                params.merkleTrees,
                NO_AFFILIATE,
                false
            )
        );
    }
}
