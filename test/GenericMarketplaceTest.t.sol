// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { BaseMarketConfig } from "../src/BaseMarketConfig.sol";
import { BlurConfig } from "../src/marketplaces/blur/BlurConfig.sol";
import { BlurV2Config } from "../src/marketplaces/blur-2.0/BlurV2Config.sol";
import { FoundationConfig } from "../src/marketplaces/foundation/FoundationConfig.sol";
import { LooksRareConfig } from "../src/marketplaces/looksRare/LooksRareConfig.sol";
import { SeaportOnePointFiveConfig } from "../src/marketplaces/seaport-1.5/SeaportOnePointFiveConfig.sol";
import { LooksRareV2Config } from "../src/marketplaces/looksRare-v2/LooksRareV2Config.sol";
import { SeaportOnePointOneConfig } from "../src/marketplaces/seaport-1.1/SeaportOnePointOneConfig.sol";
import { SudoswapConfig } from "../src/marketplaces/sudoswap/SudoswapConfig.sol";
import { WyvernConfig } from "../src/marketplaces/wyvern/WyvernConfig.sol";
import { X2Y2Config } from "../src/marketplaces/X2Y2/X2Y2Config.sol";
import { ZeroExConfig } from "../src/marketplaces/zeroEx/ZeroExConfig.sol";

import { SetupCall, TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "../src/Types.sol";

import "./tokens/TestERC20.sol";
import "./tokens/TestERC721.sol";
import "./tokens/TestERC1155.sol";
import "./utils/BaseOrderTest.sol";

contract GenericMarketplaceTest is BaseOrderTest {
    BaseMarketConfig blurConfig;
    BaseMarketConfig blurV2Config;
    BaseMarketConfig foundationConfig;
    BaseMarketConfig looksRareConfig;
    BaseMarketConfig looksRareV2Config;
    BaseMarketConfig seaportOnePointOneConfig;
    BaseMarketConfig seaportOnePointFiveConfig;
    BaseMarketConfig sudoswapConfig;
    BaseMarketConfig wyvernConfig;
    BaseMarketConfig x2y2Config;
    BaseMarketConfig zeroExConfig;

    constructor() {
        blurConfig = BaseMarketConfig(new BlurConfig());
        blurV2Config = BaseMarketConfig(new BlurV2Config());
        foundationConfig = BaseMarketConfig(new FoundationConfig());
        looksRareConfig = BaseMarketConfig(new LooksRareConfig());
        looksRareV2Config = BaseMarketConfig(new LooksRareV2Config());
        seaportOnePointOneConfig = BaseMarketConfig(
            new SeaportOnePointOneConfig()
        );
        seaportOnePointFiveConfig = BaseMarketConfig(
            new SeaportOnePointFiveConfig()
        );
        sudoswapConfig = BaseMarketConfig(new SudoswapConfig());
        wyvernConfig = BaseMarketConfig(new WyvernConfig());
        x2y2Config = BaseMarketConfig(new X2Y2Config());
        zeroExConfig = BaseMarketConfig(new ZeroExConfig());
    }

    function testBlur() external {
        benchmarkMarket(blurConfig);
    }

    function testBlurV2() external {
        benchmarkMarket(blurV2Config);
    }

    function testFoundation() external {
        benchmarkMarket(foundationConfig);
    }

    function testLooksRare() external {
        benchmarkMarket(looksRareConfig);
    }

    function testLooksRareV2() external {
        benchmarkMarket(looksRareV2Config);
    }

    function testSeaportOnePointFive() external {
        benchmarkMarket(seaportOnePointFiveConfig);
    }

    function testSeaportOnePointOne() external {
        benchmarkMarket(seaportOnePointOneConfig);
    }

    function testSudoswap() external {
        benchmarkMarket(sudoswapConfig);
    }

    function testX2Y2() external {
        benchmarkMarket(x2y2Config);
    }

    function testZeroEx() external {
        benchmarkMarket(zeroExConfig);
    }

    // function testWyvern() external {
    //     benchmarkMarket(wyvernConfig);
    // }

    function benchmarkMarket(BaseMarketConfig config) public {
        beforeAllPrepareMarketplaceTest(config);
        benchmark_BuyOfferedERC721WithEther_ListOnChain(config);
        benchmark_BuyOfferedERC721WithEther(config);
        benchmark_BuyOfferedERC1155WithEther_ListOnChain(config);
        benchmark_BuyOfferedERC1155WithEther(config);
        benchmark_BuyOfferedERC721WithWETH_ListOnChain(config);
        benchmark_BuyOfferedERC721WithWETH(config);
        benchmark_BuyOfferedERC721WithERC20_ListOnChain(config);
        benchmark_BuyOfferedERC721WithERC20(config);
        benchmark_BuyOfferedERC721WithBETH(config);
        benchmark_BuyOfferedERC1155WithERC20_ListOnChain(config);
        benchmark_BuyOfferedERC1155WithERC20(config);
        benchmark_BuyOfferedERC20WithERC721_ListOnChain(config);
        benchmark_BuyOfferedERC20WithERC721(config);
        benchmark_BuyOfferedWETHWithERC721_ListOnChain(config);
        benchmark_BuyOfferedWETHWithERC721(config);
        benchmark_BuyOfferedBETHWithERC721(config);
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
        benchmark_BuyTenOfferedERC721WithEtherDistinctOrders_ListOnChain(
            config
        );
        benchmark_BuyTenOfferedERC721WithEtherDistinctOrders(config);
        benchmark_BuyTenOfferedERC721WithErc20DistinctOrders_ListOnChain(
            config
        );
        benchmark_BuyTenOfferedERC721WithErc20DistinctOrders(config);
        benchmark_BuyTenOfferedERC721WithWETHDistinctOrders_ListOnChain(config);
        benchmark_BuyTenOfferedERC721WithWETHDistinctOrders(config);
        benchmark_MatchOrders_ABCA(config);
    }

    function beforeAllPrepareMarketplaceTest(BaseMarketConfig config) internal {
        // Get requested call from marketplace. Needed by Wyvern to deploy proxy
        SetupCall[] memory setupCalls = config.beforeAllPrepareMarketplaceCall(
            alice,
            bob,
            erc20Addresses,
            erc721Addresses
        );
        for (uint256 i = 0; i < setupCalls.length; i++) {
            hevm.startPrank(setupCalls[i].sender);
            (bool success, ) = (setupCalls[i].target).call(setupCalls[i].data);
            if (!success) {
                emit log("");
            }
            hevm.stopPrank();
        }

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

            // Allow the market to escrow after listing
            assert(
                test721_1.ownerOf(1) == alice ||
                    test721_1.ownerOf(1) == config.market()
            );

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

            // Allow the market to escrow after listing
            assert(
                test721_1.ownerOf(1) == alice ||
                    test721_1.ownerOf(1) == config.market()
            );
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

    function benchmark_BuyOfferedERC721WithBETH(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 -> BETH)";
        test721_1.mint(alice, 1);
        hevm.deal(alice, 0);
        hevm.deal(bob, 100);
        hevm.prank(bob);
        beth.deposit{ value: 100 }();
        try
            config.getPayload_BuyOfferedERC721WithBETH(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(beth), 100)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(beth.balanceOf(alice), 0);
            assertEq(alice.balance, 0);
            assertEq(beth.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill, w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(alice.balance, 100);
            assertEq(beth.balanceOf(bob), 0);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithWETH_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721 -> WETH List-On-Chain)";
        test721_1.mint(alice, 1);
        hevm.deal(bob, 100);
        hevm.prank(bob);
        weth.deposit{ value: 100 }();
        try
            config.getPayload_BuyOfferedERC721WithERC20(
                TestOrderContext(true, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(weth), 100)
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            // Allow the market to escrow after listing
            assert(
                test721_1.ownerOf(1) == alice ||
                    test721_1.ownerOf(1) == config.market()
            );
            assertEq(weth.balanceOf(alice), 0);
            assertEq(weth.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(weth.balanceOf(alice), 100);
            assertEq(weth.balanceOf(bob), 0);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedERC721WithWETH(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 -> WETH)";
        test721_1.mint(alice, 1);
        hevm.deal(bob, 100);
        hevm.prank(bob);
        weth.deposit{ value: 100 }();

        try
            config.getPayload_BuyOfferedERC721WithWETH(
                TestOrderContext(false, alice, bob),
                TestItem721(address(test721_1), 1),
                TestItem20(address(weth), 100)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(weth.balanceOf(alice), 0);
            assertEq(weth.balanceOf(bob), 100);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill, w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(weth.balanceOf(alice), 100);
            assertEq(weth.balanceOf(bob), 0);
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
            // Allow the market to escrow after listing
            assert(
                token1.balanceOf(alice) == 100 ||
                    token1.balanceOf(config.market()) == 100
            );
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

    function benchmark_BuyOfferedWETHWithERC721_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(WETH -> ERC721 List-On-Chain)";
        hevm.deal(alice, 100);
        hevm.prank(alice);
        weth.deposit{ value: 100 }();
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedWETHWithERC721(
                TestOrderContext(true, alice, bob),
                TestItem20(address(weth), 100),
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
            // Allow the market to escrow after listing
            assert(
                weth.balanceOf(alice) == 100 ||
                    weth.balanceOf(config.market()) == 100
            );
            assertEq(weth.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(weth.balanceOf(alice), 0);
            assertEq(weth.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedWETHWithERC721(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(WETH -> ERC721)";
        hevm.deal(alice, 100);
        hevm.prank(alice);
        weth.deposit{ value: 100 }();
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedWETHWithERC721(
                TestOrderContext(false, alice, bob),
                TestItem20(address(weth), 100),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), bob);
            assertEq(weth.balanceOf(alice), 100);
            assertEq(weth.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(weth.balanceOf(alice), 0);
            assertEq(weth.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyOfferedBETHWithERC721(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(BETH -> ERC721)";
        hevm.deal(alice, 100);
        hevm.prank(alice);
        beth.deposit{ value: 100 }();
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedBETHWithERC721(
                TestOrderContext(false, alice, bob),
                TestItem20(address(beth), 100),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), bob);
            assertEq(beth.balanceOf(alice), 100);
            assertEq(beth.balanceOf(bob), 0);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(beth.balanceOf(alice), 0);
            assertEq(beth.balanceOf(bob), 100);
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
                500, // increased so that the fee recipient recieves 1%
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

            // Allow the market to escrow after listing
            assert(
                test721_1.ownerOf(1) == alice ||
                    test721_1.ownerOf(1) == config.market()
            );
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

            // Allow the market to escrow after listing
            assert(
                test721_1.ownerOf(1) == alice ||
                    test721_1.ownerOf(1) == config.market()
            );
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
                assertTrue(
                    test721_1.ownerOf(i + 1) == alice ||
                        test721_1.ownerOf(i + 1) == config.market(),
                    "Not owner"
                );
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

    function benchmark_BuyTenOfferedERC721WithEtherDistinctOrders(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721x10 -> ETH Distinct Orders)";

        TestOrderContext[] memory contexts = new TestOrderContext[](10);
        TestItem721[] memory nfts = new TestItem721[](10);
        uint256[] memory ethAmounts = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
            contexts[i] = TestOrderContext(false, alice, bob);
            ethAmounts[i] = 100 + i;
        }

        try
            config.getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
                contexts,
                nfts,
                ethAmounts
            )
        returns (TestOrderPayload memory payload) {
            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), alice);
            }

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill /w Sigs")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), bob);
            }
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithEtherDistinctOrders_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string
            memory testLabel = "(ERC721x10 -> ETH Distinct Orders List-On-Chain)";

        TestOrderContext[] memory contexts = new TestOrderContext[](10);
        TestItem721[] memory nfts = new TestItem721[](10);
        uint256[] memory ethAmounts = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
            contexts[i] = TestOrderContext(true, alice, bob);
            ethAmounts[i] = 100 + i;
        }

        try
            config.getPayload_BuyOfferedManyERC721WithEtherDistinctOrders(
                contexts,
                nfts,
                ethAmounts
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            // @dev checking ownership here (when nfts are escrowed in different contracts) is messy so we skip it for now

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), bob);
            }
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithErc20DistinctOrders(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721x10 -> ERC20 Distinct Orders)";

        token1.mint(bob, 1045);
        TestOrderContext[] memory contexts = new TestOrderContext[](10);
        TestItem721[] memory nfts = new TestItem721[](10);
        uint256[] memory erc20Amounts = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
            contexts[i] = TestOrderContext(false, alice, bob);
            erc20Amounts[i] = 100 + i;
        }

        try
            config.getPayload_BuyOfferedManyERC721WithErc20DistinctOrders(
                contexts,
                address(token1),
                nfts,
                erc20Amounts
            )
        returns (TestOrderPayload memory payload) {
            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), alice);
            }

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill /w Sigs")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), bob);
            }
            assertEq(token1.balanceOf(alice), 1045);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithErc20DistinctOrders_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string
            memory testLabel = "(ERC721x10 -> ERC20 Distinct Orders List-On-Chain)";

        token1.mint(bob, 1045);
        TestOrderContext[] memory contexts = new TestOrderContext[](10);
        TestItem721[] memory nfts = new TestItem721[](10);
        uint256[] memory erc20Amounts = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
            contexts[i] = TestOrderContext(true, alice, bob);
            erc20Amounts[i] = 100 + i;
        }

        try
            config.getPayload_BuyOfferedManyERC721WithErc20DistinctOrders(
                contexts,
                address(token1),
                nfts,
                erc20Amounts
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), bob);
            }
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithWETHDistinctOrders(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC721x10 -> WETH Distinct Orders)";

        hevm.deal(bob, 1045);
        hevm.prank(bob);
        weth.deposit{ value: 1045 }();
        TestOrderContext[] memory contexts = new TestOrderContext[](10);
        TestItem721[] memory nfts = new TestItem721[](10);
        uint256[] memory wethAmounts = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
            contexts[i] = TestOrderContext(false, alice, bob);
            wethAmounts[i] = 100 + i;
        }

        try
            config.getPayload_BuyOfferedManyERC721WithWETHDistinctOrders(
                contexts,
                address(weth),
                nfts,
                wethAmounts
            )
        returns (TestOrderPayload memory payload) {
            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), alice);
            }

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill /w Sigs")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), bob);
            }
            assertEq(weth.balanceOf(alice), 1045);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_BuyTenOfferedERC721WithWETHDistinctOrders_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string
            memory testLabel = "(ERC721x10 -> WETH Distinct Orders List-On-Chain)";

        hevm.deal(bob, 1045);
        hevm.prank(bob);
        weth.deposit{ value: 1045 }();
        TestOrderContext[] memory contexts = new TestOrderContext[](10);
        TestItem721[] memory nfts = new TestItem721[](10);
        uint256[] memory wethAmounts = new uint256[](10);

        for (uint256 i = 0; i < 10; i++) {
            test721_1.mint(alice, i + 1);
            nfts[i] = TestItem721(address(test721_1), i + 1);
            contexts[i] = TestOrderContext(true, alice, bob);
            wethAmounts[i] = 100 + i;
        }

        try
            config.getPayload_BuyOfferedManyERC721WithWETHDistinctOrders(
                contexts,
                address(weth),
                nfts,
                wethAmounts
            )
        returns (TestOrderPayload memory payload) {
            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            for (uint256 i = 1; i <= 10; i++) {
                assertEq(test721_1.ownerOf(i), bob);
            }
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    function benchmark_MatchOrders_ABCA(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC721 A -> B -> C -> A)";

        test721_1.mint(alice, 1);
        test721_1.mint(cal, 2);
        test721_1.mint(bob, 3);

        TestOrderContext[] memory contexts = new TestOrderContext[](3);
        TestItem721[] memory nfts = new TestItem721[](3);

        contexts[0] = TestOrderContext(false, alice, address(0));
        contexts[1] = TestOrderContext(false, cal, address(0));
        contexts[2] = TestOrderContext(false, bob, address(0));

        nfts[0] = TestItem721(address(test721_1), 1);
        nfts[1] = TestItem721(address(test721_1), 2);
        nfts[2] = TestItem721(address(test721_1), 3);

        try config.getPayload_MatchOrders_ABCA(contexts, nfts) returns (
            TestOrderPayload memory payload
        ) {
            assertEq(test721_1.ownerOf(1), alice);
            assertEq(test721_1.ownerOf(2), cal);
            assertEq(test721_1.ownerOf(3), bob);

            _benchmarkCallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill /w Sigs")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            assertEq(test721_1.ownerOf(2), alice);
            assertEq(test721_1.ownerOf(3), cal);
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
        require(
            config.sellerErc20ApprovalTarget() != address(0) &&
                config.sellerNftApprovalTarget() != address(0) &&
                config.buyerErc20ApprovalTarget() != address(0) &&
                config.buyerNftApprovalTarget() != address(0),
            "BaseMarketplaceTester::prepareTest: approval target not set"
        );
        _setApprovals(
            alice,
            config.sellerErc20ApprovalTarget(),
            config.sellerNftApprovalTarget(),
            config.sellerErc1155ApprovalTarget()
        );
        _setApprovals(
            cal,
            config.sellerErc20ApprovalTarget(),
            config.sellerNftApprovalTarget(),
            config.sellerErc1155ApprovalTarget()
        );
        _setApprovals(
            bob,
            config.buyerErc20ApprovalTarget(),
            config.buyerNftApprovalTarget(),
            config.buyerErc1155ApprovalTarget()
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
