// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "./Types.sol";

abstract contract BaseMarketConfig {
    ITestRunner private _tester;

    error NotImplemented();

    constructor() {
      _tester = ITestRunner(msg.sender);
    }

    function _sign(address signer, bytes32 digest) internal view returns (bytes memory) {
      return _tester.signDigest(signer, digest);
    }

    function approvalTarget() external view virtual returns (address);

    function getUserSetupCalls(TestOrderContext calldata context)
        external
        view
        virtual
        returns (TestCallParameters[] memory)
    {}

    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        uint256 ethAmount
    ) external view virtual returns (TestOrderPayload memory execution);

    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        uint256 ethAmount
    ) external view virtual returns (TestOrderPayload memory execution);

    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external view virtual returns (TestOrderPayload memory execution);

    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 calldata erc20
    ) external view virtual returns (TestOrderPayload memory execution);

    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view virtual returns (TestOrderPayload memory execution);

    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem1155 calldata nft
    ) external view virtual returns (TestOrderPayload memory execution);
}

interface ITestRunner {
    function signDigest(address signer, bytes32 digest)
        external
        view
        returns (bytes memory);
}
