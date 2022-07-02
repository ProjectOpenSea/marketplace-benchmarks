// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

struct TestItem721 {
    address token;
    uint256 identifier;
}

struct TestItem1155 {
    address token;
    uint256 identifier;
    uint256 amount;
}

struct TestItem20 {
    address token;
    uint256 amount;
}

struct TestCallParameters {
    address target;
    uint256 value;
    bytes data;
}

struct SetupCall {
    address sender;
    address target;
    bytes data;
}

struct TestOrderContext {
    bool listOnChain;
    address offerer;
    address fulfiller;
}

struct TestOrderPayload {
    // Call needed to submit order on-chain without signature
    TestCallParameters submitOrder;
    // Call needed to actually execute the order
    TestCallParameters executeOrder;
}
