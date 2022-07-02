// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IX2Y2Marketplace } from "./interfaces/IX2Y2Marketplace.sol";
import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { Market } from "./interfaces/MarketConstants.sol";
import { X2Y2TypeHashes } from "./lib/X2Y2TypeHashes.sol";
import { SetupCall, TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";

contract X2Y2Config is BaseMarketConfig, X2Y2TypeHashes {
    IX2Y2Marketplace internal constant X2Y2 =
        IX2Y2Marketplace(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    address internal constant X2Y2Owner =
        0x5D7CcA9Fb832BBD99C8bD720EbdA39B028648301;

    address internal constant erc721Delegate =
        0xF849de01B080aDC3A814FaBE1E2087475cF2E354;

    address internal X2Y2Signer;

    function name() external pure override returns (string memory) {
        return "X2Y2";
    }

    function market() public pure override returns (address) {
        return address(X2Y2);
    }

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = erc721Delegate;
        buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(X2Y2);
    }

    function beforeAllPrepareMarketplaceCall(
        address seller,
        address,
        address[] calldata,
        address[] calldata
    ) external override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](1);

        address[] memory removeSigners = new address[](0);
        address[] memory addSigners = new address[](1);
        addSigners[0] = seller;

        // Set seller as a signer for X2Y2
        setupCalls[0] = SetupCall(
            X2Y2Owner,
            address(X2Y2),
            abi.encodeWithSelector(
                IX2Y2Marketplace.updateSigners.selector,
                addSigners,
                removeSigners
            )
        );

        X2Y2Signer = seller;

        return setupCalls;
    }

    function encodeFillOrderDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] memory nfts,
        uint256[] memory prices,
        address currency,
        uint256 intent
    ) internal view returns (bytes memory payload, uint256 ethSum) {
        Market.RunInput memory input;

        input.shared.user = contexts[0].fulfiller;
        input.shared.deadline = block.timestamp + 1;

        Market.Order[] memory orders = new Market.Order[](nfts.length);
        Market.SettleDetail[] memory details = new Market.SettleDetail[](
            nfts.length
        );

        for (uint256 i = 0; i < nfts.length; i++) {
            {
                ethSum += prices[i];
            }
            {
                orders[i].user = contexts[i].offerer;
                orders[i].network = 1;
                orders[i].intent = intent;
                orders[i].delegateType = 1;
                orders[i].deadline = block.timestamp + 1;
                orders[i].currency = currency;

                Market.OrderItem[] memory items = new Market.OrderItem[](1);

                Market.Pair[] memory itemPairs = new Market.Pair[](1);
                itemPairs[0] = Market.Pair(nfts[i].token, nfts[i].identifier);

                items[0] = Market.OrderItem(prices[i], abi.encode(itemPairs));

                orders[i].items = items;

                (orders[i].v, orders[i].r, orders[i].s) = _sign(
                    contexts[i].offerer,
                    _deriveOrderDigest(orders[i])
                );
                orders[i].signVersion = Market.SIGN_V1;
            }
            {
                details[i].op = intent == Market.INTENT_SELL
                    ? Market.Op.COMPLETE_SELL_OFFER
                    : Market.Op.COMPLETE_BUY_OFFER;
                details[i].orderIdx = i;
                details[i].itemIdx = 0;
                details[i].price = prices[i];
                details[i].itemHash = _hashItem(orders[i], orders[i].items[0]);
                details[i].executionDelegate = erc721Delegate;
            }
        }

        input.orders = orders;
        input.details = details;

        (input.v, input.r, input.s) = _sign(
            X2Y2Signer,
            _deriveInputDigest(input)
        );

        payload = abi.encodeWithSelector(IX2Y2Marketplace.run.selector, input);
    }

    function encodeFillOrder(
        address offerer,
        address fulfiller,
        TestItem721[] memory nfts,
        uint256 price,
        address currency,
        uint256 intent,
        Market.Fee[] memory fees
    ) internal view returns (bytes memory) {
        Market.RunInput memory input;

        input.shared.user = fulfiller;
        input.shared.deadline = block.timestamp + 1;

        Market.Order[] memory orders = new Market.Order[](1);
        orders[0].user = offerer;
        orders[0].network = 1;
        orders[0].intent = intent;
        orders[0].delegateType = 1;
        orders[0].deadline = block.timestamp + 1;
        orders[0].currency = currency;

        Market.OrderItem[] memory items = new Market.OrderItem[](1);

        Market.Pair[] memory itemPairs = new Market.Pair[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            itemPairs[i] = Market.Pair(nfts[i].token, nfts[i].identifier);
        }

        items[0] = Market.OrderItem(price, abi.encode(itemPairs));

        orders[0].items = items;

        (orders[0].v, orders[0].r, orders[0].s) = _sign(
            offerer,
            _deriveOrderDigest(orders[0])
        );
        orders[0].signVersion = Market.SIGN_V1;

        input.orders = orders;

        Market.SettleDetail[] memory details = new Market.SettleDetail[](1);
        details[0].op = intent == Market.INTENT_SELL
            ? Market.Op.COMPLETE_SELL_OFFER
            : Market.Op.COMPLETE_BUY_OFFER;
        details[0].orderIdx = 0;
        details[0].itemIdx = 0;
        details[0].price = price;
        details[0].fees = fees;
        details[0].itemHash = _hashItem(orders[0], orders[0].items[0]);
        details[0].executionDelegate = erc721Delegate;
        input.details = details;

        (input.v, input.r, input.s) = _sign(
            X2Y2Signer,
            _deriveInputDigest(input)
        );

        return abi.encodeWithSelector(IX2Y2Marketplace.run.selector, input);
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            ethAmount,
            address(0),
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            ethAmount,
            payload
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

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            erc20.amount,
            erc20.token,
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(address(X2Y2), 0, payload);
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            erc20.amount,
            erc20.token,
            Market.INTENT_BUY,
            fees
        );

        execution.executeOrder = TestCallParameters(address(X2Y2), 0, payload);
    }

    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient,
        uint256 feeEthAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](1);
        fees[0] = Market.Fee(
            (feeEthAmount * 1000000) / (priceEthAmount + feeEthAmount) + 1,
            feeRecipient
        );

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            priceEthAmount + feeEthAmount,
            address(0),
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            priceEthAmount + feeEthAmount,
            payload
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
        if (context.listOnChain) {
            _notImplemented();
        }

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](2);
        fees[0] = Market.Fee(
            (feeEthAmount1 * 1000000) /
                (priceEthAmount + feeEthAmount1 + feeEthAmount2) +
                1,
            feeRecipient1
        );
        fees[1] = Market.Fee(
            (feeEthAmount2 * 1000000) /
                (priceEthAmount + feeEthAmount1 + feeEthAmount2) +
                1,
            feeRecipient2
        );

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            priceEthAmount + feeEthAmount1 + feeEthAmount2,
            address(0),
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            priceEthAmount + feeEthAmount1 + feeEthAmount2,
            payload
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

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            ethAmount,
            address(0),
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            ethAmount,
            payload
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

        (bytes memory payload, uint256 ethSum) = encodeFillOrderDistinctOrders(
            contexts,
            nfts,
            ethAmounts,
            address(0),
            Market.INTENT_SELL
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            ethSum,
            payload
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

        (bytes memory payload, ) = encodeFillOrderDistinctOrders(
            contexts,
            nfts,
            erc20Amounts,
            erc20Address,
            Market.INTENT_SELL
        );

        execution.executeOrder = TestCallParameters(address(X2Y2), 0, payload);
    }
}
