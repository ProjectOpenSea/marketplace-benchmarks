// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { DSTestPlus } from "@rari-capital/solmate/src/test/utils/DSTestPlus.sol";
import { WyvernConfig } from "../src/marketplaces/wyvern/WyvernConfig.sol";
import { BaseMarketConfig } from "../src/BaseMarketConfig.sol";

import { TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "../src/Types.sol";

import "./tokens/TestERC20.sol";
import "./tokens/TestERC721.sol";
import "./tokens/TestERC1155.sol";
import "./utils/BaseOrderTest.sol";

contract BaseMarketplaceTester is BaseOrderTest {
    function signDigest(address signer, bytes32 digest)
        external
        view
        returns (bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_pkOfSigner1s, payloadToSign);
        return abi.encodePacked(r, s, v);
    }

    function setUp() public virtual override {
        super.setUp();
    }

    function _callWithParams(
      string memory label,
      address sender,
      TestCallParameters memory params
    ) internal {
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
      emit log_named_uint(string(abi.encodePacked(label, " Gas")), gasDelta);
    }

    function prepareMarketplaceTest(
      BaseMarketConfig config
    ) internal {
      address target = config.approvalTarget();
      _setApprovals(alice, target);
      _setApprovals(bob, target);
    }

    // @todo move the approvals/minting logic into this contract
    // and only mint/approve needed tokens
    function benchmark_BuyOfferedERC721WithEther(
      BaseMarketConfig config
    )
      resetTokenBalancesBetweenRuns
    {
      prepareMarketplaceTest(config);
      TestOrderContext memory context = TestOrderContext(true, alice, bob);
      test1155_1.mint(alice, 1, 1);
      TestOrderPayload memory payload = config.getPayload_BuyOfferedERC1155WithERC20(
        context,
        TestItem1155(address(test1155_1), 1, 1),
        100
      );
      
    }
// getPayload_BuyOfferedERC1155WithEther
// getPayload_BuyOfferedERC721WithERC20
// getPayload_BuyOfferedERC1155WithERC20
// getPayload_BuyOfferedERC20WithERC721
// getPayload_BuyOfferedERC20WithERC1155
}

contract GenericMarketplaceTest is DSTestPlus, BaseOrderTest {
    Config seaport;
    Config wyvern;
    TestERC20 erc20;
    TestERC721 erc721;
    TestERC1155 erc1155;

    function signDigest(address signer, bytes32 digest)
        external
        view
        returns (bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_pkOfSigner1s, payloadToSign);
    }

    function setUp() public virtual override {
        super.setUp();
        seaport = Config(address(new SeaportConfig()));
    }



    function _prepareTest(Config target)
        internal
        returns (
            address to,
            uint256 value,
            bytes memory callData
        )
    {
        uint256 tokenId = 100;

        erc721.mint(seller, tokenId);

        to = target.marketplace();

        address approvalTarget = target.approvalTarget();

        vm.prank(seller);
        erc721.setApprovalForAll(approvalTarget, true);

        (bytes32 payloadToSign, bool use2098) = target.supplyPayloadToSign();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_pkOfSigner, payloadToSign);

        bytes memory signature;
        if (use2098) {
            uint256 yParity;
            if (v == 27) {
                yParity = 0;
            } else {
                yParity = 1;
            }
            uint256 yParityAndS = (yParity << 255) | uint256(s);
            signature = abi.encodePacked(r, yParityAndS);
        } else {
            signature = abi.encodePacked(r, s, v);
        }

        (value, callData) = target.simpleSwapPayload(signature);
    }

    function testSeaport() public {
        (address to, bytes memory callData) = _prepareTest(seaport);

        vm.prank(buyer);
        (bool ok, ) = to.call{ value: value }(callData);

        require(ok);
    }

    function testWyvern() public {
        (address to, bytes memory callData) = _prepareTest(wyvern);

        vm.prank(buyer);
        (bool ok, ) = to.call{ value: value }(callData);

        require(ok);
    }
}
