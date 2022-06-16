// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { WyvernConfig } from "../src/marketplaces/wyvern/WyvernConfig.sol";
import { SeaportConfig } from "../src/marketplaces/seaport/SeaportConfig.sol";
import { BaseMarketConfig } from "../src/BaseMarketConfig.sol";

import { TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "../src/Types.sol";

import "./tokens/TestERC20.sol";
import "./tokens/TestERC721.sol";
import "./tokens/TestERC1155.sol";
import "./utils/BaseOrderTest.sol";

contract BaseMarketplaceTester is BaseOrderTest {
    BaseMarketConfig seaportConfig;
    BaseMarketConfig wyvernConfig;

    constructor() {
        seaportConfig = BaseMarketConfig(new SeaportConfig());
        wyvernConfig = BaseMarketConfig(new WyvernConfig());
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
        benchmark_BuyOfferedERC20WithERC721_ListOnChain(config);
        benchmark_BuyOfferedERC20WithERC721(config);
        benchmark_BuyOfferedERC20WithERC1155_ListOnChain(config);
        benchmark_BuyOfferedERC20WithERC1155(config);
        benchmark_BuyOfferedERC721WithERC1155_ListOnChain(config);
        benchmark_BuyOfferedERC721WithERC1155(config);
        benchmark_BuyOfferedERC1155WithERC721_ListOnChain(config);
        benchmark_BuyOfferedERC1155WithERC721(config);
        benchmark_BuyOfferedERC721WithEtherFee_ListOnChain(config);
        benchmark_BuyOfferedERC721WithEtherFee(config);
        benchmark_BuyOfferedERC721WithEtherFeeTwoRecipients_ListOnChain(config);
        benchmark_BuyOfferedERC721WithEtherFeeTwoRecipients(config);
        benchmark_BuyTenOfferedERC721WithEther_ListOnChain(config);
        benchmark_BuyTenOfferedERC721WithEther(config);
    }

    function beforeAllPrepareMarketplaceTest(BaseMarketConfig config) internal {
        // Get requested call from marketplace. Needed by Wyvern to deploy proxy
        (address from, address target, bytes memory _calldata) = config
            .beforeAllPrepareMarketplaceCall(alice, bob);
        hevm.startPrank(from);
        target.call(_calldata);
        hevm.stopPrank();

        // Do any final setup within config
        config.beforeAllPrepareMarketplace(alice, bob);
    }

    /*//////////////////////////////////////////////////////////////
                        Tests
    //////////////////////////////////////////////////////////////*/

    function benchmark_BuyOfferedERC721WithEther_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721 -> ETH List-On-Chain)";
        test721_1.mint(alice, 1);
        try
            config.getPayload_BuyOfferedERC721WithEther(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                100
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), alice);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithEther(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 -> ETH)";
        test721_1.mint(alice, 1);
        try
            config.getPayload_BuyOfferedERC721WithEther(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                100
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill, w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC1155WithEther_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC1155 -> ETH List-On-Chain)";
        test1155_1.mint(alice, 1, 1);
        try
            config.getPayload_BuyOfferedERC1155WithEther(
                TestOrderContext(true, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                100
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test1155_1.balanceOf(alice, 1), 1);
            assertEq(test1155_1.balanceOf(bob, 1), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test1155_1.balanceOf(alice, 1), 0);
            assertEq(test1155_1.balanceOf(bob, 1), 1);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC1155WithEther(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC1155 -> ETH)";
        test1155_1.mint(alice, 1, 1);
        try
            config.getPayload_BuyOfferedERC1155WithEther(
                TestOrderContext(false, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                100
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test1155_1.balanceOf(alice, 1), 1);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill, w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test1155_1.balanceOf(bob, 1), 1);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithERC20_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721 -> ERC20 List-On-Chain)";
        test721_1.mint(alice, 1);
        token1.mint(bob, 100);
        try
            config.getPayload_BuyOfferedERC721WithERC20(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(token1), 100)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithERC20(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 -> ERC20)";
        test721_1.mint(alice, 1);
        token1.mint(bob, 100);
        try
            config.getPayload_BuyOfferedERC721WithERC20(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(token1), 100)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill, w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC1155WithERC20_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC1155 -> ERC20 List-On-Chain)";
        test1155_1.mint(alice, 1, 1);
        token1.mint(bob, 100);
        try
            config.getPayload_BuyOfferedERC1155WithERC20(
                TestOrderContext(true, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                TestItem20(address(token1), 100)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test1155_1.balanceOf(alice, 1), 1);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test1155_1.balanceOf(bob, 1), 1);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC1155WithERC20(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC1155 -> ERC20)";
        test1155_1.mint(alice, 1, 1);
        token1.mint(bob, 100);
        try
            config.getPayload_BuyOfferedERC1155WithERC20(
                TestOrderContext(false, alice, bob),
                TestItem1155(address(test1155_1), 1, 1),
                TestItem20(address(token1), 100)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test1155_1.balanceOf(alice, 1), 1);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test1155_1.balanceOf(bob, 1), 1);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC20WithERC721_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC20 -> ERC721 List-On-Chain)";
        token1.mint(alice, 100);
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedERC20WithERC721(
                TestOrderContext(true, alice, bob),
                TestItem20(address(token1), 100),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC20WithERC721(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC20 -> ERC721)";
        token1.mint(alice, 100);
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedERC20WithERC721(
                TestOrderContext(false, alice, bob),
                TestItem20(address(token1), 100),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), bob);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC20WithERC1155_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC20 -> ERC1155 List-On-Chain)";
        TestOrderContext memory context = TestOrderContext(true, alice, bob);
        token1.mint(alice, 100);
        test1155_1.mint(bob, 1, 1);
        try
            config.getPayload_BuyOfferedERC20WithERC1155(
                context,
                TestItem20(address(token1), 100),
                TestItem1155(address(test1155_1), 1, 1)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test1155_1.balanceOf(bob, 1), 1);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test1155_1.balanceOf(alice, 1), 1);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC20WithERC1155(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC20 -> ERC1155)";
        TestOrderContext memory context = TestOrderContext(false, alice, bob);
        token1.mint(alice, 100);
        test1155_1.mint(bob, 1, 1);
        try
            config.getPayload_BuyOfferedERC20WithERC1155(
                context,
                TestItem20(address(token1), 100),
                TestItem1155(address(test1155_1), 1, 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test1155_1.balanceOf(bob, 1), 1);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test1155_1.balanceOf(alice, 1), 1);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithERC1155_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721 -> ERC1155 List-On-Chain)";
        TestOrderContext memory context = TestOrderContext(true, alice, bob);
        test721_1.mint(alice, 1);
        test1155_1.mint(bob, 1, 1);
        try
            config.getPayload_BuyOfferedERC721WithERC1155(
                context,
                TestItem721(address(test721_1), 1),
                TestItem1155(address(test1155_1), 1, 1)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(test1155_1.balanceOf(bob, 1), 1);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(test1155_1.balanceOf(alice, 1), 1);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithERC1155(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 -> ERC1155)";
        TestOrderContext memory context = TestOrderContext(false, alice, bob);
        test721_1.mint(alice, 1);
        test1155_1.mint(bob, 1, 1);
        try
            config.getPayload_BuyOfferedERC721WithERC1155(
                context,
                TestItem721(address(test721_1), 1),
                TestItem1155(address(test1155_1), 1, 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(test1155_1.balanceOf(bob, 1), 1);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(test1155_1.balanceOf(alice, 1), 1);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC1155WithERC721_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC1155 -> ERC721 List-On-Chain)";
        TestOrderContext memory context = TestOrderContext(true, alice, bob);
        test1155_1.mint(alice, 1, 1);
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedERC1155WithERC721(
                context,
                TestItem1155(address(test1155_1), 1, 1),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(test1155_1.balanceOf(alice, 1), 1);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(test1155_1.balanceOf(bob, 1), 1);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC1155WithERC721(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC1155 -> ERC721)";
        TestOrderContext memory context = TestOrderContext(false, alice, bob);
        test1155_1.mint(alice, 1, 1);
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedERC1155WithERC721(
                context,
                TestItem1155(address(test1155_1), 1, 1),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), bob);
            assertEq(test1155_1.balanceOf(alice, 1), 1);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(test1155_1.balanceOf(bob, 1), 1);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithEtherFee_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string
            memory testLabel = "(ERC721 -> ETH One-Fee-Recipient List-On-Chain)";
        test721_1.mint(alice, 1);
        try
            config.getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                100,
                feeReciever1,
                5
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(feeReciever1.balance, 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(feeReciever1.balance, 5);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithEtherFee(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 -> ETH One-Fee-Recipient)";
        test721_1.mint(alice, 1);
        try
            config.getPayload_BuyOfferedERC721WithEtherOneFeeRecipient(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                100,
                feeReciever1,
                5
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(feeReciever1.balance, 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(feeReciever1.balance, 5);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithEtherFeeTwoRecipients_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string
            memory testLabel = "(ERC721 -> ETH Two-Fee-Recipient List-On-Chain)";
        test721_1.mint(alice, 1);
        try
            config.getPayload_BuyOfferedERC721WithEtherTwoFeeRecipient(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                100,
                feeReciever1,
                5,
                feeReciever2,
                5
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(feeReciever1.balance, 0);
            assertEq(feeReciever2.balance, 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(feeReciever1.balance, 5);
            assertEq(feeReciever2.balance, 5);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithEtherFeeTwoRecipients(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721 -> ETH Two-Fee-Recipient)";
        test721_1.mint(alice, 1);
        try
            config.getPayload_BuyOfferedERC721WithEtherTwoFeeRecipient(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                100,
                feeReciever1,
                5,
                feeReciever2,
                5
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(feeReciever1.balance, 0);
            assertEq(feeReciever2.balance, 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fullfil /w Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(feeReciever1.balance, 5);
            assertEq(feeReciever2.balance, 5);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithEther_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721x10 -> ETH List-On-Chain)";

        TestItem721[] memory nfts = new TestItem721[](10);
        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
        }

        try
            config.getPayload_BuyOfferedManyERC721WithEther(
                TestOrderContext(true, alice, bob),
                nfts,
                100
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            for (uint256 i = 0; i < 10; i++) {
                assertEq(test721_1.ownerOf(i + 1), alice);
            }

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 0; i < 10; i++) {
                assertEq(test721_1.ownerOf(i + 1), bob);
            }
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithEther(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721x10 -> ETH)";

        TestItem721[] memory nfts = new TestItem721[](10);
        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
        }

        try
            config.getPayload_BuyOfferedManyERC721WithEther(
                TestOrderContext(false, alice, bob),
                nfts,
                100
            )
        returns (TestOrderPayload memory payload) {
            for (uint256 i = 0; i < 10; i++) {
                assertEq(test721_1.ownerOf(i + 1), alice);
            }

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill /w Sig")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 0; i < 10; i++) {
                assertEq(test721_1.ownerOf(i + 1), bob);
            }
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          Helpers
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
    }

    modifier prepareTest(BaseMarketConfig config) {
        _resetStorageAndEth(config.market());
        _setApprovals(
            alice,
            config.erc20ApprovalTarget(),
            config.nftApprovalTarget()
        );
        _setApprovals(
            bob,
            config.erc20ApprovalTarget(),
            config.nftApprovalTarget()
        );
        _;
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

    function _formatLog(string memory name, string memory label)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("[", name, "] ", label, " -- gas"));
    }

    function _logNotSupported(string memory name, string memory label)
        internal
    {
        emit log(
            string(
                abi.encodePacked("[", name, "] ", label, " -- NOT SUPPORTED")
            )
        );
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
        emit log_named_uint(
            _formatLog(name, string(abi.encodePacked(label, " (direct)"))),
            gasDelta
        );
        emit log_named_uint(
            _formatLog(name, label),
            gasDelta + _additionalGasFee(params.data)
        );
    }

    function _additionalGasFee(bytes memory callData)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 21000;
        for (uint256 i = 0; i < callData.length; i++) {
            // zero bytes = 4, non-zero = 16
            sum += callData[i] == 0 ? 4 : 16;
        }
        return sum - 2600; // Remove call opcode cost
    }
}
