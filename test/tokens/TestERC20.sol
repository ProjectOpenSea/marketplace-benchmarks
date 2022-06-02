// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "solmate/tokens/ERC20.sol";

contract TestERC20 is ERC20("Test20", "TST20", 18) {
    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }
}