// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Vm } from "forge-std/Vm.sol";

import { StdCheats } from "forge-std/StdCheats.sol";

import "forge-std/console2.sol";

import { MerkleProof } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import "./lib/Constants.sol";

import { BaseMarketConfig } from "../../BaseMarketConfig.sol";

import { TakeAsk, TakeBid, TakeAskSingle, TakeBidSingle, Order, Exchange, Fees, FeeRate, AssetType, OrderType, Transfer, FungibleTransfers, StateUpdate, Cancel, Listing } from "./lib/Structs.sol";

import "./lib/BlurV2TypeHashes.sol";

import { TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20, SetupCall } from "../../Types.sol";

import { IBlurExchangeV2 } from "./interfaces/IBlurExchangeV2.sol";

import { Oracle } from "./lib/Oracle.sol";

import { TestERC20 } from "../../../test/tokens/TestERC20.sol";

import { Merkle } from "./lib/Merkle.sol";

import "forge-std/console.sol";

interface IBeth {
    function deposit() external payable;
}

address constant VM_ADDRESS = address(
    uint160(uint256(keccak256("hevm cheat code")))
);
Vm constant vm = Vm(VM_ADDRESS);

contract BlurV2Config is BaseMarketConfig, BlurV2TypeHashes, StdCheats, Merkle {
    error ExpiredOracleSignature();
    error UnauthorizedOracle();
    error InvalidOracleSignature();

    uint256 internal oraclePk;
    address payable internal oracle;
    Oracle oracleContract;

    bytes32[] public hashes;

    constructor() BaseMarketConfig() {
        oraclePk = 0x0fac1e;
        oracle = payable(vm.addr(oraclePk));
        vm.allowCheatcodes(oracle);
        deployCodeTo("out/Oracle.sol/Oracle.json", oracle);
        oracleContract = Oracle(oracle);

        vm.label(approvalTarget, "blurDelegate");
        vm.label(oracle, "fakeBlurOracle");
        vm.label(address(blur), "blurExchangeV2");

        // vm.allowCheatcodes(address(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5));
        // vm.allowCheatcodes(0x5fa60726E62c50Af45Ff2F6280C468DA438A7837);
        // bytes memory args;
        // address delegate = 0x2f18F339620a63e43f0839Eeb18D7de1e1Be4DfB;
        // address pool = 0x0000000000A39bb272e79075ade125fd351887Ac;
        // address proxy = 0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5;
        // args  = abi.encode(delegate, pool, proxy);
        // deployCodeTo("out/BlurExchangeV2.sol/BlurExchangeV2.json", args, 0x5fa60726E62c50Af45Ff2F6280C468DA438A7837);

        // uint256 bobPk = 0xb0b;
        // address payable bob = payable(vm.addr(bobPk));

        // vm.deal(bob, 1 ether);

        // vm.prank(bob);
        // beth.deposit{value: 1 ether}();
    }

    function name() external pure override returns (string memory) {
        return "BlurV2";
    }

    function market() public pure override returns (address) {
        return address(blur);
    }

    IBlurExchangeV2 internal constant blur =
        IBlurExchangeV2(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5);

    IBeth internal constant beth =
        IBeth(0x0000000000A39bb272e79075ade125fd351887Ac);

    // The "execution delegate" — functions similarly to a conduit.
    address internal constant approvalTarget =
        0x2f18F339620a63e43f0839Eeb18D7de1e1Be4DfB;

    TestERC20 internal constant weth =
        TestERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    TestERC20 internal constant bethTestERC20 =
        TestERC20(0x0000000000A39bb272e79075ade125fd351887Ac);

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
    ) external view override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](1);

        address blurOwner = blur.owner();

        setupCalls[0] = SetupCall(
            blurOwner,
            address(blur),
            abi.encodeWithSelector(
                IBlurExchangeV2.setOracle.selector,
                oracle,
                true
            )
        );

        return setupCalls;
    }

    function buildTakeAsk(
        Order[] memory orders,
        Exchange[] memory exchanges,
        FeeRate memory takerFee,
        bytes memory signatures,
        address tokenRecipient
    ) internal pure returns (TakeAsk memory takeAskStruct) {
        takeAskStruct.orders = orders;
        takeAskStruct.exchanges = exchanges;
        takeAskStruct.takerFee = takerFee;
        takeAskStruct.signatures = signatures;
        takeAskStruct.tokenRecipient = tokenRecipient;

        return takeAskStruct;
    }

    function buildTakeAskSingle(
        Order memory order,
        Exchange memory exchange,
        FeeRate memory takerFee,
        bytes memory signature,
        address tokenRecipient
    ) internal pure returns (TakeAskSingle memory takeAskSingleStruct) {
        takeAskSingleStruct.order = order;
        takeAskSingleStruct.exchange = exchange;
        takeAskSingleStruct.takerFee = takerFee;
        takeAskSingleStruct.signature = signature;
        takeAskSingleStruct.tokenRecipient = tokenRecipient;

        return takeAskSingleStruct;
    }

    function buildTakeBid(
        Order[] memory orders,
        Exchange[] memory exchanges,
        FeeRate memory takerFee,
        bytes memory signatures
    ) internal pure returns (TakeBid memory takeBidStruct) {
        takeBidStruct.orders = orders;
        takeBidStruct.exchanges = exchanges;
        takeBidStruct.takerFee = takerFee;
        takeBidStruct.signatures = signatures;

        return takeBidStruct;
    }

    function buildTakeBidSingle(
        Order memory order,
        Exchange memory exchange,
        FeeRate memory takerFee,
        bytes memory signature
    ) internal pure returns (TakeBidSingle memory takeBidSingleStruct) {
        takeBidSingleStruct.order = order;
        takeBidSingleStruct.exchange = exchange;
        takeBidSingleStruct.takerFee = takerFee;
        takeBidSingleStruct.signature = signature;

        return takeBidSingleStruct;
    }

    function buildExchange(
        uint256 index,
        bytes32[] memory proof,
        Listing memory listing,
        Taker memory taker
    ) internal pure returns (Exchange memory exchangeStruct) {
        exchangeStruct.index = index;
        exchangeStruct.proof = proof;
        exchangeStruct.listing = listing;
        exchangeStruct.taker = taker;

        return exchangeStruct;
    }

    function buildListing(
        uint256 index,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) internal pure returns (Listing memory listingStruct) {
        listingStruct.index = index;
        listingStruct.tokenId = tokenId;
        listingStruct.amount = amount;
        listingStruct.price = price;

        return listingStruct;
    }

    function buildTaker(uint256 tokenId, uint256 amount)
        internal
        pure
        returns (Taker memory takerStruct)
    {
        takerStruct.tokenId = tokenId;
        takerStruct.amount = amount;

        return takerStruct;
    }

    function buildOrder(
        address offerer,
        address collection,
        bytes32 listingsRoot,
        uint256 numberOfListings,
        uint256 expirationTime,
        AssetType assetType,
        FeeRate memory makerFee,
        uint256 salt
    ) internal pure returns (Order memory orderStruct) {
        orderStruct.trader = offerer;
        orderStruct.collection = collection;
        orderStruct.listingsRoot = listingsRoot;
        orderStruct.numberOfListings = numberOfListings;
        orderStruct.expirationTime = expirationTime;
        orderStruct.assetType = assetType;
        orderStruct.makerFee = makerFee;
        orderStruct.salt = salt;

        return orderStruct;
    }

    function buildFees(FeeRate memory protocolFee, FeeRate memory takerFee)
        internal
        pure
        returns (Fees memory feesStruct)
    {
        feesStruct.protocolFee = protocolFee;
        feesStruct.takerFee = takerFee;

        return feesStruct;
    }

    function buildFeeRate(address recipient, uint256 rate)
        internal
        pure
        returns (FeeRate memory feeRateStruct)
    {
        feeRateStruct.recipient = recipient;
        feeRateStruct.rate = uint16(rate);

        return feeRateStruct;
    }

    // struct TakeAskSingle {
    //     Order order;
    //     Exchange exchange;
    //     FeeRate takerFee;
    //     bytes signature;
    //     address tokenRecipient;
    // }

    // /**
    //  * @notice Wrapper of _takeAskSingle that verifies an oracle signature of the calldata before executing
    //  * @param inputs Inputs for _takeAskSingle
    //  * @param oracleSignature Oracle signature of inputs
    //  */
    // function takeAskSingle(
    //     TakeAskSingle memory inputs,
    //     bytes calldata oracleSignature
    // )
    //     public
    //     payable
    //     nonReentrant
    //     verifyOracleSignature(_hashCalldata(msg.sender), oracleSignature)
    // {
    //     _takeAskSingle(
    //         inputs.order,
    //         inputs.exchange,
    //         inputs.takerFee,
    //         inputs.signature,
    //         inputs.tokenRecipient
    //     );
    // }

    // /**
    //  * @notice Create a hash of calldata with an approved caller
    //  * @param _caller Address approved to execute the calldata
    //  * @return hash Calldata hash
    //  */
    // function _hashCalldata(address _caller)
    //     internal
    //     pure
    //     returns (bytes32 hash)
    // {
    //     assembly {
    //         let nextPointer := mload(0x40)
    //         let size := add(sub(nextPointer, 0x80), 0x20)
    //         mstore(nextPointer, _caller)
    //         hash := keccak256(0x80, size)
    //     }
    // }

    /**
     * @notice Create an EIP712 hash to sign
     * @param hash Primary EIP712 object hash
     * @return EIP712 hash
     */
    function _hashToSign(bytes32 hash) private pure returns (bytes32) {
        return keccak256(bytes.concat(bytes2(0x1901), DOMAIN_SEPARATOR, hash));
    }

    // REFERENCE MERKLE CODE
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    // /**
    //  * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
    //  * defined by `root`. For this, a `proof` must be provided, containing
    //  * sibling hashes on the branch from the leaf to the root of the tree. Each
    //  * pair of leaves and each pair of pre-images are assumed to be sorted.
    //  */
    // function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
    //     return processProof(proof, leaf) == root;
    // }

    // /**
    //  * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
    //  * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
    //  * hash matches the root of the tree. When processing the proof, the pairs
    //  * of leafs & pre-images are assumed to be sorted.
    //  *
    //  * _Available since v4.4._
    //  */
    // function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    //     bytes32 computedHash = leaf;
    //     for (uint256 i = 0; i < proof.length; i++) {
    //         computedHash = _hashPair(computedHash, proof[i]);
    //     }
    //     return computedHash;
    // }

    // function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    //     return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    // }

    // function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    //     /// @solidity memory-safe-assembly
    //     assembly {
    //         mstore(0x00, a)
    //         mstore(0x20, b)
    //         value := keccak256(0x00, 0x40)
    //     }
    // }

    // WHAT BLUR DOES WITH THE LISTINGS ROOT
    // validListing = MerkleProof.verify(
    //     // proof        // root             // leaf
    //     exchange.proof, order.listingsRoot, hashListing(listing)
    // );

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function getMerkleRoot(bytes32[] memory inputHashes)
        public
        pure
        returns (bytes32 merkleRoot)
    {
        merkleRoot = getRoot(inputHashes);
    }

    function buildListingsRoot(Exchange[] memory exchanges)
        internal
        view
        returns (bytes32 listingsRoot)
    {
        bytes32[] memory listingHashes;
        if (exchanges.length < 2) {
            listingHashes = new bytes32[](2);
            // Murky needs two.
            listingHashes[0] = blur.hashListing(exchanges[0].listing);
            listingHashes[1] = blur.hashListing(exchanges[0].listing);
            listingsRoot = getMerkleRoot(listingHashes);
        } else {
            listingHashes = new bytes32[](exchanges.length);
            for (uint256 i; i < exchanges.length; ++i) {
                listingHashes[i] = blur.hashListing(exchanges[i].listing);
            }

            for (uint256 i; i < listingHashes.length; ++i) {
                console.log("listingHashes[i]");
                console.logBytes32(listingHashes[i]);
            }
            listingsRoot = getMerkleRoot(listingHashes);
        }

        return listingsRoot;
    }

    function buildProofArray(Exchange[] memory exchanges, uint256 node)
        internal
        pure
        returns (bytes32[] memory proofArray)
    {
        bytes32[] memory listingHashes;
        if (exchanges.length < 2) {
            listingHashes = new bytes32[](2);
            listingHashes[0] = blur.hashListing(exchanges[0].listing);
            listingHashes[1] = blur.hashListing(exchanges[0].listing);

            proofArray = getProof(listingHashes, 0);
        } else {
            listingHashes = new bytes32[](exchanges.length);
            for (uint256 i; i < exchanges.length; ++i) {
                listingHashes[i] = blur.hashListing(exchanges[i].listing);
            }

            proofArray = getProof(listingHashes, node);
        }
    }

    function _checkLiveness(Order memory order) private view returns (bool) {
        return (order.expirationTime > block.timestamp);
    }

    /**
     * @notice Check that the fees to be taken will not overflow the purchase price
     * @param makerFee Maker fee amount
     * @param fees Protocol and taker fee rates
     * @return Fees are valid
     */
    function _checkFee(FeeRate memory makerFee, Fees memory fees)
        private
        pure
        returns (bool)
    {
        return
            makerFee.rate + fees.takerFee.rate + fees.protocolFee.rate <=
            10_000;
    }

    /**
     * @notice Verify EIP712 signature
     * @param signer Address of the alleged signer
     * @param hash EIP712 hash
     * @param signatures Packed bytes array of order signatures
     * @param index Index of the signature to verify
     * @return authorized Validity of the signature
     */
    function _verifyAuthorization(
        address signer,
        bytes32 hash,
        bytes memory signatures,
        uint256 index
    ) internal view returns (bool authorized) {
        bytes32 hashToSign = _hashToSign(hash);

        console.log("hash local");
        console.logBytes32(hash);

        console.log("hashToSign local");
        console.logBytes32(hashToSign);

        console.log("signature in local _verifyAuthorization");
        console.logBytes(signatures);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            let signatureOffset := add(
                add(signatures, One_word),
                mul(Signatures_size, index)
            )
            r := mload(signatureOffset)
            s := mload(add(signatureOffset, Signatures_s_offset))
            v := shr(
                Bytes1_shift,
                mload(add(signatureOffset, Signatures_v_offset))
            )
        }

        console.log("r");
        console.logBytes32(r);
        console.log("s");
        console.logBytes32(s);
        console.log("v");
        console.logUint(v);

        console.log("signer");
        console.logAddress(signer);

        authorized = _verify(signer, hashToSign, v, r, s);

        // console.log("authorized");
        // console.logBool(authorized);
    }

    /**
     * @notice Verify signature of digest
     * @param signer Address of expected signer
     * @param digest Signature digest
     * @param v v parameter
     * @param r r parameter
     * @param s s parameter
     */
    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool valid) {
        address recoveredSigner = ecrecover(digest, v, r, s);

        console.log("recoveredSigner");
        console.logAddress(recoveredSigner);

        console.log("signer");
        console.logAddress(signer);

        if (recoveredSigner != address(0) && recoveredSigner == signer) {
            valid = true;
        }
    }

    function _validateOrder(
        Order memory order,
        OrderType orderType,
        bytes memory signatures,
        Fees memory fees,
        uint256 signatureIndex
    ) internal view returns (bool) {
        bytes32 orderHash = blur.hashOrder(order, orderType);

        // console.log("signature in _validateOrder");
        // console.logBytes(signatures);

        console.log("orderHash local");
        console.logBytes32(orderHash);

        /* After hashing, the salt is no longer needed so we can store the order hash here. */
        order.salt = uint256(orderHash);

        console.log("CALLING _verifyAuthorization");

        // if (
        //     !_verifyAuthorization(
        //         order.trader,
        //         orderHash,
        //         signatures,
        //         signatureIndex
        //     )
        // ) {
        //     // console.log("order.trader");
        //     // console.log(order.trader);
        //     // console.log("orderHash");
        //     // console.logBytes32(orderHash);
        //     // console.log("signatures");
        //     // console.logBytes(signatures);
        //     // console.log("signatureIndex");
        //     // console.log(signatureIndex);
        //     // console.log("_verifyAuthorization FAILED");
        //     revert('AUTH ISSUE');
        // }

        return
            _verifyAuthorization(
                order.trader,
                orderHash,
                signatures,
                signatureIndex
            ) &&
            _checkLiveness(order) &&
            _checkFee(order.makerFee, fees);
    }

    /**
     * @notice Validate both the listing and it's parent order (only for single executions)
     * @param order Order of the listing
     * @param orderType Order type
     * @param exchange Exchange containing the listing
     * @param signature Order signature
     * @param fees Protocol and taker fee rates
     * @return Validity of the order and listing
     */
    function _validateOrderAndListing(
        Order memory order,
        OrderType orderType,
        Exchange memory exchange,
        bytes memory signature,
        Fees memory fees
    ) internal view returns (bool) {
        console.log("=====================================================");
        console.log("LOCAL");

        console.log("orderType");
        console.logUint(uint256(orderType));

        console.log("order.trader");
        console.logAddress(order.trader);

        console.log("order.collection");
        console.logAddress(order.collection);

        console.log("order.listingsRoot");
        console.logBytes32(order.listingsRoot);

        console.log("order.numberOfListings");
        console.logUint(order.numberOfListings);

        console.log("order.salt");
        console.logUint(order.salt);

        console.log("order.expirationTime");
        console.logUint(order.expirationTime);

        console.log("order.assetType");
        console.logUint(uint256(order.assetType));

        console.log("order.makerFee.rate");
        console.logUint(order.makerFee.rate);

        console.log("order.makerFee.basisPoints");
        console.logUint(order.makerFee.rate);

        Listing memory listing = exchange.listing;
        // uint256 listingIndex = listing.index;

        // console.log("signature in _validateOrderAndListing");
        // console.logBytes(signature);

        // if (!_validateOrder(order, orderType, signature, fees, 0)) {
        //     // console.log("Order validation failed");
        //     revert();
        // }

        if (!_validateListing(order, orderType, exchange)) {
            // console.log("Listing validation failed");
            revert();
        }

        if (!(exchange.taker.amount <= listing.amount)) {
            console.log("Taker amount exceeds listing amount");
            revert("Taker amount exceeds listing amount");
        }

        return
            _validateOrder(order, orderType, signature, fees, 0) &&
            _validateListing(order, orderType, exchange);
        // // &&
        //  amountTaken[order.trader][bytes32(order.salt)][listingIndex] + exchange.taker.amount <=
        // listing.amount;
    }

    /**
     * @notice Validate a listing and its proposed exchange
     * @param order Order of the listing
     * @param orderType Order type
     * @param exchange Exchange containing the listing
     * @return validListing Validity of the listing and its proposed exchange
     */
    function _validateListing(
        Order memory order,
        OrderType orderType,
        Exchange memory exchange
    ) private pure returns (bool validListing) {
        Listing memory listing = exchange.listing;
        validListing = MerkleProof.verify(
            exchange.proof,
            order.listingsRoot,
            blur.hashListing(listing)
        );
        Taker memory taker = exchange.taker;
        if (orderType == OrderType.ASK) {
            if (order.assetType == AssetType.ERC721) {
                validListing =
                    validListing &&
                    taker.amount == 1 &&
                    listing.amount == 1;
            }
            validListing = validListing && listing.tokenId == taker.tokenId;
        } else {
            if (order.assetType == AssetType.ERC721) {
                validListing = validListing && taker.amount == 1;
            } else {
                validListing = validListing && listing.tokenId == taker.tokenId;
            }
        }
    }

    struct BuildArgumentsInfra {
        Order order;
        Order[] orders;
        Exchange exchange;
        Exchange[] exchanges;
        FeeRate feeRate;
        bytes32 orderHash;
        bytes32 orderHashToSign;
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes orderSignature;
        bytes32 oracleHash;
    }

    // TAKE ASK SINGLE
    function buildArguments(
        TestOrderContext memory context,
        address nftToken,
        uint256 identifier,
        AssetType assetType,
        address, /* erc20Token */
        uint256 tokenAmount,
        FeeRate memory /* feeRate */
    )
        internal
        view
        returns (TakeAskSingle memory takeAskSingle, bytes memory signature)
    {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](0),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](0),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderHash: bytes32(0),
            orderHashToSign: bytes32(0),
            r: bytes32(0),
            s: bytes32(0),
            v: 0,
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        // Create the order.
        infra.order = buildOrder(
            context.offerer, // The seller of an NFT is the "trader" here.
            nftToken, // This is "collection" in Blur parlance.
            bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
            2, // Number of listings, 2 to make Murky happy.
            block.timestamp + 1000, // expirationTime
            assetType, // assetType
            buildFeeRate(address(0), 0), // feeRate
            gasleft() // salt
        );

        infra.exchange = buildExchange(
            0, // index
            new bytes32[](0), // proof (set below)
            buildListing(
                0, // index (presumably of the listing in the Order)
                identifier, // tokenId
                1, // amount
                tokenAmount // price
            ),
            buildTaker(
                identifier, // tokenId
                1 // amount
            )
        );

        // console.log("infra.exchange.proof.length");
        // console.logUint(infra.exchange.proof.length);

        // console.log("infra.exchange.proof");
        // console.logBytes32(infra.exchange.proof[0]);

        infra.exchanges = new Exchange[](1);
        infra.exchanges[0] = infra.exchange;

        infra.exchange.proof = buildProofArray(infra.exchanges, 0);
        infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

        // console.log("infra.order.listingsRoot");
        // console.logBytes32(infra.order.listingsRoot);

        // Sanity check that the merkle stuff is right.
        bool validListing = MerkleProof.verify(
            infra.exchange.proof,
            infra.order.listingsRoot,
            blur.hashListing(infra.exchange.listing)
        );

        if (!validListing) {
            // console.log("Invalid listing");
            revert("Invalid listing");
        }

        if (!_checkLiveness(infra.order)) {
            // console.log("Order is not live");
            revert("Order is not live");
        }

        if (
            !_checkFee(
                infra.order.makerFee,
                Fees(buildFeeRate(address(0), 0), buildFeeRate(address(0), 0))
            )
        ) {
            // console.log("Fees are invalid");
            revert("Fees are invalid");
        }

        {
            infra.orderHash = blur.hashOrder(infra.order, OrderType.ASK);

            infra.orderHashToSign = _hashToSign(infra.orderHash);

            (infra.v, infra.r, infra.s) = _sign(
                context.offerer,
                infra.orderHashToSign
            );

            // console.log("infra.r");
            // console.logBytes32(infra.r);

            // console.log("infra.s");
            // console.logBytes32(infra.s);

            // console.log("infra.v");
            // console.logUint(infra.v);

            infra.orderSignature = abi.encodePacked(infra.r, infra.s, infra.v);

            // console.log("infra.orderSignature");
            // console.logBytes(infra.orderSignature);
        }

        // console.log("infra.orderHashToSign");
        // console.logBytes32(infra.orderHashToSign);

        console.log("order.salt before");
        console.logUint(infra.order.salt);

        // if (
        //     !_validateOrderAndListing(
        //         infra.order,
        //         OrderType.ASK,
        //         infra.exchange,
        //         infra.orderSignature,
        //         Fees(buildFeeRate(address(0), 0), buildFeeRate(address(0), 0))
        //     )
        // ) {
        //     // console.log("Order and listing are invalid");
        //     revert("Order and listing are invalid");
        // } else {
        //     console.log('Passes the local version of _validateOrderAndListing');
        // }

        console.log("order.salt after");
        console.logUint(infra.order.salt);

        // infra.order.salt = 0;

        // struct TakeAskSingle {
        //     Order order;
        //     Exchange exchange;
        //     FeeRate takerFee;
        //     bytes signature;
        //     address tokenRecipient;
        // }

        takeAskSingle = TakeAskSingle({
            order: infra.order,
            exchange: infra.exchange,
            takerFee: infra.feeRate,
            signature: infra.orderSignature,
            tokenRecipient: context.fulfiller
        });

        {
            infra.oracleHash = blur.hashTakeAskSingle(
                takeAskSingle,
                context.fulfiller
            );

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeAskSingle, signature);
    }

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 nativeTokenAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeAskSingle memory takeAskSingle,
            bytes memory oracleSignature
        ) = buildArguments(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC721,
                address(0),
                nativeTokenAmount,
                buildFeeRate(address(0), 0)
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAskSingle.selector,
                takeAskSingle,
                oracleSignature
            )
        );
    }

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 memory nft,
        uint256 nativeTokenAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeAskSingle memory takeAskSingle,
            bytes memory oracleSignature
        ) = buildArguments(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC1155,
                address(0),
                nativeTokenAmount,
                buildFeeRate(address(0), 0)
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAskSingle.selector,
                takeAskSingle,
                oracleSignature
            )
        );
    }

    // It's not possible to purchase NFTs with tokens other than ETH, WETH, or
    // Blur's proprietary version of WETH.
    // See https://etherscan.io/address/0xb38827497daf7f28261910e33e22219de087c8f5#code#F1#L594.
    function getPayload_BuyOfferedERC721WithBETH(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        TestItem20 memory erc20
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        console.log("GENERATING INPUTS");
        (
            TakeAskSingle memory takeAskSingle,
            bytes memory oracleSignature
        ) = buildArguments(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC721,
                address(0),
                erc20.amount,
                buildFeeRate(address(0), 0)
            );
        console.log("GENERATED INPUTS");

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAskSinglePool.selector,
                takeAskSingle,
                oracleSignature,
                erc20.amount
            )
        );
    }

    // TAKE BID SINGLE
    function buildArguments(
        TestOrderContext memory context,
        address nftToken,
        uint256 identifier,
        AssetType assetType,
        uint256 tokenAmount
    )
        internal
        view
        returns (TakeBidSingle memory takeBidSingle, bytes memory signature)
    {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](0),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](0),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderHash: bytes32(0),
            orderHashToSign: bytes32(0),
            r: bytes32(0),
            s: bytes32(0),
            v: 0,
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        // Create the order.
        infra.order = buildOrder(
            context.offerer, // The seller of an NFT is the "trader" here.
            nftToken, // This is "collection" in Blur parlance.
            bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
            2, // Number of listings, 2 to make Murky happy.
            block.timestamp + 1000, // expirationTime
            assetType, // assetType
            buildFeeRate(address(0), 0), // feeRate
            gasleft() // salt
        );

        infra.exchange = buildExchange(
            0, // index
            new bytes32[](0), // proof (set below)
            buildListing(
                0, // index (presumably of the listing in the Order)
                identifier, // tokenId
                1, // amount
                tokenAmount // price
            ),
            buildTaker(
                identifier, // tokenId
                1 // amount
            )
        );

        infra.exchanges = new Exchange[](1);
        infra.exchanges[0] = infra.exchange;

        infra.exchange.proof = buildProofArray(infra.exchanges, 0);
        infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

        {
            infra.orderHash = blur.hashOrder(infra.order, OrderType.BID);

            infra.orderHashToSign = _hashToSign(infra.orderHash);

            (infra.v, infra.r, infra.s) = _sign(
                context.offerer,
                infra.orderHashToSign
            );

            infra.orderSignature = abi.encodePacked(infra.r, infra.s, infra.v);
        }

        takeBidSingle = TakeBidSingle({
            order: infra.order,
            exchange: infra.exchange,
            takerFee: infra.feeRate,
            signature: infra.orderSignature
        });

        {
            infra.oracleHash = blur.hashTakeBidSingle(
                takeBidSingle,
                context.fulfiller
            );

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeBidSingle, signature);
    }

    function getPayload_BuyOfferedBETHWithERC721(
        TestOrderContext calldata context,
        TestItem20 memory erc20,
        TestItem721 memory nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (
            TakeBidSingle memory takeBidSingle,
            bytes memory oracleSignature
        ) = buildArguments(
                context,
                nft.token,
                nft.identifier,
                AssetType.ERC721,
                erc20.amount
            );

        execution.executeOrder = TestCallParameters(
            address(blur),
            0,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeBidSingle.selector,
                takeBidSingle,
                oracleSignature
            )
        );
    }

    // TAKE ASK MULTIPLE INDIVIDUAL ORDERS
    function buildArguments(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        AssetType assetType,
        uint256[] memory tokenAmounts
    ) internal view returns (TakeAsk memory takeAsk, bytes memory signature) {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](1),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](nfts.length),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderHash: bytes32(0),
            orderHashToSign: bytes32(0),
            r: bytes32(0),
            s: bytes32(0),
            v: 0,
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        for (uint256 i; i < nfts.length; ++i) {
            // Create the order.
            infra.order = buildOrder(
                contexts[i].offerer, // The seller of an NFT is the "trader" here.
                nfts[i].token, // This is "collection" in Blur parlance.
                bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
                2, // Number of listings, 2 to make Murky happy.
                block.timestamp + 1000, // expirationTime
                assetType, // assetType
                buildFeeRate(address(0), 0), // feeRate
                gasleft() // salt
            );

            infra.exchange = buildExchange(
                i, // index
                new bytes32[](0), // proof (set below)
                buildListing(
                    0, // index (presumably of the listing in the Order)
                    nfts[i].identifier, // tokenId
                    1, // amount
                    tokenAmounts[i] // price
                ),
                buildTaker(
                    nfts[i].identifier, // tokenId
                    1 // amount
                )
            );

            infra.exchanges = new Exchange[](1);
            infra.exchanges[0] = infra.exchange;

            infra.exchange.proof = buildProofArray(infra.exchanges, 0);
            infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

            {
                infra.orderHash = blur.hashOrder(infra.order, OrderType.ASK);

                infra.orderHashToSign = _hashToSign(infra.orderHash);

                (infra.v, infra.r, infra.s) = _sign(
                    contexts[i].offerer,
                    infra.orderHashToSign
                );

                infra.orderSignature = abi.encodePacked(
                    infra.orderSignature,
                    infra.r,
                    infra.s,
                    infra.v
                );
            }

            infra.orders[i] = infra.order;
            infra.exchanges[i] = infra.exchange;
        }

        takeAsk = TakeAsk({
            orders: infra.orders,
            exchanges: infra.exchanges,
            takerFee: infra.feeRate,
            signatures: infra.orderSignature,
            tokenRecipient: contexts[0].fulfiller
        });

        {
            infra.oracleHash = blur.hashTakeAsk(takeAsk, contexts[0].fulfiller);

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeAsk, signature);
    }

    function getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
        TestOrderContext[] calldata contexts,
        TestItem721[] calldata nfts,
        uint256[] calldata nativeTokenAmounts
    ) external view override returns (TestOrderPayload memory execution) {
        if (contexts[0].listOnChain) {
            _notImplemented();
        }

        uint256 nativeTokenAmount;

        for (uint256 i; i < nativeTokenAmounts.length; ++i) {
            nativeTokenAmount += nativeTokenAmounts[i];
        }

        (TakeAsk memory takeAsk, bytes memory oracleSignature) = buildArguments(
            contexts,
            nfts,
            AssetType.ERC721,
            nativeTokenAmounts
        );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAsk.selector,
                takeAsk,
                oracleSignature
            )
        );
    }

    // TAKE ASK MULTIPLE 10 ORDERS IN ONE
    function buildArguments(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        AssetType assetType,
        uint256 tokenAmount
    ) internal view returns (TakeAsk memory takeAsk, bytes memory signature) {
        // Initialize an empty infra struct.
        BuildArgumentsInfra memory infra = BuildArgumentsInfra({
            order: Order({
                trader: address(0),
                collection: address(0),
                listingsRoot: bytes32(0),
                numberOfListings: 0,
                expirationTime: 0,
                assetType: assetType,
                makerFee: FeeRate(address(0), 0),
                salt: 0
            }),
            orders: new Order[](nfts.length),
            exchange: Exchange({
                index: 0,
                proof: new bytes32[](0),
                listing: Listing({ index: 0, tokenId: 0, amount: 0, price: 0 }),
                taker: Taker({ tokenId: 0, amount: 0 })
            }),
            exchanges: new Exchange[](nfts.length),
            feeRate: FeeRate({ recipient: address(0), rate: 0 }),
            orderHash: bytes32(0),
            orderHashToSign: bytes32(0),
            r: bytes32(0),
            s: bytes32(0),
            v: 0,
            orderSignature: new bytes(0),
            oracleHash: bytes32(0)
        });

        // Create the order.
        infra.order = buildOrder(
            context.offerer, // The seller of an NFT is the "trader" here.
            nfts[0].token, // This is "collection" in Blur parlance.
            bytes32(0), // Listings root (merkle tree root of hashed listings), set below.
            10, // Number of listings.
            block.timestamp + 1000, // expirationTime
            assetType, // assetType
            buildFeeRate(address(0), 0), // feeRate
            gasleft() // salt
        );

        for (uint256 i; i < nfts.length; ++i) {
            infra.exchange = buildExchange(
                0, // index of the order
                new bytes32[](0), // proof (set below)
                buildListing(
                    i, // index (presumably of the listing in the Order)
                    nfts[i].identifier, // tokenId
                    1, // amount
                    tokenAmount / nfts.length // price
                ),
                buildTaker(
                    nfts[i].identifier, // tokenId
                    1 // amount
                )
            );

            infra.exchanges[i] = infra.exchange;
        }

        for (uint256 i; i < nfts.length; ++i) {
            infra.exchanges[i].proof = buildProofArray(infra.exchanges, i);
        }

        infra.order.listingsRoot = buildListingsRoot(infra.exchanges);

        {
            infra.orderHash = blur.hashOrder(infra.order, OrderType.ASK);

            infra.orderHashToSign = _hashToSign(infra.orderHash);

            (infra.v, infra.r, infra.s) = _sign(
                context.offerer,
                infra.orderHashToSign
            );

            infra.orderSignature = abi.encodePacked(
                infra.orderSignature,
                infra.r,
                infra.s,
                infra.v
            );
        }

        infra.orders[0] = infra.order;

        takeAsk = TakeAsk({
            orders: infra.orders,
            exchanges: infra.exchanges,
            takerFee: infra.feeRate,
            signatures: infra.orderSignature,
            tokenRecipient: context.fulfiller
        });

        {
            infra.oracleHash = blur.hashTakeAsk(takeAsk, context.fulfiller);

            signature = oracleContract.produceOracleSignature(
                infra.oracleHash,
                uint32(block.number)
            );
        }

        return (takeAsk, signature);
    }

    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 nativeTokenAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        (TakeAsk memory takeAsk, bytes memory oracleSignature) = buildArguments(
            context,
            nfts,
            AssetType.ERC721,
            nativeTokenAmount
        );

        execution.executeOrder = TestCallParameters(
            address(blur),
            nativeTokenAmount,
            abi.encodeWithSelector(
                IBlurExchangeV2.takeAsk.selector,
                takeAsk,
                oracleSignature
            )
        );
    }
}
