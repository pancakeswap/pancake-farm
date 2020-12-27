const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const CakeToken = artifacts.require('CakeToken');
const BnbStaking = artifacts.require('BnbStaking');
const MockBEP20 = artifacts.require('libs/MockBEP20');
const WBNB = artifacts.require('libs/WBNB');

contract('BnbStaking.......', async ([alice, bob, admin, dev, minter]) => {
  beforeEach(async () => {
    this.rewardToken = await CakeToken.new({ from: minter });
    this.lpToken = await MockBEP20.new('LPToken', 'LP1', '1000000', {
      from: minter,
    });
    this.wBNB = await WBNB.new({ from: minter });
    this.bnbChef = await BnbStaking.new(
      this.wBNB.address,
      this.rewardToken.address,
      1000,
      10,
      1010,
      admin,
      this.wBNB.address,
      { from: minter }
    );
    await this.rewardToken.mint(this.bnbChef.address, 100000, { from: minter });
  });

  it('deposit/withdraw', async () => {
    await time.advanceBlockTo('10');
    await this.bnbChef.deposit({ from: alice, value: 100 });
    await this.bnbChef.deposit({ from: bob, value: 200 });
    assert.equal(
      (await this.wBNB.balanceOf(this.bnbChef.address)).toString(),
      '300'
    );
    assert.equal((await this.bnbChef.pendingReward(alice)).toString(), '1000');
    await this.bnbChef.deposit({ from: alice, value: 300 });
    assert.equal((await this.bnbChef.pendingReward(alice)).toString(), '0');
    assert.equal((await this.rewardToken.balanceOf(alice)).toString(), '1333');
    await this.bnbChef.withdraw('100', { from: alice });
    assert.equal(
      (await this.wBNB.balanceOf(this.bnbChef.address)).toString(),
      '500'
    );
    await this.bnbChef.emergencyRewardWithdraw(1000, { from: minter });
    assert.equal((await this.bnbChef.pendingReward(bob)).toString(), '1399');
  });

  it('should block man who in blanklist', async () => {
    await this.bnbChef.setBlackList(alice, { from: admin });
    await expectRevert(
      this.bnbChef.deposit({ from: alice, value: 100 }),
      'in black list'
    );
    await this.bnbChef.removeBlackList(alice, { from: admin });
    await this.bnbChef.deposit({ from: alice, value: 100 });
    await this.bnbChef.setAdmin(dev, { from: minter });
    await expectRevert(
      this.bnbChef.setBlackList(alice, { from: admin }),
      'admin: wut?'
    );
  });

  it('emergencyWithdraw', async () => {
    await this.bnbChef.deposit({ from: alice, value: 100 });
    await this.bnbChef.deposit({ from: bob, value: 200 });
    assert.equal(
      (await this.wBNB.balanceOf(this.bnbChef.address)).toString(),
      '300'
    );
    await this.bnbChef.emergencyWithdraw({ from: alice });
    assert.equal(
      (await this.wBNB.balanceOf(this.bnbChef.address)).toString(),
      '200'
    );
    assert.equal((await this.wBNB.balanceOf(alice)).toString(), '100');
  });

  it('emergencyRewardWithdraw', async () => {
    await expectRevert(
      this.bnbChef.emergencyRewardWithdraw(100, { from: alice }),
      'caller is not the owner'
    );
    await this.bnbChef.emergencyRewardWithdraw(1000, { from: minter });
    assert.equal((await this.rewardToken.balanceOf(minter)).toString(), '1000');
  });

  it('setLimitAmount', async () => {
    // set limit to 1e-12 BNB
    await this.bnbChef.setLimitAmount('1000000', { from: minter });
    await expectRevert(
      this.bnbChef.deposit({ from: alice, value: 100000000 }),
      'exceed the to'
    );
  });
});
