// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationTypeHashes.sol";
import { ConsiderationInterface as ISeaport } from "./interfaces/ConsiderationInterface.sol";

contract SeaportConfig is BaseMarketConfig, ConsiderationTypeHashes {
    function name() external view virtual override returns (string memory) {
      return "Seaport";
    }

    ISeaport internal constant seaport =
        ISeaport(0x00000000006CEE72100D161c57ADA5Bb2be1CA79);

    function approvalTarget() external view virtual override returns (address) {
        return address(seaport);
    }

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
        bytes memory signature = _sign(offerer, digest);
        basicComponents.signature = (order.signature = signature);
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    )
        external
        view
        virtual
        override
        returns (TestOrderPayload memory execution)
    {
        (
            /* Order memory order */,
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
            Order[] memory orders = new Order[](1);
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
    )
        external
        view
        virtual
        override
        returns (TestOrderPayload memory execution)
    {
        (
            /* Order memory order */,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
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
            Order[] memory orders = new Order[](1);
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
    )
        external
        view
        virtual
        override
        returns (TestOrderPayload memory execution)
    {
        (
            /* Order memory order */,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
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
            Order[] memory orders = new Order[](1);
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
    )
        external
        view
        virtual
        override
        returns (TestOrderPayload memory execution)
    {
        (
            /* Order memory order */,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
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
            Order[] memory orders = new Order[](1);
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
    )
        external
        view
        virtual
        override
        returns (TestOrderPayload memory execution)
    {
        (
            /* Order memory order */,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
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
            Order[] memory orders = new Order[](1);
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
    )
        external
        view
        virtual
        override
        returns (TestOrderPayload memory execution)
    {
        (
            /* Order memory order */,
            BasicOrderParameters memory basicComponents
        ) = buildBasicOrder(
                BasicOrderRouteType.ETH_TO_ERC721,
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
            Order[] memory orders = new Order[](1);
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
}
