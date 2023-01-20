// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OrderStructs.sol";

contract BlurTypeHashes {
    bytes32 public constant DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Blur Exchange"),
                keccak256("1.0"), // for versionId = 1
                1,
                0x000000000000Ad05Ccc4F10045630fb830B95127 // mainnet Blur exchange address
            )
        );

    // function _hashToSign(bytes32 orderHash)
    //     internal
    //     view
    //     returns (bytes32 hash)
    // {
    //     return keccak256(abi.encodePacked(
    //         "\x19\x01",
    //         DOMAIN_SEPARATOR,
    //         orderHash
    //     ));
    // }

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address trader,uint8 side,address matchingPolicy,address collection,uint256 tokenId,uint256 amount,address paymentToken,uint256 price,uint256 listingTime,uint256 expirationTime,Fee[] fees,uint256 salt,bytes extraParams,uint256 nonce)Fee(uint16 rate,address recipient)"
        );

    bytes32 public constant FEE_TYPEHASH =
        keccak256("Fee(uint16 rate,address recipient)");

    function _hashOrder(Order memory order, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        ORDER_TYPEHASH,
                        order.trader,
                        order.side,
                        order.matchingPolicy,
                        order.collection,
                        order.tokenId,
                        order.amount,
                        order.paymentToken,
                        order.price,
                        order.listingTime,
                        order.expirationTime,
                        _packFees(order.fees),
                        order.salt,
                        keccak256(order.extraParams)
                    ),
                    abi.encode(nonce)
                )
            );
    }

    function _packFees(Fee[] memory fees) internal pure returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function _hashFee(Fee memory fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    // function _deriveOrderDigest(
    //     Order memory order
    // ) internal pure returns (bytes32) {
    //     bytes32 orderHash = keccak256(
    //         abi.encode(
    //             order.trader,
    //             order.side,
    //             order.matchingPolicy,
    //             order.collection,
    //             order.tokenId,
    //             order.amount,
    //             order.paymentToken,
    //             order.price,
    //             order.listingTime,
    //             order.expirationTime,
    //             order.fees.length,
    //             order.fees,
    //             order.salt,
    //             order.extraParams
    //         )
    //     );
    //     return
    //         keccak256(
    //             abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)
    //         );
    // }
}
