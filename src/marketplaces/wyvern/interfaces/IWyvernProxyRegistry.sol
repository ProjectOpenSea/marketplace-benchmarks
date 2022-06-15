// SPDX-License-Identifier: MIT
pragma solidity >=0.4.13;

interface IWyvernProxyRegistry {
    function registerProxy() external returns (address);

    function proxies(address) external returns (address);
}
