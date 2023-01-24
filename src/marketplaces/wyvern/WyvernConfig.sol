// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { SetupCall, TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";
import { WyvernInterface as IWyvern } from "./interfaces/WyvernInterface.sol";
import { IWyvernProxyRegistry } from "./interfaces/IWyvernProxyRegistry.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IERC1155 } from "./interfaces/IERC1155.sol";
import { IAtomicizer } from "./interfaces/IAtomicizer.sol";
import "./lib/WyvernStructs.sol";
import "./lib/WyvernEnums.sol";
import "./lib/WyvernTypeHashes.sol";

contract WyvernConfig is BaseMarketConfig, WyvernTypeHashes {
    function name() external pure override returns (string memory) {
        return "Wyvern";
    }

    function market() public pure override returns (address) {
        return address(wyvern);
    }

    bytes internal constant EMPTY_BYTES = bytes("");

    address internal constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000;

    address internal constant DEFAULT_FEE_RECIPIENT =
        0x0000000000000000000000000000000000000001;

    address internal constant ATOMICIZER =
        0xC99f70bFD82fb7c8f8191fdfbFB735606b15e5c5;

    IWyvern internal constant wyvern =
        IWyvern(0x7f268357A8c2552623316e2562D90e642bB538E5);

    IWyvernProxyRegistry internal constant proxyRegistry =
        IWyvernProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

    Sig internal EMPTY_SIG = Sig(0, 0, 0);

    /*//////////////////////////////////////////////////////////////
                            Generic Helpers
    //////////////////////////////////////////////////////////////*/

    function encodeAtomicMatch(
        Order memory buyOrder,
        Order memory sellOrder,
        Sig memory buySignature,
        Sig memory sellSignature
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    buyOrder.exchange,
                    buyOrder.maker,
                    buyOrder.taker,
                    buyOrder.feeRecipient,
                    buyOrder.target,
                    NULL_ADDRESS,
                    buyOrder.paymentToken,
                    sellOrder.exchange,
                    sellOrder.maker,
                    sellOrder.taker,
                    sellOrder.feeRecipient,
                    sellOrder.target,
                    NULL_ADDRESS,
                    sellOrder.paymentToken
                ],
                [
                    buyOrder.makerRelayerFee,
                    0,
                    0,
                    0,
                    buyOrder.basePrice,
                    0,
                    buyOrder.listingTime,
                    buyOrder.expirationTime,
                    buyOrder.salt,
                    sellOrder.makerRelayerFee,
                    0,
                    0,
                    0,
                    sellOrder.basePrice,
                    0,
                    sellOrder.listingTime,
                    sellOrder.expirationTime,
                    sellOrder.salt
                ],
                [
                    uint8(buyOrder.feeMethod),
                    uint8(buyOrder.side),
                    uint8(buyOrder.saleKind),
                    uint8(buyOrder.howToCall),
                    uint8(sellOrder.feeMethod),
                    uint8(sellOrder.side),
                    uint8(sellOrder.saleKind),
                    uint8(sellOrder.howToCall)
                ],
                buyOrder._calldata,
                sellOrder._calldata,
                buyOrder.replacementPattern,
                sellOrder.replacementPattern,
                EMPTY_BYTES,
                EMPTY_BYTES,
                [buySignature.v, sellSignature.v],
                [
                    buySignature.r,
                    buySignature.s,
                    sellSignature.r,
                    sellSignature.s,
                    bytes32(0)
                ]
            );
    }

    function encodeApproveOrder(Order memory order)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                IWyvern.approveOrder_.selector,
                [
                    order.exchange,
                    order.maker,
                    order.taker,
                    order.feeRecipient,
                    order.target,
                    NULL_ADDRESS,
                    order.paymentToken
                ],
                [
                    order.makerRelayerFee,
                    0,
                    0,
                    0,
                    order.basePrice,
                    0,
                    order.listingTime,
                    order.expirationTime,
                    order.salt
                ],
                order.feeMethod,
                order.side,
                order.saleKind,
                order.howToCall,
                order._calldata,
                order.replacementPattern,
                EMPTY_BYTES,
                true
            );
    }

    function buildOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        address target,
        address feeRecipient,
        uint256 fee,
        Side side,
        HowToCall howToCall,
        bytes memory _calldata,
        bytes memory replacementPattern
    ) internal view returns (Order memory order, Sig memory signature) {
        order.exchange = address(wyvern);
        order.maker = maker;
        order.taker = taker;
        order.makerRelayerFee = fee;
        order.feeRecipient = feeRecipient;
        order.feeMethod = FeeMethod.SplitFee;
        order.side = side;
        order.saleKind = SaleKind.FixedPrice;
        order.target = target;
        order.howToCall = howToCall;
        order._calldata = _calldata;
        order.replacementPattern = replacementPattern;
        order.paymentToken = paymentToken;
        order.basePrice = price;
        bytes32 digest = _deriveEIP712Digest(hashOrder(order, 0));
        (signature.v, signature.r, signature.s) = _sign(maker, digest);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 Helpers
    //////////////////////////////////////////////////////////////*/

    function encodeERC721TransferFrom(
        address maker,
        address taker,
        uint256 identifier
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IERC721.transferFrom.selector,
                maker,
                taker,
                identifier
            );
    }

    function encodeERC721ReplacementPatternSell()
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                bytes4(0x00000000),
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                0x0000000000000000000000000000000000000000000000000000000000000000
            );
    }

    function encodeERC721ReplacementPatternBuy()
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                bytes4(0x00000000),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000
            );
    }

    function encodeERC721BatchTransferFrom(
        address maker,
        address taker,
        TestItem721[] memory nfts
    ) internal pure returns (bytes memory) {
        address[] memory targets = new address[](nfts.length);
        uint256[] memory values = new uint256[](nfts.length);
        bytes[] memory calldatas = new bytes[](nfts.length);
        uint256[] memory calldataLengths = new uint256[](nfts.length);
        uint256 calldataLengthSum = 0;

        for (uint256 i = 0; i < nfts.length; i++) {
            calldatas[i] = encodeERC721TransferFrom(
                maker,
                taker,
                nfts[i].identifier
            );
            calldataLengths[i] = calldatas[i].length;
            targets[i] = nfts[i].token;
            calldataLengthSum += calldataLengths[i];
        }

        bytes memory _calldata = new bytes(calldataLengthSum);
        uint256 offset = 0;
        for (uint256 i = 0; i < calldatas.length; i++) {
            for (uint256 j = 0; j < calldataLengths[i]; j++) {
                _calldata[offset] = calldatas[i][j];
                offset++;
            }
        }

        return
            abi.encodeWithSelector(
                IAtomicizer.atomicize.selector,
                targets,
                values,
                calldataLengths,
                _calldata
            );
    }

    function buildERC721SellOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem721 memory nft,
        address feeRecipient,
        uint256 fee
    ) internal view returns (Order memory order, Sig memory signature) {
        bytes memory _calldata = encodeERC721TransferFrom(
            maker,
            NULL_ADDRESS,
            nft.identifier
        );
        bytes memory replacementPattern = encodeERC721ReplacementPatternSell();

        return
            buildOrder(
                maker,
                taker,
                paymentToken,
                price,
                nft.token,
                feeRecipient,
                fee,
                Side.Sell,
                HowToCall.Call,
                _calldata,
                replacementPattern
            );
    }

    function buildERC721BuyOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem721 memory nft,
        address feeRecipient,
        uint256 fee
    ) internal view returns (Order memory order, Sig memory signature) {
        bytes memory _calldata = encodeERC721TransferFrom(
            NULL_ADDRESS,
            maker,
            nft.identifier
        );
        bytes memory replacementPattern = encodeERC721ReplacementPatternBuy();

        return
            buildOrder(
                maker,
                taker,
                paymentToken,
                price,
                nft.token,
                feeRecipient,
                fee,
                Side.Buy,
                HowToCall.Call,
                _calldata,
                replacementPattern
            );
    }

    function buildERC721BatchSellOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem721[] memory nfts,
        address feeRecipient
    ) internal view returns (Order memory order, Sig memory signature) {
        bytes memory _calldata = encodeERC721BatchTransferFrom(
            maker,
            taker,
            nfts
        );

        return
            buildOrder(
                maker,
                taker,
                paymentToken,
                price,
                ATOMICIZER,
                feeRecipient,
                0,
                Side.Sell,
                HowToCall.DelegateCall,
                _calldata,
                ""
            );
    }

    function buildERC721BatchBuyOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem721[] memory nfts,
        address feeRecipient
    ) internal view returns (Order memory order, Sig memory signature) {
        bytes memory _calldata = encodeERC721BatchTransferFrom(
            taker,
            maker,
            nfts
        );

        return
            buildOrder(
                maker,
                taker,
                paymentToken,
                price,
                ATOMICIZER,
                feeRecipient,
                0,
                Side.Buy,
                HowToCall.DelegateCall,
                _calldata,
                ""
            );
    }

    /*//////////////////////////////////////////////////////////////
                           ERC1155 Helpers
    //////////////////////////////////////////////////////////////*/

    function encodeERC1155SafeTransferFrom(
        address maker,
        address taker,
        uint256 identifier,
        uint256 amount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                maker,
                taker,
                identifier,
                amount,
                EMPTY_BYTES
            );
    }

    function encodeERC1155ReplacementPatternSell()
        internal
        pure
        returns (bytes memory)
    {
        bytes memory rawBytes = abi.encodeWithSelector(
            IERC1155.safeTransferFrom.selector,
            NULL_ADDRESS,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            0,
            0,
            EMPTY_BYTES
        );
        rawBytes[0] = 0;
        rawBytes[1] = 0;
        rawBytes[2] = 0;
        rawBytes[3] = 0;
        rawBytes[163] = 0;

        return rawBytes;
    }

    function encodeERC1155ReplacementPatternBuy()
        internal
        pure
        returns (bytes memory)
    {
        bytes memory rawBytes = abi.encodeWithSelector(
            IERC1155.safeTransferFrom.selector,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            NULL_ADDRESS,
            0,
            0,
            EMPTY_BYTES
        );
        rawBytes[0] = 0;
        rawBytes[1] = 0;
        rawBytes[2] = 0;
        rawBytes[3] = 0;
        rawBytes[163] = 0;

        return rawBytes;
    }

    function buildERC1155SellOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem1155 memory nft,
        address feeRecipient,
        uint256 fee
    ) internal view returns (Order memory order, Sig memory signature) {
        bytes memory _calldata = encodeERC1155SafeTransferFrom(
            maker,
            taker,
            nft.identifier,
            nft.amount
        );
        bytes memory replacementPattern = encodeERC1155ReplacementPatternSell();

        return
            buildOrder(
                maker,
                taker,
                paymentToken,
                price,
                nft.token,
                feeRecipient,
                fee,
                Side.Sell,
                HowToCall.Call,
                _calldata,
                replacementPattern
            );
    }

    function buildERC1155BuyOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem1155 memory nft,
        address feeRecipient,
        uint256 fee
    ) internal view returns (Order memory order, Sig memory signature) {
        bytes memory _calldata = encodeERC1155SafeTransferFrom(
            taker,
            maker,
            nft.identifier,
            nft.amount
        );
        bytes memory replacementPattern = encodeERC1155ReplacementPatternBuy();

        return
            buildOrder(
                maker,
                taker,
                paymentToken,
                price,
                nft.token,
                feeRecipient,
                fee,
                Side.Buy,
                HowToCall.Call,
                _calldata,
                replacementPattern
            );
    }

    /*//////////////////////////////////////////////////////////////
                            Setup
    //////////////////////////////////////////////////////////////*/

    function beforeAllPrepareMarketplaceCall(
        address seller,
        address buyer,
        address[] calldata,
        address[] calldata
    ) external pure override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](2);
        setupCalls[0] = SetupCall(
            seller,
            address(proxyRegistry),
            abi.encodeWithSelector(proxyRegistry.registerProxy.selector)
        );
        setupCalls[1] = SetupCall(
            buyer,
            address(proxyRegistry),
            abi.encodeWithSelector(proxyRegistry.registerProxy.selector)
        );
        return setupCalls;
    }

    function beforeAllPrepareMarketplace(address seller, address buyer)
        external
        override
    {
        // Create Wyvern Proxy
        buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = 0xE5c783EE536cf5E63E792988335c4255169be4E1;
        buyerNftApprovalTarget = proxyRegistry.proxies(buyer);
        sellerNftApprovalTarget = proxyRegistry.proxies(seller);
    }

    /*//////////////////////////////////////////////////////////////
                        Test Payload Calls
    //////////////////////////////////////////////////////////////*/

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory sellOrder,
            Sig memory sellSignature
        ) = buildERC721SellOrder(
                context.offerer,
                NULL_ADDRESS,
                0x0000000000000000000000000000000000000000,
                ethAmount,
                nft,
                DEFAULT_FEE_RECIPIENT,
                0
            );
        (Order memory buyOrder, ) = buildERC721BuyOrder(
            context.fulfiller,
            NULL_ADDRESS,
            0x0000000000000000000000000000000000000000,
            ethAmount,
            nft,
            NULL_ADDRESS,
            0
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
            sellSignature.v = 0;
            sellSignature.r = 0;
            sellSignature.s = 0;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            ethAmount,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory sellOrder,
            Sig memory sellSignature
        ) = buildERC1155SellOrder(
                context.offerer,
                NULL_ADDRESS,
                0x0000000000000000000000000000000000000000,
                ethAmount,
                nft,
                DEFAULT_FEE_RECIPIENT,
                0
            );
        (Order memory buyOrder, ) = buildERC1155BuyOrder(
            context.fulfiller,
            NULL_ADDRESS,
            0x0000000000000000000000000000000000000000,
            ethAmount,
            nft,
            NULL_ADDRESS,
            0
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            ethAmount,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory sellOrder,
            Sig memory sellSignature
        ) = buildERC721SellOrder(
                context.offerer,
                NULL_ADDRESS,
                erc20.token,
                erc20.amount,
                nft,
                DEFAULT_FEE_RECIPIENT,
                0
            );
        (Order memory buyOrder, ) = buildERC721BuyOrder(
            context.fulfiller,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            NULL_ADDRESS,
            0
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
            sellSignature = EMPTY_SIG;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }

    function getPayload_BuyOfferedERC721WithWETH(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory sellOrder,
            Sig memory sellSignature
        ) = buildERC721SellOrder(
                context.offerer,
                NULL_ADDRESS,
                erc20.token,
                erc20.amount,
                nft,
                DEFAULT_FEE_RECIPIENT,
                0
            );
        (Order memory buyOrder, ) = buildERC721BuyOrder(
            context.fulfiller,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            NULL_ADDRESS,
            0
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
            sellSignature = EMPTY_SIG;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory sellOrder,
            Sig memory sellSignature
        ) = buildERC1155SellOrder(
                context.offerer,
                NULL_ADDRESS,
                erc20.token,
                erc20.amount,
                nft,
                DEFAULT_FEE_RECIPIENT,
                0
            );
        (Order memory buyOrder, ) = buildERC1155BuyOrder(
            context.fulfiller,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            NULL_ADDRESS,
            0
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
            sellSignature = EMPTY_SIG;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        (Order memory buyOrder, Sig memory buySignature) = buildERC721BuyOrder(
            context.offerer,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            DEFAULT_FEE_RECIPIENT,
            0
        );
        (Order memory sellOrder, ) = buildERC721SellOrder(
            context.fulfiller,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            NULL_ADDRESS,
            0
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(buyOrder)
            );
            buySignature = EMPTY_SIG;
        }

        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeAtomicMatch(buyOrder, sellOrder, buySignature, EMPTY_SIG)
        );
    }

    function getPayload_BuyOfferedWETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        (Order memory buyOrder, Sig memory buySignature) = buildERC721BuyOrder(
            context.offerer,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            DEFAULT_FEE_RECIPIENT,
            0
        );
        (Order memory sellOrder, ) = buildERC721SellOrder(
            context.fulfiller,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            NULL_ADDRESS,
            0
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(buyOrder)
            );
            buySignature = EMPTY_SIG;
        }

        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeAtomicMatch(buyOrder, sellOrder, buySignature, EMPTY_SIG)
        );
    }

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem1155 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        (Order memory buyOrder, Sig memory buySignature) = buildERC1155BuyOrder(
            context.offerer,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            DEFAULT_FEE_RECIPIENT,
            0
        );
        (Order memory sellOrder, ) = buildERC1155SellOrder(
            context.fulfiller,
            NULL_ADDRESS,
            erc20.token,
            erc20.amount,
            nft,
            NULL_ADDRESS,
            0
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(buyOrder)
            );
            buySignature = EMPTY_SIG;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeAtomicMatch(buyOrder, sellOrder, buySignature, EMPTY_SIG)
        );
    }

    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient,
        uint256 feeEthAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (Order memory sellOrder, Sig memory sellSignature) = buildERC721SellOrder(
            context.offerer,
            NULL_ADDRESS,
            0x0000000000000000000000000000000000000000,
            priceEthAmount + feeEthAmount,
            nft,
            feeRecipient,
            (feeEthAmount * 10000) / (priceEthAmount + feeEthAmount) + 1 // Calculate fee percentage
        );
        (Order memory buyOrder, ) = buildERC721BuyOrder(
            context.fulfiller,
            NULL_ADDRESS,
            0x0000000000000000000000000000000000000000,
            priceEthAmount + feeEthAmount,
            nft,
            NULL_ADDRESS,
            (feeEthAmount * 10000) / (priceEthAmount + feeEthAmount) + 1 // Calculate fee percentage
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
            sellSignature = EMPTY_SIG;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            priceEthAmount + feeEthAmount,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        (
            Order memory sellOrder,
            Sig memory sellSignature
        ) = buildERC721BatchSellOrder(
                context.offerer,
                context.fulfiller,
                0x0000000000000000000000000000000000000000,
                ethAmount,
                nfts,
                DEFAULT_FEE_RECIPIENT
            );
        (Order memory buyOrder, ) = buildERC721BatchBuyOrder(
            context.fulfiller,
            context.offerer,
            0x0000000000000000000000000000000000000000,
            ethAmount,
            nfts,
            NULL_ADDRESS
        );

        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeApproveOrder(sellOrder)
            );
            sellSignature = EMPTY_SIG;
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            ethAmount,
            encodeAtomicMatch(buyOrder, sellOrder, EMPTY_SIG, sellSignature)
        );
    }
}
