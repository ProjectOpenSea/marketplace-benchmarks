// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";

import { SeaportConfig } from "../src/marketplaces/wyvern/SeaportConfig.sol";
import { WyvernConfig } from "../src/marketplaces/wyvern/WyvernConfig.sol";

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/tokens/ERC1155.sol";

interface Vm {
    function prank(address) external;
}

interface ConfigInterface {
    function marketplace() external view returns (address);
    function approvalTarget() external view returns (address);
    function simpleSwapPayload() external view returns (uint256 value, bytes memory callData);
}

contract TestERC20 is ERC20("Test20", "TST20", 18) {
    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }
}

contract TestERC721 is ERC721("Test721", "TST721") {
    function mint(address to, uint256 tokenId) public returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }
}

contract TestERC1155 is ERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public returns (bool) {
        _mint(to, tokenId, amount, "");
        return true;
    }

    function uri(uint256) public pure override returns (string memory) {
        return "uri";
    }
}

contract GenericMarketplaceTest is DSTestPlus {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Config seaport;
    Config wyvern;
    TestERC20 erc20;
    TestERC721 erc721;
    TestERC1155 erc1155;

    address constant seller = address(
        0x0734d56DA60852A03e2Aafae8a36FFd8c12B32f1
    );

    address constant buyer = address(
        0x939C8d89EBC11fA45e576215E2353673AD0bA18A
    );

    function setUp() public {
        seaport = Config(address(new SeaportConfig()));
        wyvern = Config(address(new WyvernConfig()));
        erc20 = new TestERC20();
        erc721 = new TestERC721();
        erc1155 = new TestERC1155();
    }

    function _prepareTest(
        Config target
    ) internal returns (address to, uint256 value, bytes memory callData) {
        uint256 tokenId = 100;

        erc721.mint(seller, tokenId);

        to = target.marketplace();

        address approvalTarget = target.approvalTarget();

        vm.prank(seller);
        erc721.setApprovalForAll(approvalTarget, true);

        (bytes32 payloadToSign, bool use2098) = target.supplyPayloadToSign();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _pkOfSigner,
            payloadToSign
        );

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
        (bool ok, ) = to.call{value}(callData);

        require(ok);
    }

    function testWyvern() public {
        (address to, bytes memory callData) = _prepareTest(wyvern);

        vm.prank(buyer);
        (bool ok, ) = to.call{value}(callData);

        require(ok);
    }
}