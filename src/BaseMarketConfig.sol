// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "./Types.sol";

abstract contract BaseMarketConfig {
    ITestRunner private _tester;

    function name() external pure virtual returns (string memory);

    function market() public pure virtual returns (address);

    error NotImplemented();

    /**
     * @dev Revert if the type of requested order is impossible
     * to execute for a marketplace.
     */
    function _notImplemented() internal pure {
        revert NotImplemented();
    }

    constructor() {
        _tester = ITestRunner(msg.sender);
    }

    /**
     * @dev Request a signature from the testing contract.
     */
    function _sign(address signer, bytes32 digest)
        internal
        view
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        return _tester.signDigest(signer, digest);
    }

    /**
     * @dev Address that should be approved by buyer and seller.
     */
    address public nftApprovalTarget;

    address public erc20ApprovalTarget;

    function getUserSetupCalls(TestOrderContext calldata context)
        external
        view
        virtual
        returns (TestCallParameters[] memory)
    {}

    /**
     * @dev Any additional prep needed before benchmarking
     */
    function beforeAllPrepareMarketplaceCall(address seller, address buyer)
        external
        virtual
        returns (
            address,
            address,
            bytes memory
        )
    {
        return (address(0), address(0), "");
    }

    function beforeAllPrepareMarketplace(address seller, address buyer)
        external
        virtual
    {}

    /**
     * @dev Get call parameters to execute an order selling a 721 token for Ether.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nft Address and ID for ERC721 token to be sold.
     * @param ethAmount Amount of Ether to be received for the NFT.
     */
    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        uint256 ethAmount
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling an 1155 token for Ether.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nft Address, ID and amount for ERC1155 token to be sold.
     * @param ethAmount Amount of Ether to be received for the NFT.
     */
    function getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        uint256 ethAmount
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling a 721 token for an ERC20.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nft Address and ID of 721 token to be sold.
     * @param erc20 Address and amount for ERC20 to be received for nft.
     */
    function getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        TestItem20 calldata erc20
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling an 1155 token for an ERC20.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nft Address, ID and amount for ERC1155 token to be sold.
     * @param erc20 Address and amount for ERC20 to be received for nft.
     */
    function getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext calldata context,
        TestItem1155 calldata nft,
        TestItem20 calldata erc20
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling an ERC20 token for an ERC721.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param erc20 Address and amount for ERC20 to be sold.
     * @param nft Address and ID for 721 token to be received for ERC20.
     */
    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling an ERC20 token for an ERC1155.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param erc20 Address and amount for ERC20 to be sold.
     * @param nft Address, ID and amount for 1155 token to be received for ERC20.
     */
    function getPayload_BuyOfferedERC20WithERC1155(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem1155 calldata nft
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling an ERC721 token for an ERC1155.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param sellNft Address and ID of 721 token to be sold.
     * @param buyNft Address, ID and amount of 1155 token to be received for ERC721.
     */
    function getPayload_BuyOfferedERC721WithERC1155(
        TestOrderContext calldata context,
        TestItem721 calldata sellNft,
        TestItem1155 calldata buyNft
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }
}

interface ITestRunner {
    function signDigest(address signer, bytes32 digest)
        external
        view
        returns (
            uint8,
            bytes32,
            bytes32
        );
}
