// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "./Types.sol";

abstract contract BaseMarketConfig {
    /**
     * @dev Market name used in results
     */
    function name() external pure virtual returns (string memory);

    function market() public pure virtual returns (address);

    /**
     * @dev Address that should be approved for nft tokens
     *   (ERC721 and ERC1155). Should be set during `beforeAllPrepareMarketplace`.
     */
    address public nftApprovalTarget;

    /**
     * @dev Address that should be approved for erc20 tokens.
     *   Should be set during `beforeAllPrepareMarketplace`.
     */
    address public erc20ApprovalTarget;

    /**
     * @dev Get calldata to call from test prior to starting tests
     *   (used by wyvern to create proxies)
     * @param seller The seller address used for testing the marketplace
     * @param buyer The buyer address used for testing the marketplace
     * @return From address, to address, and calldata
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

    /**
     * @dev Final setup prior to starting tests
     * @param seller The seller address used for testing the marketplace
     * @param buyer The buyer address used for testing the marketplace
     */
    function beforeAllPrepareMarketplace(address seller, address buyer)
        external
        virtual
    {}

    /*//////////////////////////////////////////////////////////////
                        Test Payload Calls
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get call parameters to execute an order selling a 721 token for Ether.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *   order should be listed on chain.
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

    /**
     * @dev Get call parameters to execute an order selling an ERC1155 token for an ERC721.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param sellNft Address and ID of 1155 token to be sold.
     * @param buyNft Address, ID and amount of 721 token to be received for ERC1155.
     */
    function getPayload_BuyOfferedERC1155WithERC721(
        TestOrderContext calldata context,
        TestItem1155 calldata sellNft,
        TestItem721 calldata buyNft
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling a 721 token for Ether with one fee recipient.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nft Address and ID for ERC721 token to be sold.
     * @param priceEthAmount Amount of Ether to be received for the NFT.
     * @param feeRecipient Address to send fee to.
     * @param feeEthAmount Amount of Ether to send for fee.
     */
    function getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient,
        uint256 feeEthAmount
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling a 721 token for Ether with two fee recipients.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nft Address and ID for ERC721 token to be sold.
     * @param priceEthAmount Amount of Ether to be received for the NFT.
     * @param feeRecipient1 Address to send first fee to.
     * @param feeEthAmount1 Amount of Ether to send for first fee.
     * @param feeRecipient2 Address to send second fee to.
     * @param feeEthAmount2 Amount of Ether to send for second fee.
     */
    function getPayload_BuyOfferedERC721WithEtherTwoFeeRecipient(
        TestOrderContext calldata context,
        TestItem721 memory nft,
        uint256 priceEthAmount,
        address feeRecipient1,
        uint256 feeEthAmount1,
        address feeRecipient2,
        uint256 feeEthAmount2
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling many 721 tokens for Ether.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nfts Array of Address and ID for ERC721 tokens to be sold.
     * @param ethAmount Amount of Ether to be received for the NFT.
     */
    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external view virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /*//////////////////////////////////////////////////////////////
                          Helpers
    //////////////////////////////////////////////////////////////*/
    ITestRunner private _tester;
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
