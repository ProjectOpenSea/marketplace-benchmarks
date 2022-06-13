// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import {BaseMarketConfig} from "../../BaseMarketConfig.sol";
import {TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20} from "../../Types.sol";
import {WyvernInterface as IWyvern} from "./interfaces/WyvernInterface.sol";
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

    address internal constant wyvernExchange =
        0x7f268357A8c2552623316e2562D90e642bB538E5;

    address internal constant feeRecipient =
        0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    address internal constant target =
        0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7;

    IWyvern internal constant wyvern = IWyvern(wyvernExchange);

    function approvalTarget() external view virtual override returns (address) {
        return address(0x37A7996aff29966c328494d07638C7d4A710f92D);
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

    function encodeERC721AtomicMatch(
        Order memory order,
        Sig memory signature,
        TestItem721 memory nft
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    wyvernExchange,
                    order.taker,
                    order.maker,
                    NULL_ADDRESS,
                    nft.token,
                    NULL_ADDRESS,
                    NULL_ADDRESS,
                    wyvernExchange,
                    order.maker,
                    NULL_ADDRESS,
                    feeRecipient,
                    nft.token,
                    NULL_ADDRESS,
                    NULL_ADDRESS
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
                    uint8(1),
                    uint8(1),
                    uint8(0),
                    uint8(0)
                ],
                encodeERC721TransferFrom(
                    NULL_ADDRESS,
                    order.taker,
                    nft.identifier
                ),
                encodeERC721TransferFrom(
                    order.maker,
                    NULL_ADDRESS,
                    nft.identifier
                ),
                encodeERC721ReplacementPatternBuy(),
                encodeERC721ReplacementPatternSell(),
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
        Order memory order,
        TestItem721 memory nft
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    wyvernExchange,
                    order.maker,
                    order.taker,
                    feeRecipient,
                    nft.token,
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
                [uint8(1), uint8(1), uint8(0), uint8(0)],
                encodeERC721TransferFrom(
                    order.maker,
                    NULL_ADDRESS,
                    nft.identifier
                ),
                encodeERC721ReplacementPatternSell(),
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
        order.exchange = wyvernExchange;
        order.maker = maker;
        order.taker = taker;
        order.makerRelayerFee = 950;
        order.feeRecipient = feeRecipient;
        order.feeMethod = FeeMethod.SplitFee;
        order.side = Side.Sell;
        order.saleKind = SaleKind.FixedPrice;
        order.target = target;
        order.howToCall = HowToCall.DelegateCall;
        order._calldata = encodeERC721TransferFrom(
            maker,
            taker,
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
        return
            abi.encodeWithSelector(
                bytes4(0x00000000),
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
            );
    }

    function encodeERC1155ReplacementPatternBuy()
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                bytes4(0x00000000),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
            );
    }

    function encodeERC1155AtomicMatch(
        Order memory order,
        Sig memory signature,
        TestItem1155 memory nft
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    wyvernExchange,
                    order.taker,
                    order.maker,
                    NULL_ADDRESS,
                    nft.token,
                    NULL_ADDRESS,
                    NULL_ADDRESS,
                    wyvernExchange,
                    order.maker,
                    NULL_ADDRESS,
                    feeRecipient,
                    nft.token,
                    NULL_ADDRESS,
                    NULL_ADDRESS
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
                    uint8(1),
                    uint8(1),
                    uint8(0),
                    uint8(0)
                ],
                encodeERC1155SafeTransferFrom(
                    NULL_ADDRESS,
                    order.taker,
                    nft.identifier,
                    1
                ),
                encodeERC1155SafeTransferFrom(
                    order.maker,
                    NULL_ADDRESS,
                    nft.identifier,
                    1
                ),
                encodeERC1155ReplacementPatternBuy(),
                encodeERC1155ReplacementPatternSell(),
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
        Order memory order,
        TestItem1155 memory nft
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IWyvern.atomicMatch_.selector,
                [
                    wyvernExchange,
                    order.maker,
                    order.taker,
                    feeRecipient,
                    nft.token,
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
                [uint8(1), uint8(1), uint8(0), uint8(0)],
                encodeERC1155SafeTransferFrom(
                    order.maker,
                    NULL_ADDRESS,
                    nft.identifier,
                    nft.amount
                ),
                encodeERC1155ReplacementPatternSell(),
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
        order.exchange = wyvernExchange;
        order.maker = maker;
        order.taker = taker;
        order.makerRelayerFee = 950;
        order.feeRecipient = feeRecipient;
        order.feeMethod = FeeMethod.SplitFee;
        order.side = Side.Sell;
        order.saleKind = SaleKind.FixedPrice;
        order.target = target;
        order.howToCall = HowToCall.DelegateCall;
        order._calldata = encodeERC1155SafeTransferFrom(
            maker,
            taker,
            nft.identifier,
            nft.amount
        );
        order.replacementPattern = encodeERC1155ReplacementPatternSell();
        order.paymentToken = paymentToken;
        order.basePrice = price;
        bytes32 digest = _deriveEIP712Digest(hashOrder(order, 0));
        (signature.v, signature.r, signature.s) = _sign(maker, digest);
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
                encodeERC721ApproveOrder(order, nft)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvernExchange),
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
                encodeERC1155ApproveOrder(order, nft)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvernExchange),
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
                encodeERC721ApproveOrder(order, nft)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvernExchange),
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
                encodeERC1155ApproveOrder(order, nft)
            );
        }
        execution.executeOrder = TestCallParameters(
            address(wyvernExchange),
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
