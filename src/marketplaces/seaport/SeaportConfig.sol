// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationTypeHashes.sol";
import { ConsiderationInterface as ISeaport } from "./interfaces/ConsiderationInterface.sol";
import "forge-std/console2.sol";

contract SeaportConfig is BaseMarketConfig, ConsiderationTypeHashes {
    function name() external pure override returns (string memory) {
        return "Seaport";
    }

    function market() public pure override returns (address) {
        return address(seaport);
    }

    ISeaport internal constant seaport =
        ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    function buildBasicOrder(
        BasicOrderRouteType routeType,
        address offerer,
        OfferItem memory offerItem,
        ConsiderationItem memory considerationItem
    )
        internal
        view
        returns (
            Order memory order,
            BasicOrderParameters memory basicComponents
        )
    {
        OrderParameters memory components = order.parameters;
        components.offerer = offerer;
        components.offer = new OfferItem[](1);
        components.consideration = new ConsiderationItem[](1);
        components.offer[0] = offerItem;
        components.consideration[0] = considerationItem;
        components.startTime = 0;
        components.endTime = block.timestamp + 1;
        components.totalOriginalConsiderationItems = 1;
        basicComponents.startTime = 0;
        basicComponents.endTime = block.timestamp + 1;
        basicComponents.considerationToken = considerationItem.token;
        basicComponents.considerationIdentifier = considerationItem
            .identifierOrCriteria;
        basicComponents.considerationAmount = considerationItem.endAmount;
        basicComponents.offerer = payable(offerer);
        basicComponents.offerToken = offerItem.token;
        basicComponents.offerIdentifier = offerItem.identifierOrCriteria;
        basicComponents.offerAmount = offerItem.endAmount;
        basicComponents.basicOrderType = BasicOrderType(uint256(routeType) * 4);
        basicComponents.totalOriginalAdditionalRecipients = 0;
        bytes32 digest = _deriveEIP712Digest(_deriveOrderHash(components, 0));
        (uint8 v, bytes32 r, bytes32 s) = _sign(offerer, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        basicComponents.signature = (order.signature = signature);
    }

    function buildBasicOrder(
        BasicOrderRouteType routeType,
        address offerer,
        OfferItem memory offerItem,
        ConsiderationItem memory considerationItem,
        AdditionalRecipient[] memory additionalRecipients
    )
        internal
        view
        returns (
            Order memory order,
            BasicOrderParameters memory basicComponents
        )
    {
        OrderParameters memory components = order.parameters;
        components.offerer = offerer;
        components.offer = new OfferItem[](1);
        components.consideration = new ConsiderationItem[](
            1 + additionalRecipients.length
        );
        components.offer[0] = offerItem;
        components.consideration[0] = considerationItem;

        // Add additional recipients
        address additionalRecipientsToken;
        if (
            routeType == BasicOrderRouteType.ERC721_TO_ERC20 ||
            routeType == BasicOrderRouteType.ERC1155_TO_ERC20
        ) {
            additionalRecipientsToken = offerItem.token;
        } else {
            additionalRecipientsToken = considerationItem.token;
        }
        ItemType additionalRecipientsItemType;
        if (
            routeType == BasicOrderRouteType.ETH_TO_ERC721 ||
            routeType == BasicOrderRouteType.ETH_TO_ERC1155
        ) {
            additionalRecipientsItemType = ItemType.NATIVE;
        } else {
            additionalRecipientsItemType = ItemType.ERC20;
        }
        for (uint256 i = 0; i < additionalRecipients.length; i++) {
            components.consideration[i + 1] = ConsiderationItem(
                additionalRecipientsItemType,
                additionalRecipientsToken,
                0,
                additionalRecipients[i].amount,
                additionalRecipients[i].amount,
                additionalRecipients[i].recipient
            );
        }

        components.startTime = 0;
        components.endTime = block.timestamp + 1;
        components.totalOriginalConsiderationItems =
            1 +
            additionalRecipients.length;
        basicComponents.startTime = 0;
        basicComponents.endTime = block.timestamp + 1;
        basicComponents.considerationToken = considerationItem.token;
        basicComponents.considerationIdentifier = considerationItem
            .identifierOrCriteria;
        basicComponents.considerationAmount = considerationItem.endAmount;
        basicComponents.offerer = payable(offerer);
        basicComponents.offerToken = offerItem.token;
        basicComponents.offerIdentifier = offerItem.identifierOrCriteria;
        basicComponents.offerAmount = offerItem.endAmount;
        basicComponents.basicOrderType = BasicOrderType(uint256(routeType) * 4);
        basicComponents.additionalRecipients = additionalRecipients;
        basicComponents.totalOriginalAdditionalRecipients = additionalRecipients
            .length;
        bytes32 digest = _deriveEIP712Digest(_deriveOrderHash(components, 0));
        (uint8 v, bytes32 r, bytes32 s) = _sign(offerer, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        basicComponents.signature = (order.signature = signature);
    }

    function buildOrder(
        address offerer,
        OfferItem[] memory offerItems,
        ConsiderationItem[] memory considerationItems
    ) internal view returns (Order memory order) {
        OrderParameters memory components = order.parameters;
        components.offerer = offerer;
        components.offer = offerItems;
        components.consideration = considerationItems;
        components.orderType = OrderType.FULL_OPEN;
        components.startTime = 0;
        components.endTime = block.timestamp + 1;
        components.totalOriginalConsiderationItems = considerationItems.length;
        bytes32 digest = _deriveEIP712Digest(_deriveOrderHash(components, 0));
        (uint8 v, bytes32 r, bytes32 s) = _sign(offerer, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        order.signature = signature;
    }

    function buildOrderAndFulfillmentManyDistinctOrders(
        TestOrderContext[] memory contexts,
        address paymentTokenAddress,
        TestItem721[] memory nfts,
        uint256[] memory amounts
    )
        internal
        view
        returns (
            Order[] memory,
            Fulfillment[] memory,
            uint256
        )
    {
        Order[] memory orders = new Order[](nfts.length + 1);

        ConsiderationItem[]
            memory fulfillerConsiderationItems = new ConsiderationItem[](
                nfts.length
            );

        Fulfillment[] memory fullfillments = new Fulfillment[](nfts.length + 1);

        for (uint256 i = 0; i < nfts.length; i++) {
            // Build offer orders
            OfferItem[] memory offerItems = new OfferItem[](1);

            ConsiderationItem[]
                memory considerationItems = new ConsiderationItem[](1);
            {
                offerItems[0] = OfferItem(
                    ItemType.ERC721,
                    nfts[i].token,
                    nfts[i].identifier,
                    1,
                    1
                );
            }
            {
                considerationItems[0] = ConsiderationItem(
                    paymentTokenAddress != address(0)
                        ? ItemType.ERC20
                        : ItemType.NATIVE,
                    paymentTokenAddress,
                    0,
                    amounts[i],
                    amounts[i],
                    payable(contexts[i].offerer)
                );
            }
            {
                orders[i] = buildOrder(
                    contexts[i].offerer,
                    offerItems,
                    considerationItems
                );
            }
            {
                fulfillerConsiderationItems[i] = ConsiderationItem(
                    ItemType.ERC721,
                    nfts[i].token,
                    nfts[i].identifier,
                    1,
                    1,
                    payable(contexts[i].fulfiller)
                );
            }
            {
                // Add fulfillment components for each NFT

                FulfillmentComponent
                    memory nftConsiderationComponent = FulfillmentComponent(
                        nfts.length,
                        i
                    );

                FulfillmentComponent
                    memory nftOfferComponent = FulfillmentComponent(i, 0);

                FulfillmentComponent[]
                    memory nftOfferComponents = new FulfillmentComponent[](1);
                nftOfferComponents[0] = nftOfferComponent;

                FulfillmentComponent[]
                    memory nftConsiderationComponents = new FulfillmentComponent[](
                        1
                    );
                nftConsiderationComponents[0] = nftConsiderationComponent;
                fullfillments[i] = Fulfillment(
                    nftOfferComponents,
                    nftConsiderationComponents
                );
            }
        }

        uint256 sumAmounts = 0;

        for (uint256 i = 0; i < nfts.length; i++) {
            sumAmounts += amounts[i];
        }

        {
            FulfillmentComponent
                memory paymentTokenOfferComponent = FulfillmentComponent(
                    nfts.length,
                    0
                );

            FulfillmentComponent[]
                memory paymentTokenOfferComponents = new FulfillmentComponent[](
                    1
                );
            paymentTokenOfferComponents[0] = paymentTokenOfferComponent;

            FulfillmentComponent[]
                memory paymentTokenConsiderationComponents = new FulfillmentComponent[](
                    nfts.length
                );
            for (uint256 i = 0; i < nfts.length; i++) {
                {
                    FulfillmentComponent
                        memory paymentTokenConsiderationComponent = FulfillmentComponent(
                            i,
                            0
                        );
                    paymentTokenConsiderationComponents[
                        i
                    ] = paymentTokenConsiderationComponent;
                }
            }
            fullfillments[nfts.length] = Fulfillment(
                paymentTokenOfferComponents,
                paymentTokenConsiderationComponents
            );
        }

        // Build sweep floor order
        OfferItem[] memory fulfillerOfferItems = new OfferItem[](1);
        fulfillerOfferItems[0] = OfferItem(
            paymentTokenAddress != address(0)
                ? ItemType.ERC20
                : ItemType.NATIVE,
            paymentTokenAddress,
            0,
            sumAmounts,
            sumAmounts
        );
        orders[nfts.length] = buildOrder(
            contexts[0].fulfiller,
            fulfillerOfferItems,
            fulfillerConsiderationItems
        );
        orders[nfts.length].signature = ""; // Signature isn't needed since fulfiller is msg.sender

        return (orders, fullfillments, sumAmounts);
    }

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            seaport
        );
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
                context.offerer,
                OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
                ConsiderationItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    ethAmount,
                    ethAmount,
                    payable(context.offerer)
                )
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            ethAmount,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC1155,
                context.offerer,
                OfferItem(
                    ItemType.ERC1155,
                    nft.token,
                    nft.identifier,
                    nft.amount,
                    nft.amount
                ),
                ConsiderationItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    ethAmount,
                    ethAmount,
                    payable(context.offerer)
                )
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            ethAmount,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ERC20_TO_ERC721,
                context.offerer,
                OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
                ConsiderationItem(
                    ItemType.ERC20,
                    erc20.token,
                    0,
                    erc20.amount,
                    erc20.amount,
                    payable(context.offerer)
                )
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ERC20_TO_ERC1155,
                context.offerer,
                OfferItem(
                    ItemType.ERC1155,
                    nft.token,
                    nft.identifier,
                    nft.amount,
                    nft.amount
                ),
                ConsiderationItem(
                    ItemType.ERC20,
                    erc20.token,
                    0,
                    erc20.amount,
                    erc20.amount,
                    payable(context.offerer)
                )
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ERC721_TO_ERC20,
                context.offerer,
                OfferItem(
                    ItemType.ERC20,
                    erc20.token,
                    0,
                    erc20.amount,
                    erc20.amount
                ),
                ConsiderationItem(
                    ItemType.ERC721,
                    nft.token,
                    nft.identifier,
                    1,
                    1,
                    payable(context.offerer)
                )
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem1155 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ERC1155_TO_ERC20,
                context.offerer,
                OfferItem(
                    ItemType.ERC20,
                    erc20.token,
                    0,
                    erc20.amount,
                    erc20.amount
                ),
                ConsiderationItem(
                    ItemType.ERC1155,
                    nft.token,
                    nft.identifier,
                    nft.amount,
                    nft.amount,
                    payable(context.offerer)
                )
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC721WithERC1155(
        TestOrderContext calldata context,
        TestItem721 memory sellNft,
        TestItem1155 calldata buyNft
    ) external view override returns (TestOrderPayload memory execution) {
        OfferItem[] memory offerItems = new OfferItem[](1);
        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
            1
        );

        offerItems[0] = OfferItem(
            ItemType.ERC721,
            sellNft.token,
            sellNft.identifier,
            1,
            1
        );
        considerationItems[0] = ConsiderationItem(
            ItemType.ERC1155,
            buyNft.token,
            buyNft.identifier,
            buyNft.amount,
            buyNft.amount,
            payable(context.offerer)
        );

        Order memory order = buildOrder(
            context.offerer,
            offerItems,
            considerationItems
        );

        if (context.listOnChain) {
            order.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(ISeaport.fulfillOrder.selector, order, 0)
        );
    }

    function getPayload_BuyOfferedERC1155WithERC721(
        TestOrderContext calldata context,
        TestItem1155 memory sellNft,
        TestItem721 calldata buyNft
    ) external view override returns (TestOrderPayload memory execution) {
        OfferItem[] memory offerItems = new OfferItem[](1);
        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
            1
        );

        offerItems[0] = OfferItem(
            ItemType.ERC1155,
            sellNft.token,
            sellNft.identifier,
            sellNft.amount,
            sellNft.amount
        );
        considerationItems[0] = ConsiderationItem(
            ItemType.ERC721,
            buyNft.token,
            buyNft.identifier,
            1,
            1,
            payable(context.offerer)
        );

        Order memory order = buildOrder(
            context.offerer,
            offerItems,
            considerationItems
        );

        if (context.listOnChain) {
            order.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(ISeaport.fulfillOrder.selector, order, 0)
        );
    }

    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient,
        uint256 feeEthAmount
    ) external view override returns (TestOrderPayload memory execution) {
        AdditionalRecipient[]
            memory additionalRecipients = new AdditionalRecipient[](1);
        additionalRecipients[0] = AdditionalRecipient(
            feeEthAmount,
            payable(feeRecipient)
        );
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
                context.offerer,
                OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
                ConsiderationItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    priceEthAmount,
                    priceEthAmount,
                    payable(context.offerer)
                ),
                additionalRecipients
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            priceEthAmount + feeEthAmount,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedERC721WithEtherTwoFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient1,
        uint256 feeEthAmount1,
        address feeRecipient2,
        uint256 feeEthAmount2
    ) external view override returns (TestOrderPayload memory execution) {
        AdditionalRecipient[]
            memory additionalRecipients = new AdditionalRecipient[](2);

        additionalRecipients[0] = AdditionalRecipient(
            feeEthAmount1,
            payable(feeRecipient1)
        );
        additionalRecipients[1] = AdditionalRecipient(
            feeEthAmount2,
            payable(feeRecipient2)
        );
        ConsiderationItem memory consideration = ConsiderationItem(
            ItemType.NATIVE,
            address(0),
            0,
            priceEthAmount,
            priceEthAmount,
            payable(context.offerer)
        );
        (
            Order memory order,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
                context.offerer,
                OfferItem(ItemType.ERC721, nft.token, nft.identifier, 1, 1),
                consideration,
                additionalRecipients
            );
        if (context.listOnChain) {
            order.signature = "";
            basicComponents.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(seaport),
            priceEthAmount + feeEthAmount1 + feeEthAmount2,
            abi.encodeWithSelector(
                ISeaport.fulfillBasicOrder.selector,
                basicComponents
            )
        );
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        OfferItem[] memory offerItems = new OfferItem[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            offerItems[i] = OfferItem(
                ItemType.ERC721,
                nfts[i].token,
                nfts[i].identifier,
                1,
                1
            );
        }

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
            1
        );

        considerationItems[0] = ConsiderationItem(
            ItemType.NATIVE,
            address(0),
            0,
            ethAmount,
            ethAmount,
            payable(context.offerer)
        );

        Order memory order = buildOrder(
            context.offerer,
            offerItems,
            considerationItems
        );

        if (context.listOnChain) {
            order.signature = "";

            Order[] memory orders = new Order[](1);
            orders[0] = order;
            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(ISeaport.validate.selector, orders)
            );
        }

        execution.executeOrder = TestCallParameters(
            address(seaport),
            ethAmount,
            abi.encodeWithSelector(ISeaport.fulfillOrder.selector, order, 0)
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        require(
            contexts.length == nfts.length && nfts.length == ethAmounts.length,
            "SeaportConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
        );

        (
            Order[] memory orders,
            Fulfillment[] memory fullfillments,
            uint256 sumEthAmount
        ) = buildOrderAndFulfillmentManyDistinctOrders(
                contexts,
                address(0),
                nfts,
                ethAmounts
            );

        // Validate all for simplicity for now, could make this combination of on-chain and not
        if (contexts[0].listOnChain) {
            Order[] memory ordersToValidate = new Order[](orders.length - 1); // Last order is fulfiller order
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i].signature = "";
                ordersToValidate[i] = orders[i];
            }

            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(
                    ISeaport.validate.selector,
                    ordersToValidate
                )
            );
        }

        execution.executeOrder = TestCallParameters(
            address(seaport),
            sumEthAmount,
            abi.encodeWithSelector(
                ISeaport.matchOrders.selector,
                orders,
                fullfillments
            )
        );
    }

    function getPayload_BuyOfferedManyERC721WithErc20DistinctOrders(
        TestOrderContext[] calldata contexts,
        address erc20Address,
        TestItem721[] calldata nfts,
        uint256[] calldata erc20Amounts
    ) external view override returns (TestOrderPayload memory execution) {
        require(
            contexts.length == nfts.length &&
                nfts.length == erc20Amounts.length,
            "SeaportConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
        );
        (
            Order[] memory orders,
            Fulfillment[] memory fullfillments,

        ) = buildOrderAndFulfillmentManyDistinctOrders(
                contexts,
                erc20Address,
                nfts,
                erc20Amounts
            );

        // Validate all for simplicity for now, could make this combination of on-chain and not
        if (contexts[0].listOnChain) {
            Order[] memory ordersToValidate = new Order[](orders.length - 1); // Last order is fulfiller order
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i].signature = "";
                ordersToValidate[i] = orders[i];
            }

            execution.submitOrder = TestCallParameters(
                address(seaport),
                0,
                abi.encodeWithSelector(
                    ISeaport.validate.selector,
                    ordersToValidate
                )
            );
        }

        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(
                ISeaport.matchOrders.selector,
                orders,
                fullfillments
            )
        );
    }

    function getPayload_MatchOrders_ABCA(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts
    ) external view override returns (TestOrderPayload memory execution) {
        require(contexts.length == nfts.length, "invalid input");

        Order[] memory orders = new Order[](contexts.length);
        Fulfillment[] memory fullfillments = new Fulfillment[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            uint256 wrappedIndex = i + 1 == nfts.length ? 0 : i + 1; // wrap around back to 0
            {
                OfferItem[] memory offerItems = new OfferItem[](1);
                offerItems[0] = OfferItem(
                    ItemType.ERC721,
                    nfts[i].token,
                    nfts[i].identifier,
                    1,
                    1
                );

                ConsiderationItem[]
                    memory considerationItems = new ConsiderationItem[](1);
                considerationItems[0] = ConsiderationItem(
                    ItemType.ERC721,
                    nfts[wrappedIndex].token,
                    nfts[wrappedIndex].identifier,
                    1,
                    1,
                    payable(contexts[i].offerer)
                );
                orders[i] = buildOrder(
                    contexts[i].offerer,
                    offerItems,
                    considerationItems
                );
            }
            // Set fulfillment
            {
                FulfillmentComponent
                    memory nftConsiderationComponent = FulfillmentComponent(
                        i,
                        0
                    );

                FulfillmentComponent
                    memory nftOfferComponent = FulfillmentComponent(
                        wrappedIndex,
                        0
                    );

                FulfillmentComponent[]
                    memory nftOfferComponents = new FulfillmentComponent[](1);
                nftOfferComponents[0] = nftOfferComponent;

                FulfillmentComponent[]
                    memory nftConsiderationComponents = new FulfillmentComponent[](
                        1
                    );
                nftConsiderationComponents[0] = nftConsiderationComponent;
                fullfillments[i] = Fulfillment(
                    nftOfferComponents,
                    nftConsiderationComponents
                );
            }
        }

        execution.executeOrder = TestCallParameters(
            address(seaport),
            0,
            abi.encodeWithSelector(
                ISeaport.matchOrders.selector,
                orders,
                fullfillments
            )
        );
    }
}
