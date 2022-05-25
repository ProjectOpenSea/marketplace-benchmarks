pragma solidity 0.8.14;

contract SeaportConfig {
	address public constant marketplace = address(
		0x00000000006CEE72100D161c57ADA5Bb2be1CA79
	);

	address public constant approvalTarget = address(
		0x00000000006CEE72100D161c57ADA5Bb2be1CA79
	);

	/// Get whatever needs to be signed for the given test.
	function simpleSwapDigest() external view returns (
		bytes32 digest,
		bool use2098
	) {
    	bytes32 orderHash = bytes32(0); // TODO

    	bytes32 domainSeparator = bytes32(
        	0x0a8f10d275e6dd59030d0b1d6aa63bf27c249f4e420c727533c0f7f0f2e75261
        );

        digest = keccak256(
        	abi.encodePacked(bytes2(0x1901), domainSeparator, orderHash)
        );

        use2098 = true;
	}

	/// Supply signature and translate into the call to make for the test.
	function simpleSwapPayload(bytes memory signature) external view returns (
		uint256 value,
		bytes memory callData
	) {
		// Derive and return the value and calldata required for the test.
		value = 0;

		// TODO
		bytes4 functionSelector = bytes4(0x12345678);
		uint256 arg1 = 69420;

		callData = abi.encodeWithSelector(
			functionSelector, arg1, signature
		);
	}
}