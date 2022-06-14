// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import {BaseMarketConfig} from "../../BaseMarketConfig.sol";
import {TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20} from "../../Types.sol";
import {WyvernInterface as IWyvern} from "./interfaces/WyvernInterface.sol";
import {IWyvernProxyRegistry} from "./interfaces/IWyvernProxyRegistry.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import "./lib/WyvernStructs.sol";
import "./lib/WyvernEnums.sol";
import "./lib/WyvernTypeHashes.sol";

contract WyvernConfig is BaseMarketConfig, WyvernTypeHashes {
    function name() external view virtual override returns (string memory) {
        return "Wyvern";
    }

    bytes internal constant EMPTY_BYTES = bytes("");

    address internal constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000;

    address internal constant feeRecipient =
        0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    IWyvern internal constant wyvern = 
        IWyvern(0x7f268357A8c2552623316e2562D90e642bB538E5);

    IWyvernProxyRegistry internal constant proxyRegistry = 
        IWyvernProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

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

    function encodeERC721AtomicMatch(
        Order memory order,
        Sig memory signature,
        TestItem721 memory nft
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    order.exchange,
                    order.taker,
                    order.maker,
                    NULL_ADDRESS,
                    order.target,
                    NULL_ADDRESS,
                    order.paymentToken,


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
                    order.salt,


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
                [
                    uint8(1),
                    uint8(0),
                    uint8(0),
                    uint8(0),


                    uint8(order.feeMethod),
                    uint8(order.side),
                    uint8(order.saleKind),
                    uint8(order.howToCall)
                ],
                encodeERC721TransferFrom(
                    NULL_ADDRESS,
                    order.taker,
                    nft.identifier
                ),
                order._calldata,
                encodeERC721ReplacementPatternBuy(),
                order.replacementPattern,
                EMPTY_BYTES,
                EMPTY_BYTES,
                [uint8(signature.v), uint8(signature.v)],
                [
                    signature.r,
                    signature.s,
                    signature.r,
                    signature.s,
                    0x0000000000000000000000000000000000000000000000000000000000000000
                ]
            );
    }

    function encodeERC721ApproveOrder(
        Order memory order
    ) internal pure returns (bytes memory) {
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

    function buildERC721SellOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem721 memory nft
    ) internal view returns (Order memory order, Sig memory signature) {
        order.exchange = address(wyvern);
        order.maker = maker;
        order.taker = taker;
        order.makerRelayerFee = 950;
        order.feeRecipient = feeRecipient;
        order.feeMethod = FeeMethod.SplitFee;
        order.side = Side.Sell;
        order.saleKind = SaleKind.FixedPrice;
        order.target = nft.token;
        order.howToCall = HowToCall.Call;
        order._calldata = encodeERC721TransferFrom(
            maker,
            NULL_ADDRESS,
            nft.identifier
        );
        order.replacementPattern = encodeERC721ReplacementPatternSell();
        order.paymentToken = paymentToken;
        order.basePrice = price;
        bytes32 digest = _deriveEIP712Digest(hashOrder(order, 0));
        (signature.v, signature.r, signature.s) = _sign(maker, digest);
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
        bytes memory rawBytes =  abi.encodeWithSelector(
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
        bytes memory rawBytes =  abi.encodeWithSelector(
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

    function encodeERC1155AtomicMatch(
        Order memory order,
        Sig memory signature,
        TestItem1155 memory nft
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    order.exchange,
                    order.taker,
                    order.maker,
                    NULL_ADDRESS,
                    order.target,
                    NULL_ADDRESS,
                    order.paymentToken,


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
                    order.salt,


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
                [
                    uint8(1),
                    uint8(0),
                    uint8(0),
                    uint8(0),


                    uint8(order.feeMethod),
                    uint8(order.side),
                    uint8(order.saleKind),
                    uint8(order.howToCall)
                ],
                encodeERC1155SafeTransferFrom(NULL_ADDRESS, order.taker, nft.identifier, nft.amount),
                order._calldata,
                encodeERC1155ReplacementPatternBuy(),
                order.replacementPattern,
                EMPTY_BYTES,
                EMPTY_BYTES,
                [uint8(signature.v), uint8(signature.v)],
                [
                    signature.r,
                    signature.s,
                    signature.r,
                    signature.s,
                    0x0000000000000000000000000000000000000000000000000000000000000000
                ]
            );
    }

    function encodeERC1155ApproveOrder(
        Order memory order
    ) internal pure returns (bytes memory) {
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

    function buildERC1155SellOrder(
        address maker,
        address taker,
        address paymentToken,
        uint256 price,
        TestItem1155 memory nft
    ) internal view returns (Order memory order, Sig memory signature) {
        order.exchange = address(wyvern);
        order.maker = maker;
        order.taker = taker;
        order.makerRelayerFee = 950;
        order.feeRecipient = feeRecipient;
        order.feeMethod = FeeMethod.SplitFee;
        order.side = Side.Sell;
        order.saleKind = SaleKind.FixedPrice;
        order.target = nft.token;
        order.howToCall = HowToCall.Call;
        order._calldata = encodeERC1155SafeTransferFrom(maker, NULL_ADDRESS, nft.identifier, nft.amount);
        order.replacementPattern = encodeERC1155ReplacementPatternSell();
        order.paymentToken = paymentToken;
        order.basePrice = price;
        bytes32 digest = _deriveEIP712Digest(hashOrder(order, 0));
        (signature.v, signature.r, signature.s) = _sign(maker, digest);
    }

    function beforeAllPrepareMarketplaceCall(address seller, address) external pure override returns (address, address, bytes memory) {
        return (
            address(seller),
            address(proxyRegistry), 
            abi.encodeWithSelector(
                proxyRegistry.registerProxy.selector
            )
        );
    }

    function beforeAllPrepareMarketplace(address seller, address) external override {
        // Create Wyvern Proxy
        erc20ApprovalTarget = 0xE5c783EE536cf5E63E792988335c4255169be4E1;
        nftApprovalTarget = proxyRegistry.proxies(seller);
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
        (Order memory order, Sig memory signature) = buildERC721SellOrder(
            context.offerer,
            context.fulfiller,
            0x0000000000000000000000000000000000000000,
            ethAmount,
            nft
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeERC721ApproveOrder(order)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            ethAmount,
            encodeERC721AtomicMatch(order, signature, nft)
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
        (Order memory order, Sig memory signature) = buildERC1155SellOrder(
            context.offerer,
            context.fulfiller,
            0x0000000000000000000000000000000000000000,
            ethAmount,
            nft
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeERC1155ApproveOrder(order)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            ethAmount,
            encodeERC1155AtomicMatch(order, signature, nft)
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
        (Order memory order, Sig memory signature) = buildERC721SellOrder(
            context.offerer,
            context.fulfiller,
            erc20.token,
            erc20.amount,
            nft
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeERC721ApproveOrder(order)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeERC721AtomicMatch(order, signature, nft)
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
        (Order memory order, Sig memory signature) = buildERC1155SellOrder(
            context.offerer,
            context.fulfiller,
            erc20.token,
            erc20.amount,
            nft
        );
        if (context.listOnChain) {
            execution.submitOrder = TestCallParameters(
                address(wyvern),
                0,
                encodeERC1155ApproveOrder(order)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvern),
            0,
            encodeERC1155AtomicMatch(order, signature, nft)
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
    {}

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
    {}
}
