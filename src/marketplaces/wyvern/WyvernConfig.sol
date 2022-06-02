// pragma solidity 0.8.14;

// contract WyvernConfig {
// 	address public constant marketplace = address(
// 		0x7f268357A8c2552623316e2562D90e642bB538E5
// 	);

// 	address public constant approvalTarget = address(
// 		0x37A7996aff29966c328494d07638C7d4A710f92D
// 	);

// 	/// Get whatever needs to be signed for the given test.
// 	function simpleSwapDigest() external view returns (
// 		bytes32 digest,
// 		bool use2098
// 	) {
//     	bytes32 orderHash = bytes32(0); // TODO

//     	bytes32 domainSeparator = bytes32(
//         	0x72982d92449bfb3d338412ce4738761aff47fb975ceb17a1bc3712ec716a5a68
//         );

//         digest = keccak256(
//         	abi.encodePacked(bytes2(0x1901), domainSeparator, orderHash)
//         );

//         use2098 = false;
// 	}

// 	/// Supply signature and translate into the call to make for the test.
// 	function simpleSwapPayload(bytes memory signature) external view returns (
// 		uint256 value,
// 		bytes memory callData
// 	) {
// 		// Derive and return the value and calldata required for the test.
// 		value = 0;

// 		// TODO
// 		bytes4 functionSelector = bytes4(0x12345678);
// 		uint256 arg1 = 69420;

// 		callData = abi.encodeWithSelector(
// 			functionSelector, arg1, signature
// 		);
// 	}
// }
