// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LooksRareTypeHashes } from "./lib/LooksRareTypeHashes.sol";
import { OrderTypes } from "./lib/OrderTypes.sol";
import { ILooksRareExchange } from "./interfaces/ILooksRareExchange.sol";
import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";
import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20, SetupCall } from "../../Types.sol";

contract LooksRareConfig is BaseMarketConfig, LooksRareTypeHashes {
    function name() external pure override returns (string memory) {
        return "LooksRare";
    }

    function market() public pure override returns (address) {
        return address(looksRare);
    }

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILooksRareExchange internal constant looksRare =
        ILooksRareExchange(0x59728544B08AB483533076417FbBB2fD0B17CE3a);
    address internal constant looksRareOwner =
        0xBfb6669Ef4C4c71ae6E722526B1B8d7d9ff9a019;

    address internal constant fixedPriceStrategy =
        0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;

    ICurrencyManager internal constant currencyManager =
        ICurrencyManager(0xC881ADdf409eE2C4b6bBc8B607c2C5CAFaB93d25);
    address internal constant currencyManagerOwner =
        0xB624e4148ef395458D361547C9Fdb59B62a84bd2;

    /*//////////////////////////////////////////////////////////////
                            Generic Helpers
    //////////////////////////////////////////////////////////////*/

    function buildMakerOrder(
        bool isOrderAsk,
        address maker,
        address fungibleToken,
        uint256 fungibleAmount,
        address nftToken,
        uint256 nftAmount,
        uint256 nftTokenId
    ) internal view returns (OrderTypes.MakerOrder memory makerOrder) {
        makerOrder = OrderTypes.MakerOrder(
            isOrderAsk,
            maker,
            nftToken,
            fungibleAmount,
            nftTokenId,
            nftAmount,
            fixedPriceStrategy,
            fungibleToken,
            0,
            block.timestamp,
            block.timestamp + 1,
            0,
            "",
            0,
            0,
            0
        );
        (uint8 v, bytes32 r, bytes32 s) = _sign(
            maker,
            _deriveOrderDigest(makerOrder)
        );
        makerOrder.v = v;
        makerOrder.r = r;
        makerOrder.s = s;
    }

    function buildTakerOrder(
        address taker,
        OrderTypes.MakerOrder memory makerOrder
    ) internal pure returns (OrderTypes.TakerOrder memory) {
        return
            OrderTypes.TakerOrder(
                !makerOrder.isOrderAsk,
                taker,
                makerOrder.price,
                makerOrder.tokenId,
                0,
                ""
            );
    }

    /*//////////////////////////////////////////////////////////////
                            Setup
    //////////////////////////////////////////////////////////////*/

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e; // ERC721 transfer manager
        buyerErc1155ApprovalTarget = sellerErc1155ApprovalTarget = 0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051; // ERC1155 transfer manager
        buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            looksRare
        );
    }

    function beforeAllPrepareMarketplaceCall(
        address,
        address,
        address[] calldata erc20Tokens,
        address[] calldata
    ) external pure override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](erc20Tokens.length + 1);
        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            // Whitelist necessary ERC-20 tokens
            setupCalls[i] = SetupCall(
                currencyManagerOwner,
                address(currencyManager),
                abi.encodeWithSelector(
                    ICurrencyManager.addCurrency.selector,
                    erc20Tokens[i]
                )
            );
        }

        // Remove protocol fee
        setupCalls[erc20Tokens.length] = SetupCall(
            looksRareOwner,
            address(looksRare),
            abi.encodeWithSelector(
                ILooksRareExchange.updateProtocolFeeRecipient.selector,
                address(0)
            )
        );

        return setupCalls;
    }

    /*//////////////////////////////////////////////////////////////
                        Test Payload Calls
    //////////////////////////////////////////////////////////////*/

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            true,
            context.offerer,
            WETH,
            ethAmount,
            nft.token,
            1,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }
        execution.executeOrder = TestCallParameters(
            address(looksRare),
            ethAmount,
            abi.encodeWithSelector(
                ILooksRareExchange.matchAskWithTakerBidUsingETHAndWETH.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            true,
            context.offerer,
            WETH,
            ethAmount,
            nft.token,
            nft.amount,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }
        execution.executeOrder = TestCallParameters(
            address(looksRare),
            ethAmount,
            abi.encodeWithSelector(
                ILooksRareExchange.matchAskWithTakerBidUsingETHAndWETH.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            true,
            context.offerer,
            erc20.token,
            erc20.amount,
            nft.token,
            1,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(looksRare),
            0,
            abi.encodeWithSelector(
                ILooksRareExchange.matchAskWithTakerBid.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedERC721WithWETH(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            true,
            context.offerer,
            erc20.token,
            erc20.amount,
            nft.token,
            1,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(looksRare),
            0,
            abi.encodeWithSelector(
                ILooksRareExchange.matchAskWithTakerBid.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 calldata erc20
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            true,
            context.offerer,
            erc20.token,
            erc20.amount,
            nft.token,
            nft.amount,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(looksRare),
            0,
            abi.encodeWithSelector(
                ILooksRareExchange.matchAskWithTakerBid.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            false,
            context.offerer,
            erc20.token,
            erc20.amount,
            nft.token,
            1,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(looksRare),
            0,
            abi.encodeWithSelector(
                ILooksRareExchange.matchBidWithTakerAsk.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedWETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            false,
            context.offerer,
            erc20.token,
            erc20.amount,
            nft.token,
            1,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(looksRare),
            0,
            abi.encodeWithSelector(
                ILooksRareExchange.matchBidWithTakerAsk.selector,
                takerOrder,
                makerOrder
            )
        );
    }

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem1155 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        OrderTypes.MakerOrder memory makerOrder = buildMakerOrder(
            false,
            context.offerer,
            erc20.token,
            erc20.amount,
            nft.token,
            nft.amount,
            nft.identifier
        );
        OrderTypes.TakerOrder memory takerOrder = buildTakerOrder(
            context.fulfiller,
            makerOrder
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(looksRare),
            0,
            abi.encodeWithSelector(
                ILooksRareExchange.matchBidWithTakerAsk.selector,
                takerOrder,
                makerOrder
            )
        );
    }
}
