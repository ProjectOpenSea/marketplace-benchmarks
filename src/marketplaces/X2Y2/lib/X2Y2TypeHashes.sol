// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Market } from "../interfaces/MarketConstants.sol";
import { ECDSA } from "./ECDSA.sol";

contract X2Y2TypeHashes {
    function _deriveOrderDigest(Market.Order memory order)
        internal
        pure
        returns (bytes32)
    {
        bytes32 orderHash = keccak256(
            abi.encode(
                order.salt,
                order.user,
                order.network,
                order.intent,
                order.delegateType,
                order.deadline,
                order.currency,
                order.dataMask,
                order.items.length,
                order.items
            )
        );
        return ECDSA.toEthSignedMessageHash(orderHash);
    }

    function _deriveInputDigest(Market.RunInput memory input)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(input.shared, input.details.length, input.details)
            );
    }

    function _hashItem(Market.Order memory order, Market.OrderItem memory item)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    order.salt,
                    order.user,
                    order.network,
                    order.intent,
                    order.delegateType,
                    order.deadline,
                    order.currency,
                    order.dataMask,
                    item
                )
            );
    }
}
