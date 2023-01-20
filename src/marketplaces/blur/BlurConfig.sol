// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20, SetupCall } from "../../Types.sol";
import "./lib/OrderStructs.sol";
import "./lib/BlurTypeHashes.sol";
import { IBlurExchange } from "./interfaces/IBlurExchange.sol";
import "forge-std/console2.sol";

contract BlurConfig is BaseMarketConfig, BlurTypeHashes {
    function name() external pure override returns (string memory) {
        return "Blur";
    }

    function market() public pure override returns (address) {
        return address(blur);
    }

    IBlurExchange internal constant blur =
        IBlurExchange(0x000000000000Ad05Ccc4F10045630fb830B95127);

    // The "execution delegate" — functions similarly to a conduit
    address internal constant approvalTarget =
        0x00000000000111AbE46ff893f3B2fdF1F759a8A8;

    address internal constant BlurOwner =
        0x0000000000000000000000000000000000000000;

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
    ) external pure override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](1);

        // address[] memory removeSigners = new address[](0);
        // address[] memory addSigners = new address[](1);
        // addSigners[0] = seller;

        // Set seller as a signer for blur
        setupCalls[0] = SetupCall(
            BlurOwner,
            address(blur),
            abi.encodeWithSelector(IBlurExchange.open.selector)
        );

        return setupCalls;
    }

    ////////////////////////////////////////////////////////////
    // require(_validateSignatures(sell, sellHash), "Sell failed authorization");
    // [FAIL. Reason: Sell failed authorization] testBlur() (gas: 1940642)

    function buildOrder(
        address creator,
        Side side,
        address nftContractAddress,
        uint256 nftTokenId,
        uint256 nftAmount,
        address paymentToken,
        uint256 paymentTokenAmount
    )
        internal
        view
        returns (
            Order memory _order,
            uint8 _v,
            bytes32 _r,
            bytes32 _s
        )
    {
        Order memory order;

        order.trader = creator;
        order.side = side;

        // see "policy manager" at 0x3a35A3102b5c6bD1e4d3237248Be071EF53C8331
        order.matchingPolicy = address(
            0x00000000006411739DA1c40B106F8511de5D1FAC
        );

        order.collection = nftContractAddress;
        order.tokenId = nftTokenId;
        order.amount = nftAmount;
        order.paymentToken = paymentToken;
        order.price = paymentTokenAmount;
        order.listingTime = 0;
        order.expirationTime = block.timestamp + 1; // Might want to go back and change this.
        order.fees = new Fee[](0);
        order.salt = 0;
        order.extraParams = new bytes(0);

        (uint8 v, bytes32 r, bytes32 s) = _sign(
            creator,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    _hashOrder(order, 0) // Nonce management might be a pain.
                )
            )
        );

        return (order, v, r, s);
    }

    function buildInput(
        Order memory order,
        uint8 v,
        bytes32 r,
        bytes32 s,
        SignatureVersion signatureVersion
    ) internal view returns (Input memory _input) {
        Input memory input;

        input.order = order;
        input.v = v;
        input.r = r;
        input.s = s;
        input.extraSignature = new bytes(0);
        input.signatureVersion = signatureVersion;
        input.blockNumber = block.number;

        return input;
    }

    function buildExecution(Input memory sell, Input memory buy)
        internal
        pure
        returns (Execution memory _execution)
    {
        Execution memory execution;

        execution.sell = sell;
        execution.buy = buy;

        return execution;
    }

    function buildInputPair(
        address maker,
        address taker,
        address nftContractAddress,
        uint256 nftTokenId,
        uint256 nftAmount,
        address paymentToken,
        uint256 paymentTokenAmount
    ) internal view returns (Input memory makerInput, Input memory takerInput) {
        Order memory makerOrder;
        Order memory takerOrder;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (makerOrder, v, r, s) = buildOrder(
            maker,
            Side.Sell, // Might want to make this a parameter.
            nftContractAddress,
            nftTokenId,
            nftAmount,
            paymentToken,
            paymentTokenAmount
        );

        makerInput = buildInput(makerOrder, v, r, s, SignatureVersion.Single);

        (takerOrder, v, r, s) = buildOrder(
            taker,
            Side.Buy, // Might want to make this a parameter.
            nftContractAddress,
            nftTokenId,
            nftAmount,
            paymentToken,
            paymentTokenAmount
        );

        takerInput = buildInput(takerOrder, v, r, s, SignatureVersion.Single);

        return (makerInput, takerInput);
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (Input memory makerInput, Input memory takerInput) = buildInputPair(
            context.offerer,
            context.fulfiller,
            nft.token,
            nft.identifier,
            1,
            address(0),
            ethAmount
        );

        if (context.listOnChain) {
            _notImplemented();
        }
        execution.executeOrder = TestCallParameters(
            address(blur),
            ethAmount,
            abi.encodeWithSelector(
                IBlurExchange.execute.selector,
                makerInput,
                takerInput
            )
        );
    }

    // function getPayload_BuyOfferedERC1155WithEther(
    //     TestOrderContext calldata context,
    //     TestItem1155 memory nft,
    //     uint256 ethAmount
    // ) external view override returns (TestOrderPayload memory execution) {
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ETH_TO_ERC1155,
    //             context.offerer,
    //             OfferItem(
    //                 ItemType.ERC1155,
    //                 nft.token,
    //                 nft.identifier,
    //                 nft.amount,
    //                 nft.amount
    //             ),
    //             ConsiderationItem(
    //                 ItemType.NATIVE,
    //                 address(0),
    //                 0,
    //                 ethAmount,
    //                 ethAmount,
    //                 payable(context.offerer)
    //             )
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         ethAmount,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC721WithERC20(
    //     TestOrderContext calldata context,
    //     TestItem721 memory nft,
    //     TestItem20 memory erc20
    // ) external view override returns (TestOrderPayload memory execution) {
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ERC20_TO_ERC721,
    //             context.offerer,
    //             OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
    //             ConsiderationItem(
    //                 ItemType.ERC20,
    //                 erc20.token,
    //                 0,
    //                 erc20.amount,
    //                 erc20.amount,
    //                 payable(context.offerer)
    //             )
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC1155WithERC20(
    //     TestOrderContext calldata context,
    //     TestItem1155 calldata nft,
    //     TestItem20 memory erc20
    // ) external view override returns (TestOrderPayload memory execution) {
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ERC20_TO_ERC1155,
    //             context.offerer,
    //             OfferItem(
    //                 ItemType.ERC1155,
    //                 nft.token,
    //                 nft.identifier,
    //                 nft.amount,
    //                 nft.amount
    //             ),
    //             ConsiderationItem(
    //                 ItemType.ERC20,
    //                 erc20.token,
    //                 0,
    //                 erc20.amount,
    //                 erc20.amount,
    //                 payable(context.offerer)
    //             )
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC20WithERC721(
    //     TestOrderContext calldata context,
    //     TestItem20 memory erc20,
    //     TestItem721 memory nft
    // ) external view override returns (TestOrderPayload memory execution) {
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ERC721_TO_ERC20,
    //             context.offerer,
    //             OfferItem(
    //                 ItemType.ERC20,
    //                 erc20.token,
    //                 0,
    //                 erc20.amount,
    //                 erc20.amount
    //             ),
    //             ConsiderationItem(
    //                 ItemType.ERC721,
    //                 nft.token,
    //                 nft.identifier,
    //                 1,
    //                 1,
    //                 payable(context.offerer)
    //             )
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC20WithERC1155(
    //     TestOrderContext calldata context,
    //     TestItem20 memory erc20,
    //     TestItem1155 calldata nft
    // ) external view override returns (TestOrderPayload memory execution) {
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ERC1155_TO_ERC20,
    //             context.offerer,
    //             OfferItem(
    //                 ItemType.ERC20,
    //                 erc20.token,
    //                 0,
    //                 erc20.amount,
    //                 erc20.amount
    //             ),
    //             ConsiderationItem(
    //                 ItemType.ERC1155,
    //                 nft.token,
    //                 nft.identifier,
    //                 nft.amount,
    //                 nft.amount,
    //                 payable(context.offerer)
    //             )
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC721WithERC1155(
    //     TestOrderContext calldata context,
    //     TestItem721 memory sellNft,
    //     TestItem1155 calldata buyNft
    // ) external view override returns (TestOrderPayload memory execution) {
    //     OfferItem[] memory offerItems = new OfferItem[](1);
    //     ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
    //         1
    //     );

    //     offerItems[0] = OfferItem(
    //         ItemType.ERC721,
    //         sellNft.token,
    //         sellNft.identifier,
    //         1,
    //         1
    //     );
    //     considerationItems[0] = ConsiderationItem(
    //         ItemType.ERC1155,
    //         buyNft.token,
    //         buyNft.identifier,
    //         buyNft.amount,
    //         buyNft.amount,
    //         payable(context.offerer)
    //     );

    //     Order memory order = buildOrder(
    //         context.offerer,
    //         offerItems,
    //         considerationItems
    //     );

    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC1155WithERC721(
    //     TestOrderContext calldata context,
    //     TestItem1155 memory sellNft,
    //     TestItem721 calldata buyNft
    // ) external view override returns (TestOrderPayload memory execution) {
    //     OfferItem[] memory offerItems = new OfferItem[](1);
    //     ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
    //         1
    //     );

    //     offerItems[0] = OfferItem(
    //         ItemType.ERC1155,
    //         sellNft.token,
    //         sellNft.identifier,
    //         sellNft.amount,
    //         sellNft.amount
    //     );
    //     considerationItems[0] = ConsiderationItem(
    //         ItemType.ERC721,
    //         buyNft.token,
    //         buyNft.identifier,
    //         1,
    //         1,
    //         payable(context.offerer)
    //     );

    //     Order memory order = buildOrder(
    //         context.offerer,
    //         offerItems,
    //         considerationItems
    //     );

    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
    //     TestOrderContext calldata context,
    //     TestItem721 memory nft,
    //     uint256 priceEthAmount,
    //     address feeRecipient,
    //     uint256 feeEthAmount
    // ) external view override returns (TestOrderPayload memory execution) {
    //     AdditionalRecipient[]
    //         memory additionalRecipients = new AdditionalRecipient[](1);
    //     additionalRecipients[0] = AdditionalRecipient(
    //         feeEthAmount,
    //         payable(feeRecipient)
    //     );
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ETH_TO_ERC721,
    //             context.offerer,
    //             OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
    //             ConsiderationItem(
    //                 ItemType.NATIVE,
    //                 address(0),
    //                 0,
    //                 priceEthAmount,
    //                 priceEthAmount,
    //                 payable(context.offerer)
    //             ),
    //             additionalRecipients
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         priceEthAmount + feeEthAmount,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedERC721WithEtherTwoFeeRecipient(
    //     TestOrderContext calldata context,
    //     TestItem721 memory nft,
    //     uint256 priceEthAmount,
    //     address feeRecipient1,
    //     uint256 feeEthAmount1,
    //     address feeRecipient2,
    //     uint256 feeEthAmount2
    // ) external view override returns (TestOrderPayload memory execution) {
    //     AdditionalRecipient[]
    //         memory additionalRecipients = new AdditionalRecipient[](2);

    //     additionalRecipients[0] = AdditionalRecipient(
    //         feeEthAmount1,
    //         payable(feeRecipient1)
    //     );
    //     additionalRecipients[1] = AdditionalRecipient(
    //         feeEthAmount2,
    //         payable(feeRecipient2)
    //     );
    //     ConsiderationItem memory consideration = ConsiderationItem(
    //         ItemType.NATIVE,
    //         address(0),
    //         0,
    //         priceEthAmount,
    //         priceEthAmount,
    //         payable(context.offerer)
    //     );
    //     (
    //         Order memory order,
    //         BasicOrderParameters memory basicComponents
    //     ) = buildBasicOrder(
    //             BasicOrderRouteType.ETH_TO_ERC721,
    //             context.offerer,
    //             OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
    //             consideration,
    //             additionalRecipients
    //         );
    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }
    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         priceEthAmount + feeEthAmount1 + feeEthAmount2,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedManyERC721WithEther(
    //     TestOrderContext calldata context,
    //     TestItem721[] calldata nfts,
    //     uint256 ethAmount
    // ) external view override returns (TestOrderPayload memory execution) {
    //     OfferItem[] memory offerItems = new OfferItem[](nfts.length);

    //     for (uint256 i = 0; i < nfts.length; i++) {
    //         offerItems[i] = OfferItem(
    //             ItemType.ERC721,
    //             nfts[i].token,
    //             nfts[i].identifier,
    //             1,
    //             1
    //         );
    //     }

    //     ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
    //         1
    //     );

    //     considerationItems[0] = ConsiderationItem(
    //         ItemType.NATIVE,
    //         address(0),
    //         0,
    //         ethAmount,
    //         ethAmount,
    //         payable(context.offerer)
    //     );

    //     Order memory order = buildOrder(
    //         context.offerer,
    //         offerItems,
    //         considerationItems
    //     );

    //     if (context.listOnChain) {
    //         _notImplemented();
    //     }

    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         ethAmount,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
    //     TestOrderContext[] calldata contexts,
    //     TestItem721[] calldata nfts,
    //     uint256[] calldata ethAmounts
    // ) external view override returns (TestOrderPayload memory execution) {
    //     require(
    //         contexts.length == nfts.length && nfts.length == ethAmounts.length,
    //         "SeaportConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
    //     );

    //     (
    //         Order[] memory orders,
    //         Fulfillment[] memory fullfillments,
    //         uint256 sumEthAmount
    //     ) = buildOrderAndFulfillmentManyDistinctOrders(
    //             contexts,
    //             address(0),
    //             nfts,
    //             ethAmounts
    //         );

    //     // Validate all for simplicity for now, could make this combination of on-chain and not
    //     if (contexts[0].listOnChain) {
    //         Order[] memory ordersToValidate = new Order[](orders.length - 1); // Last order is fulfiller order
    //         for (uint256 i = 0; i < orders.length - 1; i++) {
    //             orders[i].signature = "";
    //             ordersToValidate[i] = orders[i];
    //         }

    //         execution.submitOrder = TestCallParameters(
    //             address(blur),
    //             0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //         );
    //     }

    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         sumEthAmount,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_BuyOfferedManyERC721WithErc20DistinctOrders(
    //     TestOrderContext[] calldata contexts,
    //     address erc20Address,
    //     TestItem721[] calldata nfts,
    //     uint256[] calldata erc20Amounts
    // ) external view override returns (TestOrderPayload memory execution) {
    //     require(
    //         contexts.length == nfts.length &&
    //             nfts.length == erc20Amounts.length,
    //         "SeaportConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
    //     );
    //     (
    //         Order[] memory orders,
    //         Fulfillment[] memory fullfillments,

    //     ) = buildOrderAndFulfillmentManyDistinctOrders(
    //             contexts,
    //             erc20Address,
    //             nfts,
    //             erc20Amounts
    //         );

    //     // Validate all for simplicity for now, could make this combination of on-chain and not
    //     if (contexts[0].listOnChain) {
    //         Order[] memory ordersToValidate = new Order[](orders.length - 1); // Last order is fulfiller order
    //         for (uint256 i = 0; i < orders.length - 1; i++) {
    //             orders[i].signature = "";
    //             ordersToValidate[i] = orders[i];
    //         }

    //         execution.submitOrder = TestCallParameters(
    //             address(blur),
    //             0,
    //             abi.encodeWithSelector(
    //                 IBlurExchange.validate.selector,
    //                 ordersToValidate
    //             )
    //         );
    //     }

    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }

    // function getPayload_MatchOrders_ABCA(
    //     TestOrderContext[] calldata contexts,
    //     TestItem721[] calldata nfts
    // ) external view override returns (TestOrderPayload memory execution) {
    //     require(contexts.length == nfts.length, "invalid input");

    //     Order[] memory orders = new Order[](contexts.length);
    //     Fulfillment[] memory fullfillments = new Fulfillment[](nfts.length);

    //     for (uint256 i = 0; i < nfts.length; i++) {
    //         uint256 wrappedIndex = i + 1 == nfts.length ? 0 : i + 1; // wrap around back to 0
    //         {
    //             OfferItem[] memory offerItems = new OfferItem[](1);
    //             offerItems[0] = OfferItem(
    //                 ItemType.ERC721,
    //                 nfts[i].token,
    //                 nfts[i].identifier,
    //                 1,
    //                 1
    //             );

    //             ConsiderationItem[]
    //                 memory considerationItems = new ConsiderationItem[](1);
    //             considerationItems[0] = ConsiderationItem(
    //                 ItemType.ERC721,
    //                 nfts[wrappedIndex].token,
    //                 nfts[wrappedIndex].identifier,
    //                 1,
    //                 1,
    //                 payable(contexts[i].offerer)
    //             );
    //             orders[i] = buildOrder(
    //                 contexts[i].offerer,
    //                 offerItems,
    //                 considerationItems
    //             );
    //         }
    //         // Set fulfillment
    //         {
    //             FulfillmentComponent
    //                 memory nftConsiderationComponent = FulfillmentComponent(
    //                     i,
    //                     0
    //                 );

    //             FulfillmentComponent
    //                 memory nftOfferComponent = FulfillmentComponent(
    //                     wrappedIndex,
    //                     0
    //                 );

    //             FulfillmentComponent[]
    //                 memory nftOfferComponents = new FulfillmentComponent[](1);
    //             nftOfferComponents[0] = nftOfferComponent;

    //             FulfillmentComponent[]
    //                 memory nftConsiderationComponents = new FulfillmentComponent[](
    //                     1
    //                 );
    //             nftConsiderationComponents[0] = nftConsiderationComponent;
    //             fullfillments[i] = Fulfillment(
    //                 nftOfferComponents,
    //                 nftConsiderationComponents
    //             );
    //         }
    //     }

    //     execution.executeOrder = TestCallParameters(
    //         address(blur),
    //         0,
    //         abi.encodeWithSelector(
    //             IBlurExchange.execute.selector,
    //             makerInput,
    //             takerInput
    //         )
    //     );
    // }
}
