// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
