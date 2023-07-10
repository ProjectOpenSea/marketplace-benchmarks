// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

interface IAtomicizer {
    function atomicize(
        address[] calldata addrs,
        uint256[] calldata values,
        uint256[] calldata calldataLengths,
        bytes calldata calldatas
    ) external;
}
