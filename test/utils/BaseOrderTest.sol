// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import { DSTestPlus } from "@rari-capital/solmate/src/test/utils/DSTestPlus.sol";
import { stdStorage, StdStorage } from "forge-std/Test.sol";
import { TestERC1155 } from "../tokens/TestERC1155.sol";
import { TestERC20 } from "../tokens/TestERC20.sol";
import { TestERC721 } from "../tokens/TestERC721.sol";
import { ArithmeticUtil } from "./ArithmeticUtil.sol";

contract BaseOrderTest is DSTestPlus {
    using stdStorage for StdStorage;
    using ArithmeticUtil for uint256;
    using ArithmeticUtil for uint128;
    using ArithmeticUtil for uint120;

    uint256 constant MAX_INT = ~uint256(0);

    uint256 internal alicePk = 0xa11ce;
    uint256 internal bobPk = 0xb0b;
    uint256 internal calPk = 0xca1;
    address payable internal alice = payable(hevm.addr(alicePk));
    address payable internal bob = payable(hevm.addr(bobPk));
    address payable internal cal = payable(hevm.addr(calPk));

    TestERC20 internal token1;
    TestERC20 internal token2;
    TestERC20 internal token3;

    TestERC721 internal test721_1;
    TestERC721 internal test721_2;
    TestERC721 internal test721_3;

    TestERC1155 internal test1155_1;
    TestERC1155 internal test1155_2;
    TestERC1155 internal test1155_3;

    address[] allTokens;
    TestERC20[] erc20s;
    TestERC721[] erc721s;
    TestERC1155[] erc1155s;
    address[] accounts;
    mapping(address => uint256) internal privateKeys;

    uint256 internal globalTokenId;

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

    /**
    @dev top up eth of this contract to uint128(MAX_INT) to avoid fuzz failures
     */
    modifier topUp() {
        hevm.deal(address(this), uint128(MAX_INT));
        _;
    }

    /**
     * @dev hook to record storage writes and reset token balances in between differential runs
     */

    modifier resetTokenBalancesBetweenRuns() {
        _;
        _resetTokensAndEthForTestAccounts();
    }

    function setUp() public virtual override {
        super.setUp();

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
        erc721s = [test721_1, test721_2, test721_3];
        erc1155s = [test1155_1, test1155_2, test1155_3];
        allTokens = [
            address(token1),
            address(token2),
            address(token3),
            address(test721_1),
            address(test721_2),
            address(test721_3),
            address(test1155_1),
            address(test1155_2),
            address(test1155_3)
        ];

        // allocate funds and tokens to test addresses
        globalTokenId = 1;
    }

    /**
    @dev deploy test token contracts
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
        hevm.label(address(test721_1), "test721_1");
        hevm.label(address(test1155_1), "test1155_1");

        emit log("Deployed test token contracts");
    }

    function _setApprovals(address _owner, address _target) internal {
        hevm.startPrank(_owner);
        for (uint256 i = 0; i < erc20s.length; i++) {
            erc20s[i].approve(_target, MAX_INT);
        }
        for (uint256 i = 0; i < erc721s.length; i++) {
            erc721s[i].setApprovalForAll(_target, true);
        }
        for (uint256 i = 0; i < erc1155s.length; i++) {
            erc1155s[i].setApprovalForAll(_target, true);
        }

        hevm.stopPrank();
    }

    /**
     * @dev reset written token storage slots to 0 and reinitialize uint128(MAX_INT) erc20 balances for 3 test accounts and this
     */
    function _resetTokensAndEthForTestAccounts() internal {
        _resetTokensStorage();
        _restoreERC20Balances();
        _restoreEthBalances();
    }

    function _restoreEthBalances() internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            hevm.deal(accounts[i], uint128(MAX_INT));
        }
    }

    function _resetTokensStorage() internal {
        for (uint256 i = 0; i < allTokens.length; i++) {
            _resetStorage(allTokens[i]);
        }
    }

    /**
     * @dev restore erc20 balances for all accounts
     */
    function _restoreERC20Balances() internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            _restoreERC20BalancesForAddress(accounts[i]);
        }
    }

    /**
     * @dev restore all erc20 balances for a given address
     */
    function _restoreERC20BalancesForAddress(address _who) internal {
        for (uint256 i = 0; i < erc20s.length; i++) {
            _restoreERC20Balance(RestoreERC20Balance(address(erc20s[i]), _who));
        }
    }

    /**
     * @dev reset token balance for an address to uint128(MAX_INT)
     */
    function _restoreERC20Balance(
        RestoreERC20Balance memory restoreErc20Balance
    ) internal {
        stdstore
            .target(restoreErc20Balance.token)
            .sig("balanceOf(address)")
            .with_key(restoreErc20Balance.who)
            .checked_write(uint128(MAX_INT));
    }



    /**
     * @dev reset all storage written at an address thus far to 0; will overwrite totalSupply()for ERC20s but that should be fine
     *      with the goal of resetting the balances and owners of tokens - but note: should be careful about approvals, etc
     *
     *      note: must be called in conjunction with vm.record()
     */
    function _resetStorage(address _addr) internal {
        (, bytes32[] memory writeSlots) = vm.accesses(_addr);
        for (uint256 i = 0; i < writeSlots.length; i++) {
            vm.store(_addr, writeSlots[i], bytes32(0));
        }
    }

    receive() external payable virtual {}
}
