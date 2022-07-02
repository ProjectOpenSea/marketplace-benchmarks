pragma solidity ^0.8.0;

interface IRouter {
    struct PairSwapSpecific {
        address pair;
        uint256[] nftIds;
    }

    function swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable returns (uint256 remainingValue);

    function swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 remainingValue);

    function swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    function depositNFTs(
        address _nft,
        uint256[] calldata ids,
        address recipient
    ) external;

    function depositNFTs(
        address _nft,
        uint256[] calldata ids,
        address[] calldata recipients
    ) external;
}
