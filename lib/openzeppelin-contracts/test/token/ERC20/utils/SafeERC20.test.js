const { constants, expectRevert } = require('@openzeppelin/test-helpers');

const SafeERC20 = artifacts.require('$SafeERC20');
const ERC20ReturnFalseMock = artifacts.require('ERC20ReturnFalseMock');
const ERC20ReturnTrueMock = artifacts.require('ERC20ReturnTrueMock');
const ERC20NoReturnMock = artifacts.require('ERC20NoReturnMock');
const ERC20PermitNoRevertMock = artifacts.require('ERC20PermitNoRevertMock');

const { getDomain, domainType, Permit } = require('../../../helpers/eip712');

const { fromRpcSig } = require('ethereumjs-util');
const ethSigUtil = require('eth-sig-util');
const Wallet = require('ethereumjs-wallet').default;

contract('SafeERC20', function (accounts) {
  const [hasNoCode] = accounts;

  before(async function () {
    this.mock = await SafeERC20.new();
  });

  describe('with address that has no contract code', function () {
    beforeEach(async function () {
      this.token = { address: hasNoCode };
    });

    shouldRevertOnAllCalls('Address: call to non-contract');
  });

  describe('with token that returns false on all calls', function () {
    beforeEach(async function () {
      this.token = await ERC20ReturnFalseMock.new();
    });

    shouldRevertOnAllCalls('SafeERC20: ERC20 operation did not succeed');
  });

  describe('with token that returns true on all calls', function () {
    beforeEach(async function () {
      this.token = await ERC20ReturnTrueMock.new();
    });

    shouldOnlyRevertOnErrors();
  });

  describe('with token that returns no boolean values', function () {
    beforeEach(async function () {
      this.token = await ERC20NoReturnMock.new();
    });

    shouldOnlyRevertOnErrors();
  });

  describe("with token that doesn't revert on invalid permit", function () {
    const wallet = Wallet.generate();
    const owner = wallet.getAddressString();
    const spender = hasNoCode;

    beforeEach(async function () {
      this.token = await ERC20PermitNoRevertMock.new();

      this.data = await getDomain(this.token).then(domain => ({
        primaryType: 'Permit',
        types: { EIP712Domain: domainType(domain), Permit },
        domain,
        message: { owner, spender, value: '42', nonce: '0', deadline: constants.MAX_UINT256 },
      }));

      this.signature = fromRpcSig(ethSigUtil.signTypedMessage(wallet.getPrivateKey(), { data: this.data }));
    });

    it('accepts owner signature', async function () {
      expect(await this.token.nonces(owner)).to.be.bignumber.equal('0');
      expect(await this.token.allowance(owner, spender)).to.be.bignumber.equal('0');

      await this.mock.$safePermit(
        this.token.address,
        this.data.message.owner,
        this.data.message.spender,
        this.data.message.value,
        this.data.message.deadline,
        this.signature.v,
        this.signature.r,
        this.signature.s,
      );

      expect(await this.token.nonces(owner)).to.be.bignumber.equal('1');
      expect(await this.token.allowance(owner, spender)).to.be.bignumber.equal(this.data.message.value);
    });

    it('revert on reused signature', async function () {
      expect(await this.token.nonces(owner)).to.be.bignumber.equal('0');
      // use valid signature and consume nounce
      await this.mock.$safePermit(
        this.token.address,
        this.data.message.owner,
        this.data.message.spender,
        this.data.message.value,
        this.data.message.deadline,
        this.signature.v,
        this.signature.r,
        this.signature.s,
      );
      expect(await this.token.nonces(owner)).to.be.bignumber.equal('1');
      // invalid call does not revert for this token implementation
      await this.token.permit(
        this.data.message.owner,
        this.data.message.spender,
        this.data.message.value,
        this.data.message.deadline,
        this.signature.v,
        this.signature.r,
        this.signature.s,
      );
      expect(await this.token.nonces(owner)).to.be.bignumber.equal('1');
      // invalid call revert when called through the SafeERC20 library
      await expectRevert(
        this.mock.$safePermit(
          this.token.address,
          this.data.message.owner,
          this.data.message.spender,
          this.data.message.value,
          this.data.message.deadline,
          this.signature.v,
          this.signature.r,
          this.signature.s,
        ),
        'SafeERC20: permit did not succeed',
      );
      expect(await this.token.nonces(owner)).to.be.bignumber.equal('1');
    });

    it('revert on invalid signature', async function () {
      // signature that is not valid for owner
      const invalidSignature = {
        v: 27,
        r: '0x71753dc5ecb5b4bfc0e3bc530d79ce5988760ed3f3a234c86a5546491f540775',
        s: '0x0049cedee5aed990aabed5ad6a9f6e3c565b63379894b5fa8b512eb2b79e485d',
      };

      // invalid call does not revert for this token implementation
      await this.token.permit(
        this.data.message.owner,
        this.data.message.spender,
        this.data.message.value,
        this.data.message.deadline,
        invalidSignature.v,
        invalidSignature.r,
        invalidSignature.s,
      );

      // invalid call revert when called through the SafeERC20 library
      await expectRevert(
        this.mock.$safePermit(
          this.token.address,
          this.data.message.owner,
          this.data.message.spender,
          this.data.message.value,
          this.data.message.deadline,
          invalidSignature.v,
          invalidSignature.r,
          invalidSignature.s,
        ),
        'SafeERC20: permit did not succeed',
      );
    });
  });
});

function shouldRevertOnAllCalls(reason) {
  it('reverts on transfer', async function () {
    await expectRevert(this.mock.$safeTransfer(this.token.address, constants.ZERO_ADDRESS, 0), reason);
  });

  it('reverts on transferFrom', async function () {
    await expectRevert(
      this.mock.$safeTransferFrom(this.token.address, this.mock.address, constants.ZERO_ADDRESS, 0),
      reason,
    );
  });

  it('reverts on approve', async function () {
    await expectRevert(this.mock.$safeApprove(this.token.address, constants.ZERO_ADDRESS, 0), reason);
  });

  it('reverts on increaseAllowance', async function () {
    // [TODO] make sure it's reverting for the right reason
    await expectRevert.unspecified(this.mock.$safeIncreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 0));
  });

  it('reverts on decreaseAllowance', async function () {
    // [TODO] make sure it's reverting for the right reason
    await expectRevert.unspecified(this.mock.$safeDecreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 0));
  });
}

function shouldOnlyRevertOnErrors() {
  it("doesn't revert on transfer", async function () {
    await this.mock.$safeTransfer(this.token.address, constants.ZERO_ADDRESS, 0);
  });

  it("doesn't revert on transferFrom", async function () {
    await this.mock.$safeTransferFrom(this.token.address, this.mock.address, constants.ZERO_ADDRESS, 0);
  });

  describe('approvals', function () {
    context('with zero allowance', function () {
      beforeEach(async function () {
        await this.token.setAllowance(this.mock.address, 0);
      });

      it("doesn't revert when approving a non-zero allowance", async function () {
        await this.mock.$safeApprove(this.token.address, constants.ZERO_ADDRESS, 100);
      });

      it("doesn't revert when approving a zero allowance", async function () {
        await this.mock.$safeApprove(this.token.address, constants.ZERO_ADDRESS, 0);
      });

      it("doesn't revert when increasing the allowance", async function () {
        await this.mock.$safeIncreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 10);
      });

      it('reverts when decreasing the allowance', async function () {
        await expectRevert(
          this.mock.$safeDecreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 10),
          'SafeERC20: decreased allowance below zero',
        );
      });
    });

    context('with non-zero allowance', function () {
      beforeEach(async function () {
        await this.token.setAllowance(this.mock.address, 100);
      });

      it('reverts when approving a non-zero allowance', async function () {
        await expectRevert(
          this.mock.$safeApprove(this.token.address, constants.ZERO_ADDRESS, 20),
          'SafeERC20: approve from non-zero to non-zero allowance',
        );
      });

      it("doesn't revert when approving a zero allowance", async function () {
        await this.mock.$safeApprove(this.token.address, constants.ZERO_ADDRESS, 0);
      });

      it("doesn't revert when increasing the allowance", async function () {
        await this.mock.$safeIncreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 10);
      });

      it("doesn't revert when decreasing the allowance to a positive value", async function () {
        await this.mock.$safeDecreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 50);
      });

      it('reverts when decreasing the allowance to a negative value', async function () {
        await expectRevert(
          this.mock.$safeDecreaseAllowance(this.token.address, constants.ZERO_ADDRESS, 200),
          'SafeERC20: decreased allowance below zero',
        );
      });
    });
  });
}
