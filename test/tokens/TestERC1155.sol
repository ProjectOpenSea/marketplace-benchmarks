// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "solmate/tokens/ERC1155.sol";

contract TestERC1155 is ERC1155 {
    function mint(address to, uint256 tokenId, uint256 amount)
        public
        returns (bool)
    {
        _mint(to, tokenId, amount, "");
        return true;
    }

    function uri(uint256) public pure override returns (string memory) {
        return "uri";
    }
}
