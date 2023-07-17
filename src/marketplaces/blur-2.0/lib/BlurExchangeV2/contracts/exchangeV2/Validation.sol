// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { MerkleProof } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import { Signatures } from "./Signatures.sol";
import { AssetType, Order, Exchange, Listing, OrderType, FeeRate, Fees, Taker } from "./lib/Structs.sol";
import { IValidation } from "./interfaces/IValidation.sol";

import "forge-std/console.sol";

abstract contract Validation is IValidation, Signatures {
    uint256 internal constant _BASIS_POINTS = 10_000;
    uint256 internal constant _MAX_PROTOCOL_FEE_RATE = 250;

    FeeRate public protocolFee;

    /* amountTaken[user][orderHash][listingIndex] */
    mapping(address => mapping(bytes32 => mapping(uint256 => uint256)))
        public amountTaken;

    constructor(address proxy) Signatures(proxy) {}

    /**
     * @notice Check if an order has expired
     * @param order Order to check liveness
     * @return Order is live
     */
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
            _BASIS_POINTS;
    }

    /**
     * @notice Validate a list of orders and prepare arrays for recording pending fulfillments
     * @param orders List of orders
     * @param orderType Order type for all orders
     * @param signatures Bytes array of the order signatures
     * @param fees Protocol and taker fee rates
     */
    function _validateOrders(
        Order[] memory orders,
        OrderType orderType,
        bytes memory signatures,
        Fees memory fees
    )
        internal
        view
        returns (
            bool[] memory validOrders,
            uint256[][] memory pendingAmountTaken
        )
    {
        uint256 ordersLength = orders.length;
        validOrders = new bool[](ordersLength);
        pendingAmountTaken = new uint256[][](ordersLength);
        for (uint256 i; i < ordersLength; ) {
            pendingAmountTaken[i] = new uint256[](orders[i].numberOfListings);
            validOrders[i] = _validateOrder(
                orders[i],
                orderType,
                signatures,
                fees,
                i
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Validate an order
     * @param order Order to validate
     * @param orderType Order type
     * @param signatures Bytes array of order signatures
     * @param fees Protocol and taker fee rates
     * @param signatureIndex Index of the order signature
     * @return Validity of the order
     */
    function _validateOrder(
        Order memory order,
        OrderType orderType,
        bytes memory signatures,
        Fees memory fees,
        uint256 signatureIndex
    ) internal view returns (bool) {
        bytes32 orderHash = hashOrder(order, orderType);

        // // console.log("orderHash in fake blur");
        // // console.logBytes32(orderHash);

        /* After hashing, the salt is no longer needed so we can store the order hash here. */
        order.salt = uint256(orderHash);

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
     * @notice Validate a listing (only valid if the order has be prevalidated)
     * @dev Validation can be manipulated by inputting the same order twice in the orders array,
     * which will effectively bypass the `pendingAmountTaken` check. There is a safety check at the
     * execution phase that will revert the transaction if this manipulation overdraws an order.
     * @param order Order of the listing
     * @param orderType Order type
     * @param exchange Exchange containing the listing
     * @param validOrders List indicated which orders were validated
     * @param pendingAmountTakenArrays Pending fulfillments from the current batch
     * @return validListing Validity of the listing
     */
    function _validateListingFromBatch(
        Order memory order,
        OrderType orderType,
        Exchange memory exchange,
        bool[] memory validOrders,
        uint256[][] memory pendingAmountTakenArrays
    ) internal view returns (bool validListing) {
        Listing memory listing = exchange.listing;
        uint256 listingIndex = listing.index;
        uint256 amountTakenTwo = amountTaken[order.trader][bytes32(order.salt)][
            listingIndex
        ];
        uint256 pendingAmountTaken = pendingAmountTakenArrays[exchange.index][
            listingIndex
        ];
        uint256 takerAmount = exchange.taker.amount;

        // console.log('validOrders[exchange.index]');
        // console.log(validOrders[exchange.index]);

        // console.log('pendingAmountTaken + takerAmount <= type(uint256).max - amountTakenTwo');
        // console.log(pendingAmountTaken + takerAmount <= type(uint256).max - amountTakenTwo);

        // console.log('amountTakenTwo + pendingAmountTaken + takerAmount <= listing.amount');
        // console.log(amountTakenTwo + pendingAmountTaken + takerAmount <= listing.amount);

        unchecked {
            validListing =
                validOrders[exchange.index] &&
                _validateListing(order, orderType, exchange) &&
                pendingAmountTaken + takerAmount <=
                type(uint256).max - amountTakenTwo &&
                amountTakenTwo + pendingAmountTaken + takerAmount <=
                listing.amount;
        }
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
    ) private view returns (bool validListing) {
        Listing memory listing = exchange.listing;
        validListing = MerkleProof.verify(
            exchange.proof,
            order.listingsRoot,
            hashListing(listing)
        );

        console.log("validListing merkle");
        console.log(validListing);

        validListing = true;

        Taker memory taker = exchange.taker;
        if (orderType == OrderType.ASK) {
            if (order.assetType == AssetType.ERC721) {
                validListing =
                    validListing &&
                    taker.amount == 1 &&
                    listing.amount == 1;
            }

            console.log("validListing asset type");
            console.log(validListing);

            validListing = validListing && listing.tokenId == taker.tokenId;

            console.log("validListing tokenId");
            console.log(validListing);
        } else {
            if (order.assetType == AssetType.ERC721) {
                validListing = validListing && taker.amount == 1;
            } else {
                validListing = validListing && listing.tokenId == taker.tokenId;
            }
        }
    }

    // struct Order {
    //     // Size: 0x100
    //     address trader; // 0x00
    //     address collection; // 0x20
    //     bytes32 listingsRoot; // 0x40
    //     uint256 numberOfListings; // 0x60
    //     uint256 expirationTime; // 0x80
    //     AssetType assetType; // 0xa0
    //     FeeRate makerFee; // 0xc0
    //     uint256 salt; // 0xe0
    // }

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
        // // console.log("=====================================================");
        // // console.log("BLUR");

        // // console.log("orderType");
        // // console.logUint(uint256(orderType));

        // // console.log("order.trader");
        // // console.logAddress(order.trader);

        // // console.log("order.collection");
        // // console.logAddress(order.collection);

        // // console.log("order.listingsRoot");
        // // console.logBytes32(order.listingsRoot);

        // // console.log("order.numberOfListings");
        // // console.logUint(order.numberOfListings);

        // // console.log("order.salt");
        // // console.logUint(order.salt);

        // // console.log("order.expirationTime");
        // // console.logUint(order.expirationTime);

        // // console.log("order.assetType");
        // // console.logUint(uint256(order.assetType));

        // // console.log("order.makerFee.rate");
        // // console.logUint(order.makerFee.rate);

        // // console.log("order.makerFee.basisPoints");
        // // console.logUint(order.makerFee.rate);

        Listing memory listing = exchange.listing;
        uint256 listingIndex = listing.index;
        return
            _validateOrder(order, orderType, signature, fees, 0) &&
            _validateListing(order, orderType, exchange) &&
            amountTaken[order.trader][bytes32(order.salt)][listingIndex] +
                exchange.taker.amount <=
            listing.amount;
    }

    uint256[49] private __gap;
}
