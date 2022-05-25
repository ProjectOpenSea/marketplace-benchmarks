// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ConsiderationStructs.sol";

contract ConsiderationTypeHashes {
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;

    constructor () {
        bytes memory offerItemTypeString = abi.encodePacked(
            "OfferItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount",
            ")"
        );

        // Construct the ConsiderationItem type string.
        // prettier-ignore
        bytes memory considerationItemTypeString = abi.encodePacked(
            "ConsiderationItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount,",
                "address recipient",
            ")"
        );

        // Construct the OrderComponents type string, not including the above.
        // prettier-ignore
        bytes memory orderComponentsPartialTypeString = abi.encodePacked(
            "OrderComponents(",
                "address offerer,",
                "address zone,",
                "OfferItem[] offer,",
                "ConsiderationItem[] consideration,",
                "uint8 orderType,",
                "uint256 startTime,",
                "uint256 endTime,",
                "bytes32 zoneHash,",
                "uint256 salt,",
                "bytes32 conduitKey,",
                "uint256 nonce",
            ")"
        );
        // Derive the OfferItem type hash using the corresponding type string.
        bytes32 offerItemTypehash = keccak256(offerItemTypeString);

        // Derive ConsiderationItem type hash using corresponding type string.
        bytes32 considerationItemTypehash = keccak256(considerationItemTypeString);

        _OFFER_ITEM_TYPEHASH = offerItemTypehash;
        _CONSIDERATION_ITEM_TYPEHASH = considerationItemTypehash;

        // Derive OrderItem type hash via combination of relevant type strings.
        _ORDER_TYPEHASH = keccak256(
            abi.encodePacked(
                orderComponentsPartialTypeString,
                considerationItemTypeString,
                offerItemTypeString
            )
        );
    }

        /**
     * @dev Internal view function to derive the EIP-712 hash for an offer item.
     *
     * @param offerItem The offered item to hash.
     *
     * @return The hash.
     */
    function _hashOfferItem(OfferItem memory offerItem)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _OFFER_ITEM_TYPEHASH,
                    offerItem.itemType,
                    offerItem.token,
                    offerItem.identifierOrCriteria,
                    offerItem.startAmount,
                    offerItem.endAmount
                )
            );
    }

    /**
     * @dev Internal view function to derive the EIP-712 hash for a consideration item.
     *
     * @param considerationItem The consideration item to hash.
     *
     * @return The hash.
     */
    function _hashConsiderationItem(ConsiderationItem memory considerationItem)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _CONSIDERATION_ITEM_TYPEHASH,
                    considerationItem.itemType,
                    considerationItem.token,
                    considerationItem.identifierOrCriteria,
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    considerationItem.recipient
                )
            );
    }

    /**
     * @dev Internal view function to derive the order hash for a given order.
     *      Note that only the original consideration items are included in the
     *      order hash, as additional consideration items may be supplied by the
     *      caller.
     *
     * @param orderParameters The parameters of the order to hash.
     * @param nonce           The nonce of the order to hash.
     *
     * @return orderHash The hash.
     */
    function _deriveOrderHash(
        OrderParameters memory orderParameters,
        uint256 nonce
    ) internal view returns (bytes32 orderHash) {
        // Designate new memory regions for offer and consideration item hashes.
        bytes32[] memory offerHashes = new bytes32[](
            orderParameters.offer.length
        );
        bytes32[] memory considerationHashes = new bytes32[](
            orderParameters.totalOriginalConsiderationItems
        );

        // Iterate over each offer on the order.
        for (uint256 i = 0; i < orderParameters.offer.length; ++i) {
            // Hash the offer and place the result into memory.
            offerHashes[i] = _hashOfferItem(orderParameters.offer[i]);
        }

        // Iterate over each consideration on the order.
        for (
            uint256 i = 0;
            i < orderParameters.totalOriginalConsiderationItems;
            ++i
        ) {
            // Hash the consideration and place the result into memory.
            considerationHashes[i] = _hashConsiderationItem(
                orderParameters.consideration[i]
            );
        }

        // Derive and return the order hash as specified by EIP-712.

        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    orderParameters.offerer,
                    orderParameters.zone,
                    keccak256(abi.encodePacked(offerHashes)),
                    keccak256(abi.encodePacked(considerationHashes)),
                    orderParameters.orderType,
                    orderParameters.startTime,
                    orderParameters.endTime,
                    orderParameters.zoneHash,
                    orderParameters.salt,
                    orderParameters.conduitKey,
                    nonce
                )
            );
    }
}