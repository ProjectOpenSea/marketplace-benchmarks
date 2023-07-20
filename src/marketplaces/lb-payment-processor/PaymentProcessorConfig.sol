// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import "../../Types.sol";
import { IPaymentProcessor } from "./interfaces/IPaymentProcessor.sol";
import "./interfaces/PaymentProcessorDataTypes.sol";
import "forge-std/Test.sol";
import { ECDSA } from "./lib/ECDSA.sol";
import { TestERC721 } from "test/tokens/TestERC721.sol";

contract PaymentProcessorConfig is BaseMarketConfig, Test {
    /// @notice keccack256("OfferApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 tokenId,uint256 amount,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant OFFER_APPROVAL_HASH =
        0x2008a1ab898fdaa2d8f178bc39e807035d2d6e330dac5e42e913ca727ab56038;

    /// @notice keccack256("CollectionOfferApproval(uint8 protocol,bool collectionLevelOffer,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 amount,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant COLLECTION_OFFER_APPROVAL_HASH =
        0x0bc3075778b80a2341ce445063e81924b88d61eb5f21c815e8f9cc824af096d0;

    /// @notice keccack256("BundledOfferApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin,uint256[] tokenIds,uint256[] amounts,uint256[] itemSalePrices)")
    bytes32 public constant BUNDLED_OFFER_APPROVAL_HASH =
        0x126520d0bca0cfa7e5852d004cc4335723ce67c638cbd55cd530fe992a089e7b;

    /// @notice keccack256("SaleApproval(uint8 protocol,bool sellerAcceptedOffer,address marketplace,uint256 marketplaceFeeNumerator,uint256 maxRoyaltyFeeNumerator,address privateBuyer,address seller,address tokenAddress,uint256 tokenId,uint256 amount,uint256 minPrice,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant SALE_APPROVAL_HASH =
        0xd3f4273db8ff5262b6bc5f6ee07d139463b4f826cce90c05165f63062f3686dc;

    /// @notice keccack256("BundledSaleApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address privateBuyer,address seller,address tokenAddress,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin,uint256[] tokenIds,uint256[] amounts,uint256[] maxRoyaltyFeeNumerators,uint256[] itemPrices)")
    bytes32 public constant BUNDLED_SALE_APPROVAL_HASH =
        0x80244acca7a02d7199149a3038653fc8cb10ca984341ec429a626fab631e1662;

    uint256 internal securityPolicyId;

    IPaymentProcessor paymentProcessor =
        IPaymentProcessor(address(0x009a1dC629242961C9E4f089b437aFD394474cc0));
    mapping(address => uint256) internal _nonces;

    function name() external pure override returns (string memory) {
        return "Payment Processor";
    }

    function market() public view override returns (address) {
        return address(paymentProcessor);
    }

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(
            paymentProcessor
        );

        securityPolicyId = paymentProcessor.createSecurityPolicy(
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            2300,
            "TEST POLICY"
        );
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        uint256 ethAmount
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: address(0),
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: ethAmount,
            offerPrice: ethAmount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            ethAmount,
            payload
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        uint256 ethAmount
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC1155,
            paymentCoin: address(0),
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: ethAmount,
            offerPrice: ethAmount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: nft.amount
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            ethAmount,
            payload
        );
    }

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        vm.prank(nft.token);
        paymentProcessor.setCollectionSecurityPolicy(
            nft.token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20.token
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20.token
            );
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: erc20.token,
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: erc20.amount,
            offerPrice: erc20.amount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedERC721WithWETH(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        vm.prank(nft.token);
        paymentProcessor.setCollectionSecurityPolicy(
            nft.token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20.token
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20.token
            );
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: erc20.token,
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: erc20.amount,
            offerPrice: erc20.amount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 memory erc20
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        vm.prank(nft.token);
        paymentProcessor.setCollectionSecurityPolicy(
            nft.token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20.token
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20.token
            );
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC1155,
            paymentCoin: erc20.token,
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: erc20.amount,
            offerPrice: erc20.amount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: nft.amount
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        vm.prank(nft.token);
        paymentProcessor.setCollectionSecurityPolicy(
            nft.token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20.token
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20.token
            );
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: true,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: erc20.token,
            tokenAddress: nft.token,
            seller: bob,
            privateBuyer: address(0),
            buyer: alice,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(bob),
            offerNonce: _getNextNonce(alice),
            listingMinPrice: erc20.amount,
            offerPrice: erc20.amount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            bob,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(alice, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedWETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        vm.prank(nft.token);
        paymentProcessor.setCollectionSecurityPolicy(
            nft.token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20.token
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20.token
            );
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: true,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: erc20.token,
            tokenAddress: nft.token,
            seller: bob,
            privateBuyer: address(0),
            buyer: alice,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(bob),
            offerNonce: _getNextNonce(alice),
            listingMinPrice: erc20.amount,
            offerPrice: erc20.amount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            bob,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(alice, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem1155 memory nft
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        vm.prank(nft.token);
        paymentProcessor.setCollectionSecurityPolicy(
            nft.token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20.token
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20.token
            );
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: true,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC1155,
            paymentCoin: erc20.token,
            tokenAddress: nft.token,
            seller: bob,
            privateBuyer: address(0),
            buyer: alice,
            delegatedPurchaser: address(0),
            marketplace: address(0),
            marketplaceFeeNumerator: 0,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(bob),
            offerNonce: _getNextNonce(alice),
            listingMinPrice: erc20.amount,
            offerPrice: erc20.amount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: nft.amount
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            bob,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(alice, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient,
        uint256 feeEthAmount
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(feeRecipient, _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(feeRecipient, _getNextNonce(bob));

        uint256 ethAmount = priceEthAmount + feeEthAmount;
        uint256 feeRate = (feeEthAmount * 10000) / priceEthAmount;

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: address(0),
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: feeRecipient,
            marketplaceFeeNumerator: feeRate,
            maxRoyaltyFeeNumerator: 0,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: ethAmount,
            offerPrice: ethAmount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            ethAmount,
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
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(feeRecipient1, _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(feeRecipient1, _getNextNonce(bob));

        uint256 ethAmount = priceEthAmount + feeEthAmount1 + feeEthAmount2;
        uint256 feeRate1 = (feeEthAmount1 * 10000) / priceEthAmount;
        uint256 feeRate2 = (feeEthAmount2 * 10000) / priceEthAmount;

        TestERC721(nft.token).setTokenRoyalty(
            nft.identifier,
            feeRecipient2,
            uint96(feeRate2)
        );

        MatchedOrder memory saleDetails = MatchedOrder({
            sellerAcceptedOffer: false,
            collectionLevelOffer: false,
            protocol: TokenProtocols.ERC721,
            paymentCoin: address(0),
            tokenAddress: nft.token,
            seller: alice,
            privateBuyer: address(0),
            buyer: bob,
            delegatedPurchaser: address(0),
            marketplace: feeRecipient1,
            marketplaceFeeNumerator: feeRate1,
            maxRoyaltyFeeNumerator: feeRate2,
            listingNonce: _getNextNonce(alice),
            offerNonce: _getNextNonce(bob),
            listingMinPrice: ethAmount,
            offerPrice: ethAmount,
            listingExpiration: type(uint256).max,
            offerExpiration: type(uint256).max,
            tokenId: nft.identifier,
            amount: 1
        });

        SignatureECDSA memory signedListing = _getSignedListing(
            alice,
            saleDetails
        );
        SignatureECDSA memory signedOffer = _getSignedOffer(bob, saleDetails);

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buySingleListing.selector,
            saleDetails,
            signedListing,
            signedOffer
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            ethAmount,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }
        address alice = context.offerer;
        address bob = context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: address(0),
                tokenAddress: address(nfts[0].token),
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: address(0),
                marketplaceFeeNumerator: 0,
                offerNonce: _getNextNonce(bob),
                offerPrice: ethAmount,
                offerExpiration: type(uint256).max
            });

        MatchedOrderBundleExtended
            memory bundleOfferDetailsExtended = MatchedOrderBundleExtended({
                bundleBase: bundledOfferDetails,
                seller: alice,
                listingNonce: _getNextNonce(alice),
                listingExpiration: type(uint256).max
            });

        uint256 numItemsInBundle = nfts.length;

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );

        Accumulator memory accumulator = Accumulator({
            tokenIds: new uint256[](numItemsInBundle),
            amounts: new uint256[](numItemsInBundle),
            salePrices: new uint256[](numItemsInBundle),
            maxRoyaltyFeeNumerators: new uint256[](numItemsInBundle),
            sellers: new address[](numItemsInBundle),
            sumListingPrices: 0
        });

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].tokenId = nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = 0;
            bundledOfferItems[i].itemPrice = ethAmount / numItemsInBundle;
            bundledOfferItems[i].listingNonce = 0;
            bundledOfferItems[i].listingExpiration = 0;
            bundledOfferItems[i].seller = alice;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            accumulator.tokenIds[i] = saleDetails.tokenId;
            accumulator.amounts[i] = saleDetails.amount;
            accumulator.salePrices[i] = saleDetails.listingMinPrice;
            accumulator.maxRoyaltyFeeNumerators[i] = saleDetails
                .maxRoyaltyFeeNumerator;
            accumulator.sellers[i] = alice;
            accumulator.sumListingPrices += saleDetails.listingMinPrice;

            // TestERC721(nfts[i].token).setTokenRoyalty(saleDetails.tokenId, feeReceiver, 0);
        }

        AccumulatorHashes memory accumulatorHashes = AccumulatorHashes({
            tokenIdsKeccakHash: keccak256(
                abi.encodePacked(accumulator.tokenIds)
            ),
            amountsKeccakHash: keccak256(abi.encodePacked(accumulator.amounts)),
            maxRoyaltyFeeNumeratorsKeccakHash: keccak256(
                abi.encodePacked(accumulator.maxRoyaltyFeeNumerators)
            ),
            itemPricesKeccakHash: keccak256(
                abi.encodePacked(accumulator.salePrices)
            )
        });

        SignatureECDSA
            memory signedBundledOffer = _getSignedOfferForBundledItems(
                bob,
                bundledOfferDetails,
                bundledOfferItems
            );
        SignatureECDSA memory signedBundledListing = _getSignedBundledListing(
            alice,
            accumulatorHashes,
            bundleOfferDetailsExtended
        );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buyBundledListing.selector,
            signedBundledListing,
            signedBundledOffer,
            bundleOfferDetailsExtended,
            bundledOfferItems
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            ethAmount,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherItemsPricedIndividually(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }
        address alice = context.offerer;
        address bob = context.fulfiller;
        uint256 numItemsInBundle = nfts.length;
        uint256 totalEthAmount = 0;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            totalEthAmount += ethAmounts[i];
        }

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: address(0),
                tokenAddress: address(nfts[0].token),
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: address(0),
                marketplaceFeeNumerator: 0,
                offerNonce: _getNextNonce(bob),
                offerPrice: totalEthAmount,
                offerExpiration: type(uint256).max
            });

        MatchedOrderBundleExtended
            memory bundleOfferDetailsExtended = MatchedOrderBundleExtended({
                bundleBase: bundledOfferDetails,
                seller: alice,
                listingNonce: _getNextNonce(alice),
                listingExpiration: type(uint256).max
            });

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );

        Accumulator memory accumulator = Accumulator({
            tokenIds: new uint256[](numItemsInBundle),
            amounts: new uint256[](numItemsInBundle),
            salePrices: new uint256[](numItemsInBundle),
            maxRoyaltyFeeNumerators: new uint256[](numItemsInBundle),
            sellers: new address[](numItemsInBundle),
            sumListingPrices: 0
        });

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].tokenId = nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = 0;
            bundledOfferItems[i].itemPrice = ethAmounts[i];
            bundledOfferItems[i].listingNonce = 0;
            bundledOfferItems[i].listingExpiration = 0;
            bundledOfferItems[i].seller = alice;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            accumulator.tokenIds[i] = saleDetails.tokenId;
            accumulator.amounts[i] = saleDetails.amount;
            accumulator.salePrices[i] = saleDetails.listingMinPrice;
            accumulator.maxRoyaltyFeeNumerators[i] = saleDetails
                .maxRoyaltyFeeNumerator;
            accumulator.sellers[i] = alice;
            accumulator.sumListingPrices += saleDetails.listingMinPrice;

            // TestERC721(nfts[i].token).setTokenRoyalty(saleDetails.tokenId, feeReceiver, 0);
        }

        AccumulatorHashes memory accumulatorHashes = AccumulatorHashes({
            tokenIdsKeccakHash: keccak256(
                abi.encodePacked(accumulator.tokenIds)
            ),
            amountsKeccakHash: keccak256(abi.encodePacked(accumulator.amounts)),
            maxRoyaltyFeeNumeratorsKeccakHash: keccak256(
                abi.encodePacked(accumulator.maxRoyaltyFeeNumerators)
            ),
            itemPricesKeccakHash: keccak256(
                abi.encodePacked(accumulator.salePrices)
            )
        });

        SignatureECDSA
            memory signedBundledOffer = _getSignedOfferForBundledItems(
                bob,
                bundledOfferDetails,
                bundledOfferItems
            );
        SignatureECDSA memory signedBundledListing = _getSignedBundledListing(
            alice,
            accumulatorHashes,
            bundleOfferDetailsExtended
        );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buyBundledListing.selector,
            signedBundledListing,
            signedBundledOffer,
            bundleOfferDetailsExtended,
            bundledOfferItems
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            totalEthAmount,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherItemsPricedIndividuallyOneFeeRecipient(
        TestBundleOrderWithSingleFeeReceiver memory args
    ) external override returns (TestOrderPayload memory execution) {
        if (args.context.listOnChain) {
            _notImplemented();
        }
        uint256 totalEthAmount = 0;
        uint256 numItemsInBundle = args.nfts.length;
        address alice = args.context.offerer;
        address bob = args.context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            totalEthAmount += args.itemPrices[i];
        }

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: address(0),
                tokenAddress: address(args.nfts[0].token),
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: args.feeRecipient,
                marketplaceFeeNumerator: args.feeRate,
                offerNonce: _getNextNonce(bob),
                offerPrice: totalEthAmount,
                offerExpiration: type(uint256).max
            });

        MatchedOrderBundleExtended
            memory bundleOfferDetailsExtended = MatchedOrderBundleExtended({
                bundleBase: bundledOfferDetails,
                seller: alice,
                listingNonce: _getNextNonce(alice),
                listingExpiration: type(uint256).max
            });

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );

        Accumulator memory accumulator = Accumulator({
            tokenIds: new uint256[](numItemsInBundle),
            amounts: new uint256[](numItemsInBundle),
            salePrices: new uint256[](numItemsInBundle),
            maxRoyaltyFeeNumerators: new uint256[](numItemsInBundle),
            sellers: new address[](numItemsInBundle),
            sumListingPrices: 0
        });

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].tokenId = args.nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = 0;
            bundledOfferItems[i].itemPrice = args.itemPrices[i];
            bundledOfferItems[i].listingNonce = 0;
            bundledOfferItems[i].listingExpiration = 0;
            bundledOfferItems[i].seller = alice;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            accumulator.tokenIds[i] = saleDetails.tokenId;
            accumulator.amounts[i] = saleDetails.amount;
            accumulator.salePrices[i] = saleDetails.listingMinPrice;
            accumulator.maxRoyaltyFeeNumerators[i] = saleDetails
                .maxRoyaltyFeeNumerator;
            accumulator.sellers[i] = alice;
            accumulator.sumListingPrices += saleDetails.listingMinPrice;

            // TestERC721(args.nfts[i].token).setTokenRoyalty(saleDetails.tokenId, args.feeRecipient, uint96(args.feeEthAmounts[i] * 10000 / args.ethAmounts[i]));
        }

        AccumulatorHashes memory accumulatorHashes = AccumulatorHashes({
            tokenIdsKeccakHash: keccak256(
                abi.encodePacked(accumulator.tokenIds)
            ),
            amountsKeccakHash: keccak256(abi.encodePacked(accumulator.amounts)),
            maxRoyaltyFeeNumeratorsKeccakHash: keccak256(
                abi.encodePacked(accumulator.maxRoyaltyFeeNumerators)
            ),
            itemPricesKeccakHash: keccak256(
                abi.encodePacked(accumulator.salePrices)
            )
        });

        SignatureECDSA memory signedBundledListing = _getSignedBundledListing(
            alice,
            accumulatorHashes,
            bundleOfferDetailsExtended
        );
        SignatureECDSA
            memory signedBundledOffer = _getSignedOfferForBundledItems(
                bob,
                bundledOfferDetails,
                bundledOfferItems
            );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buyBundledListing.selector,
            signedBundledListing,
            signedBundledOffer,
            bundleOfferDetailsExtended,
            bundledOfferItems
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            totalEthAmount,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherItemsPricedIndividuallyTwoFeeRecipients(
        TestBundleOrderWithTwoFeeReceivers memory args
    ) external override returns (TestOrderPayload memory execution) {
        if (args.context.listOnChain) {
            _notImplemented();
        }
        uint256 totalEthAmount = 0;
        uint256 numItemsInBundle = args.nfts.length;
        address alice = args.context.offerer;
        address bob = args.context.fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            totalEthAmount += args.itemPrices[i];
        }

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: address(0),
                tokenAddress: address(args.nfts[0].token),
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: args.feeRecipient1,
                marketplaceFeeNumerator: args.feeRate1,
                offerNonce: _getNextNonce(bob),
                offerPrice: totalEthAmount,
                offerExpiration: type(uint256).max
            });

        MatchedOrderBundleExtended
            memory bundleOfferDetailsExtended = MatchedOrderBundleExtended({
                bundleBase: bundledOfferDetails,
                seller: alice,
                listingNonce: _getNextNonce(alice),
                listingExpiration: type(uint256).max
            });

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );

        Accumulator memory accumulator = Accumulator({
            tokenIds: new uint256[](numItemsInBundle),
            amounts: new uint256[](numItemsInBundle),
            salePrices: new uint256[](numItemsInBundle),
            maxRoyaltyFeeNumerators: new uint256[](numItemsInBundle),
            sellers: new address[](numItemsInBundle),
            sumListingPrices: 0
        });

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].tokenId = args.nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = args.feeRate2;
            bundledOfferItems[i].itemPrice = args.itemPrices[i];
            bundledOfferItems[i].listingNonce = 0;
            bundledOfferItems[i].listingExpiration = 0;
            bundledOfferItems[i].seller = alice;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            accumulator.tokenIds[i] = saleDetails.tokenId;
            accumulator.amounts[i] = saleDetails.amount;
            accumulator.salePrices[i] = saleDetails.listingMinPrice;
            accumulator.maxRoyaltyFeeNumerators[i] = saleDetails
                .maxRoyaltyFeeNumerator;
            accumulator.sellers[i] = alice;
            accumulator.sumListingPrices += saleDetails.listingMinPrice;

            TestERC721(args.nfts[i].token).setTokenRoyalty(
                saleDetails.tokenId,
                args.feeRecipient2,
                uint96(args.feeRate2)
            );
        }

        AccumulatorHashes memory accumulatorHashes = AccumulatorHashes({
            tokenIdsKeccakHash: keccak256(
                abi.encodePacked(accumulator.tokenIds)
            ),
            amountsKeccakHash: keccak256(abi.encodePacked(accumulator.amounts)),
            maxRoyaltyFeeNumeratorsKeccakHash: keccak256(
                abi.encodePacked(accumulator.maxRoyaltyFeeNumerators)
            ),
            itemPricesKeccakHash: keccak256(
                abi.encodePacked(accumulator.salePrices)
            )
        });

        SignatureECDSA memory signedBundledListing = _getSignedBundledListing(
            alice,
            accumulatorHashes,
            bundleOfferDetailsExtended
        );
        SignatureECDSA
            memory signedBundledOffer = _getSignedOfferForBundledItems(
                bob,
                bundledOfferDetails,
                bundledOfferItems
            );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.buyBundledListing.selector,
            signedBundledListing,
            signedBundledOffer,
            bundleOfferDetailsExtended,
            bundledOfferItems
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            totalEthAmount,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata ethAmounts
    ) external override returns (TestOrderPayload memory execution) {
        for (uint256 i = 0; i < contexts.length; ++i) {
            if (contexts[i].listOnChain) {
                _notImplemented();
            }
        }

        uint256 totalEthAmount = 0;
        uint256 numItemsInBundle = nfts.length;
        address alice = contexts[0].offerer;
        address bob = contexts[0].fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            totalEthAmount += ethAmounts[i];
        }

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: address(0),
                tokenAddress: nfts[0].token,
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: address(0),
                marketplaceFeeNumerator: 0,
                offerNonce: _getNextNonce(bob),
                offerPrice: totalEthAmount,
                offerExpiration: type(uint256).max
            });

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );
        SignatureECDSA[] memory signedListings = new SignatureECDSA[](
            numItemsInBundle
        );

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].seller = alice;
            bundledOfferItems[i].tokenId = nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = 0;
            bundledOfferItems[i].listingNonce = _getNextNonce(alice);
            bundledOfferItems[i].itemPrice = ethAmounts[i];
            bundledOfferItems[i].listingExpiration = type(uint256).max;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            signedListings[i] = _getSignedListing(alice, saleDetails);
        }

        SignatureECDSA memory signedOffer = _getSignedOfferForBundledItems(
            bob,
            bundledOfferDetails,
            bundledOfferItems
        );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.sweepCollection.selector,
            signedOffer,
            bundledOfferDetails,
            bundledOfferItems,
            signedListings
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            totalEthAmount,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithErc20DistinctOrders(
        TestOrderContext[] calldata contexts,
        address erc20Address,
        TestItem721[] calldata nfts,
        uint256[] calldata erc20Amounts
    ) external override returns (TestOrderPayload memory execution) {
        for (uint256 i = 0; i < contexts.length; ++i) {
            if (contexts[i].listOnChain) {
                _notImplemented();
            }
        }

        vm.prank(nfts[0].token);
        paymentProcessor.setCollectionSecurityPolicy(
            nfts[0].token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20Address
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20Address
            );
        }

        uint256 totalErc20Amount = 0;
        uint256 numItemsInBundle = nfts.length;
        address alice = contexts[0].offerer;
        address bob = contexts[0].fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            totalErc20Amount += erc20Amounts[i];
        }

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: erc20Address,
                tokenAddress: nfts[0].token,
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: address(0),
                marketplaceFeeNumerator: 0,
                offerNonce: _getNextNonce(bob),
                offerPrice: totalErc20Amount,
                offerExpiration: type(uint256).max
            });

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );
        SignatureECDSA[] memory signedListings = new SignatureECDSA[](
            numItemsInBundle
        );

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].seller = alice;
            bundledOfferItems[i].tokenId = nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = 0;
            bundledOfferItems[i].listingNonce = _getNextNonce(alice);
            bundledOfferItems[i].itemPrice = erc20Amounts[i];
            bundledOfferItems[i].listingExpiration = type(uint256).max;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            signedListings[i] = _getSignedListing(alice, saleDetails);
        }

        SignatureECDSA memory signedOffer = _getSignedOfferForBundledItems(
            bob,
            bundledOfferDetails,
            bundledOfferItems
        );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.sweepCollection.selector,
            signedOffer,
            bundledOfferDetails,
            bundledOfferItems,
            signedListings
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function getPayload_BuyOfferedManyERC721WithWETHDistinctOrders(
        TestOrderContext[] calldata contexts,
        address erc20Address,
        TestItem721[] calldata nfts,
        uint256[] calldata erc20Amounts
    ) external override returns (TestOrderPayload memory execution) {
        for (uint256 i = 0; i < contexts.length; ++i) {
            if (contexts[i].listOnChain) {
                _notImplemented();
            }
        }

        vm.prank(nfts[0].token);
        paymentProcessor.setCollectionSecurityPolicy(
            nfts[0].token,
            securityPolicyId
        );

        if (
            !paymentProcessor.isPaymentMethodApproved(
                securityPolicyId,
                erc20Address
            )
        ) {
            paymentProcessor.whitelistPaymentMethod(
                securityPolicyId,
                erc20Address
            );
        }

        uint256 totalErc20Amount = 0;
        uint256 numItemsInBundle = nfts.length;
        address alice = contexts[0].offerer;
        address bob = contexts[0].fulfiller;

        vm.prank(alice);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(alice));

        vm.prank(bob);
        paymentProcessor.revokeSingleNonce(address(0), _getNextNonce(bob));

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            totalErc20Amount += erc20Amounts[i];
        }

        MatchedOrderBundleBase
            memory bundledOfferDetails = MatchedOrderBundleBase({
                protocol: TokenProtocols.ERC721,
                paymentCoin: erc20Address,
                tokenAddress: nfts[0].token,
                privateBuyer: address(0),
                buyer: bob,
                delegatedPurchaser: address(0),
                marketplace: address(0),
                marketplaceFeeNumerator: 0,
                offerNonce: _getNextNonce(bob),
                offerPrice: totalErc20Amount,
                offerExpiration: type(uint256).max
            });

        BundledItem[] memory bundledOfferItems = new BundledItem[](
            numItemsInBundle
        );
        SignatureECDSA[] memory signedListings = new SignatureECDSA[](
            numItemsInBundle
        );

        for (uint256 i = 0; i < numItemsInBundle; ++i) {
            bundledOfferItems[i].seller = alice;
            bundledOfferItems[i].tokenId = nfts[i].identifier;
            bundledOfferItems[i].amount = 1;
            bundledOfferItems[i].maxRoyaltyFeeNumerator = 0;
            bundledOfferItems[i].listingNonce = _getNextNonce(alice);
            bundledOfferItems[i].itemPrice = erc20Amounts[i];
            bundledOfferItems[i].listingExpiration = type(uint256).max;

            MatchedOrder memory saleDetails = MatchedOrder({
                sellerAcceptedOffer: false,
                collectionLevelOffer: false,
                protocol: bundledOfferDetails.protocol,
                paymentCoin: bundledOfferDetails.paymentCoin,
                tokenAddress: bundledOfferDetails.tokenAddress,
                seller: bundledOfferItems[i].seller,
                privateBuyer: address(0),
                buyer: bundledOfferDetails.buyer,
                delegatedPurchaser: bundledOfferDetails.delegatedPurchaser,
                marketplace: bundledOfferDetails.marketplace,
                marketplaceFeeNumerator: bundledOfferDetails
                    .marketplaceFeeNumerator,
                maxRoyaltyFeeNumerator: bundledOfferItems[i]
                    .maxRoyaltyFeeNumerator,
                listingNonce: bundledOfferItems[i].listingNonce,
                offerNonce: bundledOfferDetails.offerNonce,
                listingMinPrice: bundledOfferItems[i].itemPrice,
                offerPrice: bundledOfferItems[i].itemPrice,
                listingExpiration: bundledOfferItems[i].listingExpiration,
                offerExpiration: bundledOfferDetails.offerExpiration,
                tokenId: bundledOfferItems[i].tokenId,
                amount: bundledOfferItems[i].amount
            });

            signedListings[i] = _getSignedListing(alice, saleDetails);
        }

        SignatureECDSA memory signedOffer = _getSignedOfferForBundledItems(
            bob,
            bundledOfferDetails,
            bundledOfferItems
        );

        bytes memory payload = abi.encodeWithSelector(
            IPaymentProcessor.sweepCollection.selector,
            signedOffer,
            bundledOfferDetails,
            bundledOfferItems,
            signedListings
        );

        execution.executeOrder = TestCallParameters(
            address(paymentProcessor),
            0,
            payload
        );
    }

    function _getNextNonce(address account) internal returns (uint256) {
        uint256 nextUnusedNonce = _nonces[account];
        ++_nonces[account];
        return nextUnusedNonce;
    }

    function _getSignedListing(
        address sellerAddress_,
        MatchedOrder memory saleDetails
    ) internal view returns (SignatureECDSA memory) {
        bytes32 listingDigest = ECDSA.toTypedDataHash(
            paymentProcessor.getDomainSeparator(),
            keccak256(
                bytes.concat(
                    abi.encode(
                        SALE_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.sellerAcceptedOffer,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.maxRoyaltyFeeNumerator,
                        saleDetails.privateBuyer,
                        saleDetails.seller,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId
                    ),
                    abi.encode(
                        saleDetails.amount,
                        saleDetails.listingMinPrice,
                        saleDetails.listingExpiration,
                        saleDetails.listingNonce,
                        paymentProcessor.masterNonces(saleDetails.seller),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        (uint8 listingV, bytes32 listingR, bytes32 listingS) = _sign(
            sellerAddress_,
            listingDigest
        );
        SignatureECDSA memory signedListing = SignatureECDSA({
            v: listingV,
            r: listingR,
            s: listingS
        });

        return signedListing;
    }

    function _getSignedOffer(
        address buyerAddress_,
        MatchedOrder memory saleDetails
    ) internal view returns (SignatureECDSA memory) {
        bytes32 offerDigest = ECDSA.toTypedDataHash(
            paymentProcessor.getDomainSeparator(),
            keccak256(
                bytes.concat(
                    abi.encode(
                        OFFER_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.delegatedPurchaser,
                        saleDetails.buyer,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.amount,
                        saleDetails.offerPrice
                    ),
                    abi.encode(
                        saleDetails.offerExpiration,
                        saleDetails.offerNonce,
                        paymentProcessor.masterNonces(saleDetails.buyer),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        (uint8 offerV, bytes32 offerR, bytes32 offerS) = _sign(
            buyerAddress_,
            offerDigest
        );
        SignatureECDSA memory signedOffer = SignatureECDSA({
            v: offerV,
            r: offerR,
            s: offerS
        });

        return signedOffer;
    }

    function _getSignedOfferForBundledItems(
        address buyerAddress_,
        MatchedOrderBundleBase memory bundledOfferDetails,
        BundledItem[] memory bundledOfferItems
    ) internal view returns (SignatureECDSA memory) {
        uint256[] memory tokenIds = new uint256[](bundledOfferItems.length);
        uint256[] memory amounts = new uint256[](bundledOfferItems.length);
        uint256[] memory itemPrices = new uint256[](bundledOfferItems.length);
        for (uint256 i = 0; i < bundledOfferItems.length; ++i) {
            tokenIds[i] = bundledOfferItems[i].tokenId;
            amounts[i] = bundledOfferItems[i].amount;
            itemPrices[i] = bundledOfferItems[i].itemPrice;
        }

        bytes32 offerDigest = ECDSA.toTypedDataHash(
            paymentProcessor.getDomainSeparator(),
            keccak256(
                bytes.concat(
                    abi.encode(
                        BUNDLED_OFFER_APPROVAL_HASH,
                        uint8(bundledOfferDetails.protocol),
                        bundledOfferDetails.marketplace,
                        bundledOfferDetails.marketplaceFeeNumerator,
                        bundledOfferDetails.delegatedPurchaser,
                        bundledOfferDetails.buyer,
                        bundledOfferDetails.tokenAddress,
                        bundledOfferDetails.offerPrice
                    ),
                    abi.encode(
                        bundledOfferDetails.offerExpiration,
                        bundledOfferDetails.offerNonce,
                        paymentProcessor.masterNonces(
                            bundledOfferDetails.buyer
                        ),
                        bundledOfferDetails.paymentCoin,
                        keccak256(abi.encodePacked(tokenIds)),
                        keccak256(abi.encodePacked(amounts)),
                        keccak256(abi.encodePacked(itemPrices))
                    )
                )
            )
        );

        (uint8 offerV, bytes32 offerR, bytes32 offerS) = _sign(
            buyerAddress_,
            offerDigest
        );
        SignatureECDSA memory signedOffer = SignatureECDSA({
            v: offerV,
            r: offerR,
            s: offerS
        });

        return signedOffer;
    }

    function _getSignedBundledListing(
        address sellerAddress_,
        AccumulatorHashes memory accumulatorHashes,
        MatchedOrderBundleExtended memory bundleDetails
    ) internal view returns (SignatureECDSA memory) {
        bytes32 listingDigest = ECDSA.toTypedDataHash(
            paymentProcessor.getDomainSeparator(),
            keccak256(
                bytes.concat(
                    abi.encode(
                        BUNDLED_SALE_APPROVAL_HASH,
                        uint8(bundleDetails.bundleBase.protocol),
                        bundleDetails.bundleBase.marketplace,
                        bundleDetails.bundleBase.marketplaceFeeNumerator,
                        bundleDetails.bundleBase.privateBuyer,
                        bundleDetails.seller,
                        bundleDetails.bundleBase.tokenAddress
                    ),
                    abi.encode(
                        bundleDetails.listingExpiration,
                        bundleDetails.listingNonce,
                        paymentProcessor.masterNonces(bundleDetails.seller),
                        bundleDetails.bundleBase.paymentCoin,
                        accumulatorHashes.tokenIdsKeccakHash,
                        accumulatorHashes.amountsKeccakHash,
                        accumulatorHashes.maxRoyaltyFeeNumeratorsKeccakHash,
                        accumulatorHashes.itemPricesKeccakHash
                    )
                )
            )
        );

        (uint8 listingV, bytes32 listingR, bytes32 listingS) = _sign(
            sellerAddress_,
            listingDigest
        );
        SignatureECDSA memory signedListing = SignatureECDSA({
            v: listingV,
            r: listingR,
            s: listingS
        });

        return signedListing;
    }
}
