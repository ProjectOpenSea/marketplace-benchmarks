/**
 *Submitted for verification at Etherscan.io on 2018-03-08
 */

pragma solidity >=0.4.13;

interface IAtomicizer {
    function atomicize(
        address[] calldata addrs,
        uint256[] calldata values,
        uint256[] calldata calldataLengths,
        bytes calldata calldatas
    ) external;
}
