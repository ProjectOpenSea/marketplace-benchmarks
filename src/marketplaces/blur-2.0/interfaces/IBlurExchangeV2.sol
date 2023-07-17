// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../lib/Structs.sol";

interface IBlurExchangeV2 {
    error InsufficientFunds();
    error TokenTransferFailed();
    error InvalidOrder();
    error ProtocolFeeTooHigh();

    event NewProtocolFee(address indexed recipient, uint16 indexed rate);
    event NewGovernor(address indexed governor);
    event NewBlockRange(uint256 blockRange);
    event CancelTrade(
        address indexed user,
        bytes32 hash,
        uint256 index,
        uint256 amount
    );
    event NonceIncremented(address indexed user, uint256 newNonce);
    event SetOracle(address indexed user, bool approved);

    function owner() external view returns (address);

    function hashListing(Listing memory listing)
        external
        pure
        returns (bytes32);

    function hashOrder(Order memory order, OrderType orderType)
        external
        view
        returns (bytes32);

    function hashTakeAsk(TakeAsk memory inputs, address _caller)
        external
        pure
        returns (bytes32);

    function hashTakeBid(TakeBid memory inputs, address _caller)
        external
        pure
        returns (bytes32);

    function hashTakeAskSingle(TakeAskSingle memory inputs, address _caller)
        external
        pure
        returns (bytes32);

    function hashTakeBidSingle(TakeBidSingle memory inputs, address _caller)
        external
        pure
        returns (bytes32);

    function initialize() external;

    function setProtocolFee(address recipient, uint16 rate) external;

    function setGovernor(address _governor) external;

    function setOracle(address oracle, bool approved) external;

    function setBlockRange(uint256 _blockRange) external;

    function incrementNonce() external;

    /*//////////////////////////////////////////////////////////////
                          EXECUTION WRAPPERS
    //////////////////////////////////////////////////////////////*/

    function takeAsk(TakeAsk memory inputs, bytes calldata oracleSignature)
        external
        payable;

    function takeBid(TakeBid memory inputs, bytes calldata oracleSignature)
        external;

    function takeAskSingle(
        TakeAskSingle memory inputs,
        bytes calldata oracleSignature
    ) external payable;

    function takeBidSingle(
        TakeBidSingle memory inputs,
        bytes calldata oracleSignature
    ) external;

    /*//////////////////////////////////////////////////////////////
                        EXECUTION POOL WRAPPERS
    //////////////////////////////////////////////////////////////*/

    function takeAskSinglePool(
        TakeAskSingle memory inputs,
        bytes calldata oracleSignature,
        uint256 amountToWithdraw
    ) external payable;

    function takeAskPool(
        TakeAsk memory inputs,
        bytes calldata oracleSignature,
        uint256 amountToWithdraw
    ) external payable;
}
