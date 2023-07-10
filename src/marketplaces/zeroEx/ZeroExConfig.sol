// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/tokens/ERC20.sol";
import "forge-std/Test.sol";

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { SetupCall, TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";
import { IZeroEx } from "./interfaces/IZeroEx.sol";
import "./lib/LibNFTOrder.sol";
import "./lib/LibSignature.sol";

contract ZeroExConfig is BaseMarketConfig, Test {
    IZeroEx constant zeroEx =
        IZeroEx(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);
    address constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // Note: in order to take advantage of a gas optimization, first create a "used" nonce
    uint256 usedNonce = uint256(0x1010101000000000);
    uint256 testNonce = uint256(0x1010101000000001);

    function name() external pure override returns (string memory) {
        return "ZeroEx";
    }

    function market() public pure override returns (address) {
        return address(zeroEx);
    }

    function beforeAllPrepareMarketplace(address seller, address)
        external
        override
    {
        buyerNftApprovalTarget = sellerNftApprovalTarget = buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            zeroEx
        );

        // Consume the usedNonce, allows for testNonce to become gas optimized
        vm.prank(seller);
        zeroEx.cancelERC721Order(usedNonce);
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: NATIVE_TOKEN_ADDRESS, // 0x orders are able to be "bought" with the native token using this sentinel value
            erc20TokenAmount: ethAmount,
            fees: new LibNFTOrder.Fee[](0),
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            ethAmount,
            abi.encodeWithSelector(IZeroEx.buyERC721.selector, order, sig, "")
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC1155Order memory order = LibNFTOrder.ERC1155Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: NATIVE_TOKEN_ADDRESS, // 0x orders are able to be "bought" with the native token using this sentinel value
            erc20TokenAmount: ethAmount,
            fees: new LibNFTOrder.Fee[](0),
            erc1155Token: nft.token,
            erc1155TokenId: nft.identifier,
            erc1155TokenAmount: uint128(nft.amount),
            erc1155TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC1155OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC1155Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            ethAmount,
            abi.encodeWithSelector(
                IZeroEx.buyERC1155.selector,
                order,
                sig,
                uint128(nft.amount),
                ""
            )
        );
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: erc20.token,
            erc20TokenAmount: erc20.amount,
            fees: new LibNFTOrder.Fee[](0),
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(IZeroEx.buyERC721.selector, order, sig, "")
        );
    }

    function getPayload_BuyOfferedERC721WithWETH(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: erc20.token,
            erc20TokenAmount: erc20.amount,
            fees: new LibNFTOrder.Fee[](0),
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(IZeroEx.buyERC721.selector, order, sig, "")
        );
    }

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC1155Order memory order = LibNFTOrder.ERC1155Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: erc20.token,
            erc20TokenAmount: erc20.amount,
            fees: new LibNFTOrder.Fee[](0),
            erc1155Token: nft.token,
            erc1155TokenId: nft.identifier,
            erc1155TokenAmount: uint128(nft.amount),
            erc1155TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC1155OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC1155Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(
                IZeroEx.buyERC1155.selector,
                order,
                sig,
                uint128(nft.amount),
                ""
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.BUY_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: erc20.token,
            erc20TokenAmount: erc20.amount,
            fees: new LibNFTOrder.Fee[](0),
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the sell
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(
                IZeroEx.sellERC721.selector,
                order,
                sig,
                nft.identifier,
                false, // unwrap native token
                "" // callback data
            )
        );
    }

    function getPayload_BuyOfferedWETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.BUY_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: erc20.token,
            erc20TokenAmount: erc20.amount,
            fees: new LibNFTOrder.Fee[](0),
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the sell
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(
                IZeroEx.sellERC721.selector,
                order,
                sig,
                nft.identifier,
                false, // unwrap native token
                "" // callback data
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem1155 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare the order
        LibNFTOrder.ERC1155Order memory order = LibNFTOrder.ERC1155Order({
            direction: LibNFTOrder.TradeDirection.BUY_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: erc20.token,
            erc20TokenAmount: erc20.amount,
            fees: new LibNFTOrder.Fee[](0),
            erc1155Token: nft.token,
            erc1155TokenId: nft.identifier,
            erc1155TokenAmount: uint128(nft.amount),
            erc1155TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC1155OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC1155Order.selector,
                    order
                )
            );
        }

        // Execute the sell
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(
                IZeroEx.sellERC1155.selector,
                order,
                sig,
                nft.identifier,
                uint128(nft.amount),
                false, // unwrap native token
                "" // callback data
            )
        );
    }

    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient,
        uint256 feeEthAmount
    ) external view override returns (TestOrderPayload memory execution) {
        // Prepare fees
        LibNFTOrder.Fee[] memory fees = new LibNFTOrder.Fee[](1);
        fees[0] = LibNFTOrder.Fee({
            recipient: feeRecipient,
            amount: feeEthAmount,
            feeData: ""
        });

        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: NATIVE_TOKEN_ADDRESS, // 0x orders are able to be "bought" with the native token using this sentinel value
            erc20TokenAmount: priceEthAmount,
            fees: fees,
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            priceEthAmount + feeEthAmount, // pay the maker and pay the fee
            abi.encodeWithSelector(IZeroEx.buyERC721.selector, order, sig, "")
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
        // Prepare fees
        LibNFTOrder.Fee[] memory fees = new LibNFTOrder.Fee[](2);
        fees[0] = LibNFTOrder.Fee({
            recipient: feeRecipient1,
            amount: feeEthAmount1,
            feeData: ""
        });
        fees[1] = LibNFTOrder.Fee({
            recipient: feeRecipient2,
            amount: feeEthAmount2,
            feeData: ""
        });

        // Prepare the order
        LibNFTOrder.ERC721Order memory order = LibNFTOrder.ERC721Order({
            direction: LibNFTOrder.TradeDirection.SELL_NFT,
            maker: context.offerer,
            taker: context.fulfiller,
            expiry: block.timestamp + 120,
            nonce: testNonce,
            erc20Token: NATIVE_TOKEN_ADDRESS, // 0x orders are able to be "bought" with the native token using this sentinel value
            erc20TokenAmount: priceEthAmount,
            fees: fees,
            erc721Token: nft.token,
            erc721TokenId: nft.identifier,
            erc721TokenProperties: new LibNFTOrder.Property[](0)
        });

        // Sign the order
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            order.maker,
            zeroEx.getERC721OrderHash(order)
        );

        // Prepare the signature
        LibSignature.Signature memory sig = LibSignature.Signature({
            signatureType: LibSignature.SignatureType.EIP712,
            v: v,
            r: r,
            s: s
        });

        // Handle special case if "listing on chain" or in the 0x parlance the order is "presigned"
        if (context.listOnChain) {
            sig = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.PRESIGNED,
                v: 0,
                r: 0,
                s: 0
            });

            execution.submitOrder = TestCallParameters(
                address(zeroEx),
                0,
                abi.encodeWithSelector(
                    IZeroEx.preSignERC721Order.selector,
                    order
                )
            );
        }

        // Execute the buy
        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            priceEthAmount + feeEthAmount1 + feeEthAmount2, // pay the maker and pay the fees
            abi.encodeWithSelector(IZeroEx.buyERC721.selector, order, sig, "")
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        require(
            contexts.length == nfts.length && nfts.length == ethAmounts.length,
            "ZeroExConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders/ARRAY_LENGTH_MISMATCH"
        );

        LibNFTOrder.ERC721Order[] memory orders = new LibNFTOrder.ERC721Order[](
            contexts.length
        );
        LibSignature.Signature[] memory sigs = new LibSignature.Signature[](
            contexts.length
        );
        bytes[] memory callbacks = new bytes[](contexts.length);
        uint256 sumEth = 0;

        for (uint256 i = 0; i < contexts.length; i++) {
            // Tally up the eth
            sumEth += ethAmounts[i];

            // Prepare the order
            orders[i] = LibNFTOrder.ERC721Order({
                direction: LibNFTOrder.TradeDirection.SELL_NFT,
                maker: contexts[i].offerer,
                taker: contexts[i].fulfiller,
                expiry: block.timestamp + 120,
                nonce: testNonce + i,
                erc20Token: NATIVE_TOKEN_ADDRESS, // 0x orders are able to be "bought" with the native token using this sentinel value
                erc20TokenAmount: ethAmounts[i],
                fees: new LibNFTOrder.Fee[](0),
                erc721Token: nfts[i].token,
                erc721TokenId: nfts[i].identifier,
                erc721TokenProperties: new LibNFTOrder.Property[](0)
            });

            // Sign the order
            (uint8 v, bytes32 r, bytes32 s) = _sign(
                orders[i].maker,
                zeroEx.getERC721OrderHash(orders[i])
            );

            // Prepare the signature
            sigs[i] = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.EIP712,
                v: v,
                r: r,
                s: s
            });
        }

        // Not sure how best to do this, not implementing for now
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            sumEth,
            abi.encodeWithSelector(
                IZeroEx.batchBuyERC721s.selector,
                orders,
                sigs,
                callbacks,
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
        require(
            contexts.length == nfts.length &&
                nfts.length == erc20Amounts.length,
            "ZeroExConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders/ARRAY_LENGTH_MISMATCH"
        );
        LibNFTOrder.ERC721Order[] memory orders = new LibNFTOrder.ERC721Order[](
            contexts.length
        );
        LibSignature.Signature[] memory sigs = new LibSignature.Signature[](
            contexts.length
        );
        bytes[] memory callbacks = new bytes[](contexts.length);

        for (uint256 i = 0; i < contexts.length; i++) {
            // Prepare the order
            orders[i] = LibNFTOrder.ERC721Order({
                direction: LibNFTOrder.TradeDirection.SELL_NFT,
                maker: contexts[i].offerer,
                taker: contexts[i].fulfiller,
                expiry: block.timestamp + 120,
                nonce: testNonce + i,
                erc20Token: erc20Address,
                erc20TokenAmount: erc20Amounts[i],
                fees: new LibNFTOrder.Fee[](0),
                erc721Token: nfts[i].token,
                erc721TokenId: nfts[i].identifier,
                erc721TokenProperties: new LibNFTOrder.Property[](0)
            });

            // Sign the order
            (uint8 v, bytes32 r, bytes32 s) = _sign(
                orders[i].maker,
                zeroEx.getERC721OrderHash(orders[i])
            );

            // Prepare the signature
            sigs[i] = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.EIP712,
                v: v,
                r: r,
                s: s
            });
        }

        // Not sure how best to do this, not implementing for now
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(
                IZeroEx.batchBuyERC721s.selector,
                orders,
                sigs,
                callbacks,
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
        require(
            contexts.length == nfts.length &&
                nfts.length == erc20Amounts.length,
            "ZeroExConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders/ARRAY_LENGTH_MISMATCH"
        );
        LibNFTOrder.ERC721Order[] memory orders = new LibNFTOrder.ERC721Order[](
            contexts.length
        );
        LibSignature.Signature[] memory sigs = new LibSignature.Signature[](
            contexts.length
        );
        bytes[] memory callbacks = new bytes[](contexts.length);

        for (uint256 i = 0; i < contexts.length; i++) {
            // Prepare the order
            orders[i] = LibNFTOrder.ERC721Order({
                direction: LibNFTOrder.TradeDirection.SELL_NFT,
                maker: contexts[i].offerer,
                taker: contexts[i].fulfiller,
                expiry: block.timestamp + 120,
                nonce: testNonce + i,
                erc20Token: erc20Address,
                erc20TokenAmount: erc20Amounts[i],
                fees: new LibNFTOrder.Fee[](0),
                erc721Token: nfts[i].token,
                erc721TokenId: nfts[i].identifier,
                erc721TokenProperties: new LibNFTOrder.Property[](0)
            });

            // Sign the order
            (uint8 v, bytes32 r, bytes32 s) = _sign(
                orders[i].maker,
                zeroEx.getERC721OrderHash(orders[i])
            );

            // Prepare the signature
            sigs[i] = LibSignature.Signature({
                signatureType: LibSignature.SignatureType.EIP712,
                v: v,
                r: r,
                s: s
            });
        }

        // Not sure how best to do this, not implementing for now
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(zeroEx),
            0,
            abi.encodeWithSelector(
                IZeroEx.batchBuyERC721s.selector,
                orders,
                sigs,
                callbacks,
                false
            )
        );
    }
}
