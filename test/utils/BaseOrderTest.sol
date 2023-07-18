// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";
import { stdStorage, StdStorage } from "forge-std/Test.sol";
import { TestERC1155 } from "../tokens/TestERC1155.sol";
import { TestERC20 } from "../tokens/TestERC20.sol";
import { WETH } from "../tokens/WETH.sol";
import { TestERC721 } from "../tokens/TestERC721.sol";

contract BaseOrderTest is DSTestPlus {
    using stdStorage for StdStorage;

    StdStorage stdstore;

    uint256 constant MAX_INT = ~uint256(0);

    uint256 internal alicePk = 0xa11ce;
    uint256 internal bobPk = 0xb0b;
    uint256 internal calPk = 0xca1;
    uint256 internal feeReciever1Pk = 0xfee1;
    uint256 internal feeReciever2Pk = 0xfee2;
    address payable internal alice = payable(hevm.addr(alicePk));
    address payable internal bob = payable(hevm.addr(bobPk));
    address payable internal cal = payable(hevm.addr(calPk));
    address payable internal feeReciever1 = payable(hevm.addr(feeReciever1Pk));
    address payable internal feeReciever2 = payable(hevm.addr(feeReciever2Pk));

    TestERC20 internal token1;
    TestERC20 internal token2;
    TestERC20 internal token3;
    // TestERC20 internal weth;
    WETH internal constant weth =
        WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // TestERC20 internal beth
    WETH internal constant beth =
        WETH(0x0000000000A39bb272e79075ade125fd351887Ac);

    TestERC721 internal test721_1;
    TestERC721 internal test721_2;
    TestERC721 internal test721_3;

    TestERC1155 internal test1155_1;
    TestERC1155 internal test1155_2;
    TestERC1155 internal test1155_3;

    address[] allTokens;
    TestERC20[] erc20s;
    address[] erc20Addresses;
    TestERC721[] erc721s;
    address[] erc721Addresses;
    TestERC1155[] erc1155s;
    address[] accounts;
    mapping(address => uint256) internal privateKeys;

    mapping(bytes32 => bool) originalMarketWriteSlots;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    struct RestoreERC20Balance {
        address token;
        address who;
    }

    function setUp() public virtual {
        hevm.label(alice, "alice");
        hevm.label(bob, "bob");
        hevm.label(cal, "cal");
        hevm.label(address(this), "testContract");

        privateKeys[alice] = alicePk;
        privateKeys[bob] = bobPk;
        privateKeys[cal] = calPk;

        _deployTestTokenContracts();
        accounts = [alice, bob, cal, address(this)];
        erc20s = [token1, token2, token3];
        erc20Addresses = [
            address(token1),
            address(token2),
            address(token3),
            address(weth),
            address(beth)
        ];
        erc721s = [test721_1, test721_2, test721_3];
        erc721Addresses = [
            address(test721_1),
            address(test721_2),
            address(test721_3)
        ];
        erc1155s = [test1155_1, test1155_2, test1155_3];
        allTokens = [
            address(token1),
            address(token2),
            address(token3),
            address(weth),
            address(beth),
            address(test721_1),
            address(test721_2),
            address(test721_3),
            address(test1155_1),
            address(test1155_2),
            address(test1155_3)
        ];
    }

    /**
     * @dev deploy test token contracts
     */
    function _deployTestTokenContracts() internal {
        token1 = new TestERC20();
        token2 = new TestERC20();
        token3 = new TestERC20();
        test721_1 = new TestERC721();
        test721_2 = new TestERC721();
        test721_3 = new TestERC721();
        test1155_1 = new TestERC1155();
        test1155_2 = new TestERC1155();
        test1155_3 = new TestERC1155();
        hevm.label(address(token1), "token1");
        hevm.label(address(weth), "weth");
        hevm.label(address(beth), "beth");
        hevm.label(address(test721_1), "test721_1");
        hevm.label(address(test1155_1), "test1155_1");
        hevm.label(address(feeReciever1), "feeReciever1");
        hevm.label(address(feeReciever2), "feeReciever2");
    }

    function _setApprovals(
        address _owner,
        address _erc20Target,
        address _erc721Target,
        address _erc1155Target
    ) internal {
        hevm.startPrank(_owner);
        for (uint256 i = 0; i < erc20s.length; i++) {
            erc20s[i].approve(_erc20Target, MAX_INT);
        }
        weth.approve(_erc20Target, MAX_INT);
        for (uint256 i = 0; i < erc721s.length; i++) {
            erc721s[i].setApprovalForAll(_erc721Target, true);
        }
        for (uint256 i = 0; i < erc1155s.length; i++) {
            erc1155s[i].setApprovalForAll(
                _erc1155Target != address(0) ? _erc1155Target : _erc721Target,
                true
            );
        }

        hevm.stopPrank();
    }

    /**
     * @dev reset written token storage slots to 0 and reinitialize
     *      uint128(MAX_INT) erc20 balances for 3 test accounts and this.
     */
    function _resetStorageAndEth(address market) internal {
        _resetTokensStorage();
        _restoreEthBalances();
        _resetMarketStorage(market);
        hevm.record();
    }

    function _restoreEthBalances() internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            hevm.deal(accounts[i], uint128(MAX_INT));
        }
        hevm.deal(feeReciever1, 0);
        hevm.deal(feeReciever2, 0);
    }

    /**
     * @dev Reset market storage between runs to allow for duplicate orders
     */
    function _resetMarketStorage(address market) internal {
        if (!originalMarketWriteSlots[0]) {
            (, bytes32[] memory writeSlots1) = hevm.accesses(market);
            for (uint256 i = 0; i < writeSlots1.length; i++) {
                originalMarketWriteSlots[writeSlots1[i]] = true;
            }
            originalMarketWriteSlots[0] = true;
        }
        (, bytes32[] memory writeSlots) = hevm.accesses(market);
        for (uint256 i = 0; i < writeSlots.length; i++) {
            if (originalMarketWriteSlots[writeSlots[i]]) continue;

            hevm.store(market, writeSlots[i], bytes32(0));

            // Handle the Blur reentrancy guard.
            if (
                market == 0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5 &&
                writeSlots[i] == bytes32(uint256(0xfb))
            ) {
                hevm.store(market, writeSlots[i], bytes32(uint256(1)));
            }
        }
    }

    function _resetTokensStorage() internal {
        for (uint256 i = 0; i < allTokens.length; i++) {
            _resetStorage(allTokens[i]);
        }
    }

    /**
     * @dev reset all storage written at an address thus far to 0; will
     *      overwrite totalSupply()for ERC20s but that should be fine with the
     *      goal of resetting the balances and owners of tokens - but note:
     *      should be careful about approvals, etc
     *
     *      note: must be called in conjunction with vm.record()
     */
    function _resetStorage(address _addr) internal {
        (, bytes32[] memory writeSlots) = hevm.accesses(_addr);
        for (uint256 i = 0; i < writeSlots.length; i++) {
            hevm.store(_addr, writeSlots[i], bytes32(0));
        }
    }

    receive() external payable virtual {}
}
