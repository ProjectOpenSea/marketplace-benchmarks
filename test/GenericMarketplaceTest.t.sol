// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";
//import { WyvernConfig } from "../src/marketplaces/wyvern/WyvernConfig.sol";
import { BaseMarketConfig } from "../src/BaseMarketConfig.sol";

import { TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "../src/Types.sol";

import "./tokens/TestERC20.sol";
import "./tokens/TestERC721.sol";
import "./tokens/TestERC1155.sol";
import "./utils/BaseOrderTest.sol";

contract BaseMarketplaceTester is BaseOrderTest {
    function signDigest(address signer, bytes32 digest)
        external
        returns (bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(privateKeys[signer], digest);
        return abi.encodePacked(r, s, v);
    }

    function testBenchmarkMarket(BaseMarketConfig config) external {
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
    }

    function setUp() public virtual override {
        super.setUp();
    }

    function concat(
      string memory a,
      string memory b,
      string memory c
    ) internal view returns (string memory d) {
      d = string(abi.encodePacked(a, b, c));
    }

    function _benchmarkCallWithParams(
      string memory name,
      string memory label,
      address sender,
      TestCallParameters memory params
    )
    internal
    {
      hevm.startPrank(sender);
      uint256 gasDelta;
      assembly {
        let to := mload(params)
        let value := mload(add(params, 0x20))
        let data := mload(mload(add(params, 0x40)))
        let ptr := add(data, 0x20)
        let len := mload(data)
        let g1 := gas()
        let success := call(
          gas(),
          to,
          value,
          ptr,
          len,
          0,
          0
        )
        let g2 := gas()
        gasDelta := sub(g1, g2)
      }
      hevm.stopPrank();
      emit log_named_uint(concat(name, label, " Gas: "), gasDelta);
    }

    function prepareMarketplaceTest(
      BaseMarketConfig config
    ) internal resetTokenBalancesBetweenRuns {
      address target = config.approvalTarget();
      _setApprovals(alice, target);
      _setApprovals(bob, target);
    }

  /*//////////////////////////////////////////////////////////////
                          BUY ERC721 WITH ETH
    //////////////////////////////////////////////////////////////*/


    function benchmark_BuyOfferedERC721WithEther_ListOnChain(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      test721_1.mint(alice, 1);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC721WithEther(
        TestOrderContext(true, alice, bob),
        TestItem721(address(test721_1), 1),
        100
      );
      _benchmarkCallWithParams(
        config.name(),
        "List ERC721 -> ETH on-chain",
        alice,
        payload.submitOrder
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC721 -> ETH listed on-chain",
        bob,
        payload.submitOrder
      );
    }

    function benchmark_BuyOfferedERC721WithEther(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      test721_1.mint(alice, 1);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC721WithEther(
        TestOrderContext(false, alice, bob),
        TestItem721(address(test721_1), 1),
        100
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC721 -> ETH with signature",
        bob,
        payload.submitOrder
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
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext(false, alice, bob),
        TestItem1155(address(test1155_1), 1, 1),
        100
      );
      _benchmarkCallWithParams(
        config.name(),
        "List ERC1155 -> ETH on-chain",
        alice,
        payload.submitOrder
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC1155 -> ETH listed on-chain",
        bob,
        payload.submitOrder
      );
    }

    function benchmark_BuyOfferedERC1155WithEther(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      test1155_1.mint(alice, 1, 1);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC1155WithEther(
        TestOrderContext(false, alice, bob),
        TestItem1155(address(test1155_1), 1, 1),
        100
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC1155 -> ETH with signature",
        bob,
        payload.submitOrder
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
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext(true, alice, bob),
        TestItem721(address(test721_1), 1),
        TestItem20(address(token1), 100)
      );
      _benchmarkCallWithParams(
        config.name(),
        "List ERC721 -> ERC20 on-chain",
        alice,
        payload.submitOrder
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC721 -> ERC20 listed on-chain",
        bob,
        payload.submitOrder
      );
    }

    function benchmark_BuyOfferedERC721WithERC20(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      test721_1.mint(alice, 1);
      token1.mint(bob, 100);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC721WithERC20(
        TestOrderContext(false, alice, bob),
        TestItem721(address(test721_1), 1),
        TestItem20(address(token1), 100)
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC721 -> ERC20 with signature",
        bob,
        payload.submitOrder
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
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext(true, alice, bob),
        TestItem1155(address(test1155_1), 1, 1),
        TestItem20(address(token1), 100)
      );
      _benchmarkCallWithParams(
        config.name(),
        "List ERC1155 -> ERC20 on-chain",
        alice,
        payload.submitOrder
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC1155 -> ERC20 listed on-chain",
        bob,
        payload.submitOrder
      );
    }

    function benchmark_BuyOfferedERC1155WithERC20(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      test1155_1.mint(alice, 1, 1);
      token1.mint(bob, 100);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC1155WithERC20(
        TestOrderContext(false, alice, bob),
        TestItem1155(address(test1155_1), 1, 1),
        TestItem20(address(token1), 100)
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC1155 -> ERC20 with signature",
        bob,
        payload.submitOrder
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
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext(true, alice, bob),
        TestItem20(address(token1), 100),
        TestItem721(address(test721_1), 1)
      );
      _benchmarkCallWithParams(
        config.name(),
        "List ERC20 -> ERC721 on-chain",
        alice,
        payload.submitOrder
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC20 -> ERC721 listed on-chain",
        bob,
        payload.submitOrder
      );
    }

    function benchmark_BuyOfferedERC20WithERC721(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      token1.mint(alice, 100);
      test721_1.mint(bob, 1);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext(false, alice, bob),
        TestItem20(address(token1), 100),
        TestItem721(address(test721_1), 1)
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC20 -> ERC721 with signature",
        bob,
        payload.submitOrder
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
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC20WithERC1155(
        context,
        TestItem20(address(token1), 100),
        TestItem1155(address(test1155_1), 1, 1)
      );
      _benchmarkCallWithParams(
        config.name(),
        "List ERC20 -> ERC1155 on-chain",
        alice,
        payload.submitOrder
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC20 -> ERC1155 listed on-chain",
        bob,
        payload.submitOrder
      );
    }

    function benchmark_BuyOfferedERC20WithERC1155(
      BaseMarketConfig config
    ) internal {
      prepareMarketplaceTest(config);
      TestOrderContext memory context = TestOrderContext(false, alice, bob);
      token1.mint(alice, 100);
      test1155_1.mint(bob, 1, 1);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC20WithERC1155(
        context,
        TestItem20(address(token1), 100),
        TestItem1155(address(test1155_1), 1, 1)
      );
      _benchmarkCallWithParams(
        config.name(),
        "Execute ERC20 -> ERC1155 with signature",
        bob,
        payload.submitOrder
      );
    }
}

// contract GenericMarketplaceTest is DSTestPlus, BaseOrderTest {
//     Config seaport;
//     Config wyvern;
//     TestERC20 erc20;
//     TestERC721 erc721;
//     TestERC1155 erc1155;

//     function signDigest(address signer, bytes32 digest)
//         external
//         view
//         returns (bytes memory)
//     {
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(_pkOfSigner1s, payloadToSign);
//     }

//     function setUp() public virtual override {
//         super.setUp();
//         seaport = Config(address(new SeaportConfig()));
//     }



//     function _prepareTest(Config target)
//         internal
//         returns (
//             address to,
//             uint256 value,
//             bytes memory callData
//         )
//     {
//         uint256 tokenId = 100;

//         erc721.mint(seller, tokenId);

//         to = target.marketplace();

//         address approvalTarget = target.approvalTarget();

//         vm.prank(seller);
//         erc721.setApprovalForAll(approvalTarget, true);

//         (bytes32 payloadToSign, bool use2098) = target.supplyPayloadToSign();

//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(_pkOfSigner, payloadToSign);

//         bytes memory signature;
//         if (use2098) {
//             uint256 yParity;
//             if (v == 27) {
//                 yParity = 0;
//             } else {
//                 yParity = 1;
//             }
//             uint256 yParityAndS = (yParity << 255) | uint256(s);
//             signature = abi.encodePacked(r, yParityAndS);
//         } else {
//             signature = abi.encodePacked(r, s, v);
//         }

//         (value, callData) = target.simpleSwapPayload(signature);
//     }

//     function testSeaport() public {
//         (address to, bytes memory callData) = _prepareTest(seaport);

//         vm.prank(buyer);
//         (bool ok, ) = to.call{ value: value }(callData);

//         require(ok);
//     }

//     function testWyvern() public {
//         (address to, bytes memory callData) = _prepareTest(wyvern);

//         vm.prank(buyer);
//         (bool ok, ) = to.call{ value: value }(callData);

//         require(ok);
//     }
// }
