// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {WyvernConfig} from "../src/marketplaces/wyvern/WyvernConfig.sol";
import {SeaportConfig} from "../src/marketplaces/seaport/SeaportConfig.sol";
import {BaseMarketConfig} from "../src/BaseMarketConfig.sol";

import {TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155} from "../src/Types.sol";

import "./tokens/TestERC20.sol";
import "./tokens/TestERC721.sol";
import "./tokens/TestERC1155.sol";
import "./utils/BaseOrderTest.sol";
import "forge-std/console2.sol";

contract BaseMarketplaceTester is BaseOrderTest {
    BaseMarketConfig seaportConfig;
    BaseMarketConfig wyvernConfig;

    constructor() {
        seaportConfig = BaseMarketConfig(address(new SeaportConfig()));
        wyvernConfig = BaseMarketConfig(address(new WyvernConfig()));
    }

    function signDigest(address signer, bytes32 digest)
        external
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        (v, r, s) = hevm.sign(privateKeys[signer], digest);
    }

    function testSeaport() external {
        benchmarkMarket(seaportConfig);
    }

    function testWyvern() external {
        benchmarkMarket(wyvernConfig);
    }

    function benchmarkMarket(BaseMarketConfig config) public {
        beforeAllPrepareMarketplaceTest(config);
        benchmark_BuyOfferedERC721WithEther_ListOnChain(config);
        benchmark_BuyOfferedERC721WithEther(config);
        benchmark_BuyOfferedERC1155WithEther_ListOnChain(config);
        benchmark_BuyOfferedERC1155WithEther(config);
        benchmark_BuyOfferedERC721WithERC20_ListOnChain(config);
        benchmark_BuyOfferedERC721WithERC20(config);
        benchmark_BuyOfferedERC1155WithERC20_ListOnChain(config);
        benchmark_BuyOfferedERC1155WithERC20(config);

        // Disabled because Wyvern offers haven't been implemented yet
        // benchmark_BuyOfferedERC20WithERC721_ListOnChain(config);
        // benchmark_BuyOfferedERC20WithERC721(config);
        // benchmark_BuyOfferedERC20WithERC1155_ListOnChain(config);
        // benchmark_BuyOfferedERC20WithERC1155(config);
    }

    function setUp() public virtual override {
        super.setUp();
    }

    function concat(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory d) {
        d = string(abi.encodePacked(a, b, c));
    }

    function formatLog(string memory name, string memory label)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("[", name, "] ", label, " -- gas"));
    }

    function _benchmarkCallWithParams(
        string memory name,
        string memory label,
        address sender,
        TestCallParameters memory params
    ) internal {
        hevm.startPrank(sender);
        uint256 gasDelta;
        bool success;
        assembly {
            let to := mload(params)
            let value := mload(add(params, 0x20))
            let data := mload(add(params, 0x40))
            let ptr := add(data, 0x20)
            let len := mload(data)
            let g1 := gas()
            success := call(gas(), to, value, ptr, len, 0, 0)
            let g2 := gas()
            gasDelta := sub(g1, g2)
            if iszero(success) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        hevm.stopPrank();
        emit log_named_uint(formatLog(name, string(abi.encodePacked(label," (direct)"))), gasDelta);
        emit log_named_uint(formatLog(name, label), gasDelta + additionalGasFee(params.data));
    }

    function additionalGasFee(bytes memory callData) internal pure returns (uint256) {
        uint sum = 21000;

        for(uint i = 0; i < callData.length; i++) {
            // zero bytes = 4, non-zero = 16
            sum += callData[i] == 0 ? 4 : 16;
        }

        return sum - 2600; // Remove call opcode cost
    }

    function beforeAllPrepareMarketplaceTest(BaseMarketConfig config) internal {
        (address from, address target, bytes memory _calldata) = config.beforeAllPrepareMarketplaceCall(alice, bob);
        hevm.startPrank(from);
        target.call(_calldata);
        hevm.stopPrank();

        config.beforeAllPrepareMarketplace(alice, bob);
    }

    function prepareMarketplaceTest(BaseMarketConfig config)
        internal
        resetTokenBalancesBetweenRuns
    {
        _setApprovals(alice, config.erc20ApprovalTarget(), config.nftApprovalTarget());
        _setApprovals(bob, config.erc20ApprovalTarget(), config.nftApprovalTarget());
    }

    /*//////////////////////////////////////////////////////////////
                          BUY ERC721 WITH ETH
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC721WithEther_ListOnChain(
        BaseMarketConfig config
    ) internal {
        prepareMarketplaceTest(config);
        test721_1.mint(alice, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC721WithEther(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                100
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC721 -> ETH) List, on-chain",
            alice,
            payload.submitOrder
        );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC721 -> ETH) Fulfill, on-chain",
            bob,
            payload.executeOrder
        );
    }

    function benchmark_BuyOfferedERC721WithEther(BaseMarketConfig config)
        internal
    {
        prepareMarketplaceTest(config);
        test721_1.mint(alice, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC721WithEther(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                101
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC721 -> ETH) Fulfill, w/ signature",
            bob,
            payload.executeOrder
        );
    }

    /*//////////////////////////////////////////////////////////////
                          BUY ERC1155 WITH ETH
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC1155WithEther_ListOnChain(
        BaseMarketConfig config
    ) internal {
        prepareMarketplaceTest(config);
        test1155_1.mint(alice, 1, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC1155WithEther(
                TestOrderContext(true, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                100
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC1155 -> ETH) List, on-chain",
            alice,
            payload.submitOrder
        );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC1155 -> ETH) Fulfill, on-chain",
            bob,
            payload.executeOrder
        );
    }

    function benchmark_BuyOfferedERC1155WithEther(BaseMarketConfig config)
        internal
    {
        prepareMarketplaceTest(config);
        test1155_1.mint(alice, 1, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC1155WithEther(
                TestOrderContext(false, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                101
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC1155 -> ETH) Fulfill, w/ signature",
            bob,
            payload.executeOrder
        );
    }

    /*//////////////////////////////////////////////////////////////
                          BUY ERC721 WITH ERC20
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC721WithERC20_ListOnChain(
        BaseMarketConfig config
    ) internal {
        prepareMarketplaceTest(config);
        test721_1.mint(alice, 1);
        token1.mint(bob, 100);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC721WithERC20(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(token1), 100)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC721 -> ERC20) List, on-chain",
            alice,
            payload.submitOrder
        );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC721 -> ERC20) Fulfill, on-chain",
            bob,
            payload.executeOrder
        );
    }

    function benchmark_BuyOfferedERC721WithERC20(BaseMarketConfig config)
        internal
    {
        prepareMarketplaceTest(config);
        test721_1.mint(alice, 1);
        token1.mint(bob, 101);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC721WithERC20(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(token1), 101)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC721 -> ERC20) Fulfill, w/ signature",
            bob,
            payload.executeOrder
        );
    }

    /*//////////////////////////////////////////////////////////////
                          BUY ERC1155 WITH ERC20
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC1155WithERC20_ListOnChain(
        BaseMarketConfig config
    ) internal {
        prepareMarketplaceTest(config);
        test1155_1.mint(alice, 1, 1);
        token1.mint(bob, 100);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC1155WithERC20(
                TestOrderContext(true, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                TestItem20(address(token1), 100)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC1155 -> ERC20) List, on-chain",
            alice,
            payload.submitOrder
        );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC1155 -> ERC20) Fulfill, on-chain",
            bob,
            payload.executeOrder
        );
    }

    function benchmark_BuyOfferedERC1155WithERC20(BaseMarketConfig config)
        internal
    {
        prepareMarketplaceTest(config);
        test1155_1.mint(alice, 1, 1);
        token1.mint(bob, 101);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC1155WithERC20(
                TestOrderContext(false, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                TestItem20(address(token1), 101)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC1155 -> ERC20) Fulfill, w/ signature",
            bob,
            payload.executeOrder
        );
    }

    /*//////////////////////////////////////////////////////////////
                          BUY ERC20 WITH ERC721
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC20WithERC721_ListOnChain(
        BaseMarketConfig config
    ) internal {
        prepareMarketplaceTest(config);
        token1.mint(alice, 100);
        test721_1.mint(bob, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC20WithERC721(
                TestOrderContext(true, alice, bob),
                TestItem20(address(token1), 100),
                TestItem721(address(test721_1), 1)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC20 -> ERC721) List, on-chain",
            alice,
            payload.submitOrder
        );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC20 -> ERC721) Fulfill, on-chain",
            bob,
            payload.executeOrder
        );
    }

    function benchmark_BuyOfferedERC20WithERC721(BaseMarketConfig config)
        internal
    {
        prepareMarketplaceTest(config);
        token1.mint(alice, 100);
        test721_1.mint(bob, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC20WithERC721(
                TestOrderContext(false, alice, bob),
                TestItem20(address(token1), 100),
                TestItem721(address(test721_1), 1)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC20 -> ERC721) Fulfill, w/ signature",
            bob,
            payload.executeOrder
        );
    }

    /*//////////////////////////////////////////////////////////////
                          BUY ERC20 WITH ERC1155
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC20WithERC1155_ListOnChain(
        BaseMarketConfig config
    ) internal {
        prepareMarketplaceTest(config);
        TestOrderContext memory context = TestOrderContext(true, alice, bob);
        token1.mint(alice, 100);
        test1155_1.mint(bob, 1, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC20WithERC1155(
                context,
                TestItem20(address(token1), 100),
                TestItem1155(address(test1155_1), 1, 1)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC20 -> ERC1155) List, on-chain",
            alice,
            payload.submitOrder
        );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC20 -> ERC1155) Fulfill, on-chain",
            bob,
            payload.executeOrder
        );
    }

    function benchmark_BuyOfferedERC20WithERC1155(BaseMarketConfig config)
        internal
    {
        prepareMarketplaceTest(config);
        TestOrderContext memory context = TestOrderContext(false, alice, bob);
        token1.mint(alice, 100);
        test1155_1.mint(bob, 1, 1);
        TestOrderPayload memory payload = config
            .getPayload_BuyOfferedERC20WithERC1155(
                context,
                TestItem20(address(token1), 100),
                TestItem1155(address(test1155_1), 1, 1)
            );
        _benchmarkCallWithParams(
            config.name(),
            "(ERC20 -> ERC1155) Fulfill, w/ signature",
            bob,
            payload.executeOrder
        );
    }
}
