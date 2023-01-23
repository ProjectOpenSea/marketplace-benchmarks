// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { TestERC20 } from "./TestERC20.sol";

contract WETH is TestERC20 {
    // uint8 public decimals = 18; might need to keep this, not sure.

    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    // mapping(address => uint) public override balanceOf;
    // mapping(address => mapping(address => uint)) public override allowance;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        address payable sender = payable(msg.sender);
        sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function approve(address guy, uint wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) public override returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
