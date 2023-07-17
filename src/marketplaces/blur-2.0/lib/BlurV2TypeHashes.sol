// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";

contract BlurV2TypeHashes {
    mapping(address => uint256) public nonces;

    // 0xdd526a4e59bb74d0e4e4ab849ded32647b3bcf1df3acc01f4c21e76a8018c7c9
    bytes32 public constant DOMAIN_SEPARATOR =
        0xdd526a4e59bb74d0e4e4ab849ded32647b3bcf1df3acc01f4c21e76a8018c7c9;
    // keccak256(
    //     abi.encode(
    //         keccak256(
    //             bytes(
    //                 "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract"
    //             )
    //         ),
    //         keccak256(bytes("Blur Exchange")),
    //         keccak256(bytes("1.0")),
    //         1,
    //         address(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5)
    //     )
    // );

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address trader,address collection,bytes32 listingsRoot,uint256 numberOfListings,uint256 expirationTime,uint8 assetType,FeeRate makerFee,uint256 salt,uint8 orderType,uint256 nonce)FeeRate(address recipient,uint16 rate)"
        );

    bytes32 FEE_TYPEHASH = keccak256("FeeRate(address recipient,uint16 rate)");

    // /**
    //  * @notice Create an EIP712 hash to sign
    //  * @param hash Primary EIP712 object hash
    //  * @return EIP712 hash
    //  */
    // function _hashToSign(bytes32 hash) private view returns (bytes32) {
    //     return keccak256(bytes.concat(bytes2(0x1901), _DOMAIN_SEPARATOR, hash));
    // }

    // /**
    //  * @notice Create a hash of TakeAsk calldata with an approved caller
    //  * @param inputs TakeAsk inputs
    //  * @param _caller Address approved to execute the calldata
    //  * @return Calldata hash
    //  */
    // function hashTakeAsk(TakeAsk memory inputs, address _caller) external pure returns (bytes32) {
    //     return _hashCalldata(_caller);
    // }

    // /**
    //  * @notice Create a hash of TakeBid calldata with an approved caller
    //  * @param inputs TakeBid inputs
    //  * @param _caller Address approved to execute the calldata
    //  * @return Calldata hash
    //  */
    // function hashTakeBid(TakeBid memory inputs, address _caller) external pure returns (bytes32) {
    //     return _hashCalldata(_caller);
    // }

    // /**
    //  * @notice Create a hash of TakeAskSingle calldata with an approved caller
    //  * @param inputs TakeAskSingle inputs
    //  * @param _caller Address approved to execute the calldata
    //  * @return Calldata hash
    //  */
    // function hashTakeAskSingle(
    //     TakeAskSingle memory inputs,
    //     address _caller
    // ) external pure returns (bytes32) {
    //     return _hashCalldata(_caller);
    // }

    // /**
    //  * @notice Create a hash of TakeBidSingle calldata with an approved caller
    //  * @param inputs TakeBidSingle inputs
    //  * @param _caller Address approved to execute the calldata
    //  * @return Calldata hash
    //  */
    // function hashTakeBidSingle(
    //     TakeBidSingle memory inputs,
    //     address _caller
    // ) external pure returns (bytes32) {
    //     return _hashCalldata(_caller);
    // }

    // /**
    //  * @notice Create an EIP712 hash of an Order
    //  * @dev Includes two additional parameters not in the struct (orderType, nonce)
    //  * @param order Order to hash
    //  * @param orderType OrderType of the Order
    //  * @return Order EIP712 hash
    //  */
    // function hashOrder(Order memory order, OrderType orderType) public view returns (bytes32) {
    //     return
    //         keccak256(
    //             abi.encode(
    //                 _ORDER_TYPEHASH,
    //                 order.trader,
    //                 order.collection,
    //                 order.listingsRoot,
    //                 order.numberOfListings,
    //                 order.expirationTime,
    //                 order.assetType,
    //                 _hashFeeRate(order.makerFee),
    //                 order.salt,
    //                 orderType,
    //                 nonces[order.trader]
    //             )
    //         );
    // }

    // /**
    //  * @notice Create a hash of a Listing struct
    //  * @param listing Listing to hash
    //  * @return Listing hash
    //  */
    // function hashListing(Listing memory listing) public pure returns (bytes32) {
    //     return keccak256(abi.encode(listing.index, listing.tokenId, listing.amount, listing.price));
    // }

    // /**
    //  * @notice Create a hash of calldata with an approved caller
    //  * @param _caller Address approved to execute the calldata
    //  * @return hash Calldata hash
    //  */
    // function _hashCalldata(address _caller) internal pure returns (bytes32 hash) {
    //     assembly {
    //         let nextPointer := mload(0x40)
    //         let size := add(sub(nextPointer, 0x80), 0x20)
    //         mstore(nextPointer, _caller)
    //         hash := keccak256(0x80, size)
    //     }
    // }

    /**
     * @notice Create an EIP712 domain separator
     * @param _eip712DomainTypehash Typehash of the EIP712Domain struct
     * @param nameHash Hash of the contract name
     * @param versionHash Hash of the version string
     * @param _proxy Address of the proxy this implementation will be behind
     * @return EIP712Domain hash
     */
    function _hashDomain(
        bytes32 _eip712DomainTypehash,
        bytes32 nameHash,
        bytes32 versionHash,
        address _proxy
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _eip712DomainTypehash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    _proxy
                )
            );
    }

    /**
     * @notice Create an EIP712 hash of an Order
     * @dev Includes two additional parameters not in the struct (orderType, nonce)
     * @param order Order to hash
     * @param orderType OrderType of the Order
     * @return Order EIP712 hash
     */
    function hashOrder(Order memory order, OrderType orderType)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.trader,
                    order.collection,
                    order.listingsRoot,
                    order.numberOfListings,
                    order.expirationTime,
                    order.assetType,
                    _hashFeeRate(order.makerFee),
                    order.salt,
                    orderType,
                    nonces[order.trader]
                )
            );
    }

    /**
     * @notice Create an EIP712 hash of a FeeRate struct
     * @param feeRate FeeRate to hash
     * @return FeeRate EIP712 hash
     */
    function _hashFeeRate(FeeRate memory feeRate)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(FEE_TYPEHASH, feeRate.recipient, feeRate.rate)
            );
    }
}
