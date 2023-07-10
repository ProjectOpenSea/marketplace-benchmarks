// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20, SetupCall } from "../../Types.sol";
import "./lib/OrderStructs.sol";
import "./lib/BlurTypeHashes.sol";
import { IBlurExchange } from "./interfaces/IBlurExchange.sol";
import "forge-std/console2.sol";
import { TestERC20 } from "../../../test/tokens/TestERC20.sol";

contract BlurConfig is BaseMarketConfig, BlurTypeHashes {
    function name() external pure override returns (string memory) {
        return "Blur";
    }

    function market() public pure override returns (address) {
        return address(blur);
    }

    IBlurExchange internal constant blur =
        IBlurExchange(0x000000000000Ad05Ccc4F10045630fb830B95127);

    // The "execution delegate" — functions similarly to a conduit.
    address internal constant approvalTarget =
        0x00000000000111AbE46ff893f3B2fdF1F759a8A8;

    // see "policy manager" at 0x3a35A3102b5c6bD1e4d3237248Be071EF53C8331
    address internal constant matchingPolicy =
        0x00000000006411739DA1c40B106F8511de5D1FAC;

    address internal constant BlurOwner =
        0x0000000000000000000000000000000000000000;

    // address internal constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    TestERC20 internal constant weth =
        TestERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

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

        setupCalls[0] = SetupCall(
            BlurOwner,
            address(blur),
            abi.encodeWithSelector(IBlurExchange.open.selector)
        );

        return setupCalls;
    }

    function buildOrder(
        address creator,
        Side side,
        address nftContractAddress,
        uint256 nftTokenId,
        address paymentToken,
        uint256 paymentTokenAmount,
        Fee[] memory fee
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

        order.matchingPolicy = matchingPolicy;

        order.collection = nftContractAddress;
        order.tokenId = nftTokenId;
        order.amount = 1; // TODO: Add suppport for amounts other than 1.
        order.paymentToken = paymentToken;
        order.price = paymentTokenAmount;
        order.listingTime = 0;
        order.expirationTime = block.timestamp + 1;
        order.fees = fee;
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

    function buildInputPair(
        address maker,
        address taker,
        address nftContractAddress,
        uint256 nftTokenId,
        address paymentToken,
        uint256 paymentTokenAmount,
        Fee[] memory fee,
        bool isOffer
    ) internal view returns (Input memory makerInput, Input memory takerInput) {
        Order memory makerOrder;
        Order memory takerOrder;
        uint8 v;
        bytes32 r;
        bytes32 s;

        // If it's an offer of ERC20 for ERC721, then the maker is the buyer and
        // the taker is the seller.
        (makerOrder, v, r, s) = buildOrder(
            maker,
            isOffer ? Side.Buy : Side.Sell,
            nftContractAddress,
            nftTokenId,
            paymentToken,
            paymentTokenAmount,
            fee
        );

        makerInput = buildInput(makerOrder, v, r, s, SignatureVersion.Single);

        (takerOrder, v, r, s) = buildOrder(
            taker,
            isOffer ? Side.Sell : Side.Buy,
            nftContractAddress,
            nftTokenId,
            paymentToken,
            paymentTokenAmount,
            fee
        );

        takerInput = buildInput(takerOrder, v, r, s, SignatureVersion.Single);

        return (makerInput, takerInput);
    }

    function buildExecution(
        address maker,
        address taker,
        address nftContractAddress,
        uint256 nftTokenId,
        address paymentToken,
        uint256 paymentTokenAmount,
        Fee[] memory fee,
        bool isOffer
    ) internal view returns (Execution memory _execution) {
        Execution memory execution;
        Input memory makerInput;
        Input memory takerInput;

        (makerInput, takerInput) = buildInputPair(
            maker,
            taker,
            nftContractAddress,
            nftTokenId,
            paymentToken,
            paymentTokenAmount,
            fee,
            isOffer
        );

        execution.sell = makerInput;
        execution.buy = takerInput;

        return execution;
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
            address(0),
            ethAmount,
            new Fee[](0),
            false
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

    // The current matching policy at 0x0000...1FAC does not allow for 1155s to
    // be sold.  This pattern should be close to viable when they update the
    // policy.
    //
    // See https://etherscan.io/address/0xb38827497daf7f28261910e33e22219de087c8f5#code#F1#L521,
    // https://etherscan.io/address/0x00000000006411739DA1c40B106F8511de5D1FAC#code#F1#L36.
    // function getPayload_BuyOfferedERC1155WithEther(
    //     TestOrderContext calldata context,
    //     TestItem1155 memory nft,
    //     uint256 ethAmount
    // ) external view override returns (TestOrderPayload memory execution) {
    //     (Input memory makerInput, Input memory takerInput) = buildInputPair(
    //         context.offerer,
    //         context.fulfiller,
    //         nft.token,
    //         nft.identifier,
    //         address(0),
    //         ethAmount
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

    // It's not possible to purchase NFTs with tokens other than ETH, WETH, or
    // Blur's proprietary version of WETH.
    // See https://etherscan.io/address/0xb38827497daf7f28261910e33e22219de087c8f5#code#F1#L594.
    function getPayload_BuyOfferedERC721WithWETH(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        (Input memory makerInput, Input memory takerInput) = buildInputPair(
            context.offerer,
            context.fulfiller,
            nft.token,
            nft.identifier,
            erc20.token,
            erc20.amount,
            new Fee[](0),
            false
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchange.execute.selector,
                makerInput,
                takerInput
            )
        );
    }

    function getPayload_BuyOfferedWETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external view override returns (TestOrderPayload memory execution) {
        (Input memory makerInput, Input memory takerInput) = buildInputPair(
            context.offerer,
            context.fulfiller,
            nft.token,
            nft.identifier,
            erc20.token,
            erc20.amount,
            new Fee[](0),
            true
        );

        if (context.listOnChain) {
            _notImplemented();
        }

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchange.execute.selector,
                takerInput,
                makerInput
            )
        );
    }

    function convert(uint256 val) internal pure returns (uint16) {
        return uint16(val);
    }

    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata, /* context*/
        TestItem721 memory, /* nft*/
        uint256, /* priceEthAmount*/
        address, /* feeRecipient*/
        uint256 /* feeEthAmount */
    )
        external
        pure
        override
        returns (
            TestOrderPayload memory /* execution */
        )
    {
        // TODO: figure out why this isn't working
        _notImplemented();

        // Fee[] memory fees = new Fee[](1);
        // uint256 rate;
        // rate = (feeEthAmount * 10000) / (priceEthAmount) + 1;
        // uint16 convertedRate;
        // convertedRate = convert(rate);
        // fees[0] = Fee({
        //     recipient: payable(feeRecipient),
        //     rate: convertedRate
        // });
        // (Input memory makerInput, Input memory takerInput) = buildInputPair(
        //     context.offerer,
        //     context.fulfiller,
        //     nft.token,
        //     nft.identifier,
        //     address(0),
        //     priceEthAmount,
        //     fees,
        //     false
        // );

        // if (context.listOnChain) {
        //     _notImplemented();
        // }

        // execution.executeOrder = TestCallParameters(
        //     address(blur),
        //     priceEthAmount + feeEthAmount,
        //     abi.encodeWithSelector(
        //         IBlurExchange.execute.selector,
        //         makerInput,
        //         takerInput
        //     )
        // );
    }

    function getPayload_BuyOfferedERC721WithEtherTwoFeeRecipient(
        TestOrderContext calldata, /* context */
        TestItem721 memory, /* nft */
        uint256, /* priceEthAmount */
        address, /* feeRecipient1 */
        uint256, /* feeEthAmount1 */
        address, /* feeRecipient2 */
        uint256 /* feeEthAmount2 */
    )
        external
        pure
        override
        returns (
            TestOrderPayload memory /* execution */
        )
    {
        // TODO: figure out why this isn't working
        _notImplemented();

        // Fee[] memory fees = new Fee[](2);
        // uint256 rate;
        // rate = (feeEthAmount1 * 10000) / (priceEthAmount) + 1;
        // fees[0] = Fee({
        //     recipient: payable(feeRecipient1),
        //     rate: convert(rate)
        // });
        // rate = (feeEthAmount2 * 10000) / (priceEthAmount) + 1;
        // fees[1] = Fee({
        //     recipient: payable(feeRecipient2),
        //     rate: convert(rate)
        // });
        // (Input memory makerInput, Input memory takerInput) = buildInputPair(
        //     context.offerer,
        //     context.fulfiller,
        //     nft.token,
        //     nft.identifier,
        //     address(0),
        //     priceEthAmount,
        //     fees,
        //     false
        // );

        // if (context.listOnChain) {
        //     _notImplemented();
        // }

        // execution.executeOrder = TestCallParameters(
        //     address(blur),
        //     priceEthAmount + feeEthAmount1 + feeEthAmount2,
        //     abi.encodeWithSelector(
        //         IBlurExchange.execute.selector,
        //         makerInput,
        //         takerInput
        //     )
        // );
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        require(
            contexts.length == nfts.length && nfts.length == ethAmounts.length,
            "BlurConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
        );

        uint256 sumEthAmount;

        Execution[] memory executions = new Execution[](nfts.length);
        Execution memory _execution;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (contexts[i].listOnChain) {
                _notImplemented();
            }

            _execution = buildExecution(
                contexts[i].offerer,
                contexts[i].fulfiller,
                nfts[i].token,
                nfts[i].identifier,
                address(0),
                ethAmounts[i],
                new Fee[](0),
                false
            );

            executions[i] = _execution;

            sumEthAmount += ethAmounts[i];
        }

        execution.executeOrder = TestCallParameters(
            address(blur),
            sumEthAmount,
            abi.encodeWithSelector(
                IBlurExchange.bulkExecute.selector,
                executions
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
            "BlurConfig::getPayload_BuyOfferedManyERC721WithEtherDistinctOrders: invalid input"
        );

        Execution[] memory executions = new Execution[](nfts.length);
        Execution memory _execution;

        for (uint256 i = 0; i < nfts.length; i++) {
            if (contexts[i].listOnChain) {
                _notImplemented();
            }

            _execution = buildExecution(
                contexts[i].offerer,
                contexts[i].fulfiller,
                nfts[i].token,
                nfts[i].identifier,
                erc20Address,
                erc20Amounts[i],
                new Fee[](0),
                false
            );

            executions[i] = _execution;
        }

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchange.bulkExecute.selector,
                executions
            )
        );
    }
}
