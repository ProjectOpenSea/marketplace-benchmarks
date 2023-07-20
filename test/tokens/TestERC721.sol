// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "solmate/tokens/ERC721.sol";
import "./ERC2981.sol";

contract TestERC721 is ERC721("Test721", "TST721"), ERC2981 {
    function mint(address to, uint256 tokenId) public returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }

    function setDefaultRoyaltyInfo(address receiver, uint96 feeNumerator)
        public
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
}
