const { expectRevert, time } = require('@openzeppelin/test-helpers');
const CakeToken = artifacts.require('CakeToken');
const SmartChef = artifacts.require('SmartChef');
const MockBEP20 = artifacts.require('libs/MockBEP20');

contract('SmartChef', ([alice, bob, carol, dev, minter]) => {
  beforeEach(async () => {
    this.syrup = await MockBEP20.new('LPToken1', 'LP1', '1000000000000', {
      from: minter,
    });
    this.reward = await MockBEP20.new('LPToken2', 'LP2', '100000000000', {
      from: minter,
    });
    this.chef = await SmartChef.new(this.syrup.address, this.reward.address, '40', '310', '400', {
      from: minter,
    });
  });

  it('smart chef now', async () => {
    await this.reward.transfer(this.chef.address, '100000', { from: minter });
    await this.syrup.transfer(bob, '1000', { from: minter });
    await this.syrup.transfer(carol, '1000', { from: minter });
    await this.syrup.transfer(alice, '1000', { from: minter });
    assert.equal((await this.syrup.balanceOf(bob)).toString(), '1000');

    await this.syrup.approve(this.chef.address, '1000', { from: bob });
    await this.syrup.approve(this.chef.address, '1000', { from: alice });
    await this.syrup.approve(this.chef.address, '1000', { from: carol });

    await this.chef.deposit('10', { from: bob });
    await this.chef.deposit('30', { from: alice });
    assert.equal(
      (await this.syrup.balanceOf(this.chef.address)).toString(),
      '40'
    );

    await time.advanceBlockTo('310');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '0'
    );

    await time.advanceBlockTo('311');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '10'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '30'
    );

    await this.chef.deposit('40', { from: carol });
    assert.equal(
      (await this.syrup.balanceOf(this.chef.address)).toString(),
      '80'
    );
    await time.advanceBlockTo('313');
    //  bob 10, alice 30, carol 40
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '25'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '75'
    );
    assert.equal(
      (await this.chef.pendingReward(carol, { from: carol })).toString(),
      '20'
    );

    await this.chef.withdraw('10', { from: bob });
    await this.chef.withdraw('30', { from: alice });
    await expectRevert(this.chef.withdraw('50', { from: carol }), 'not enough');
    await this.chef.deposit('30', { from: carol });
    await time.advanceBlockTo('450');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '0'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '0'
    );
    await this.chef.withdraw('70', { from: carol });
    assert.equal((await this.chef.addressLength()).toString(), '3');
  });

  it('emergencyWithdraw', async () => {
    await this.syrup.transfer(alice, '1000', { from: minter });
    assert.equal((await this.syrup.balanceOf(alice)).toString(), '1000');

    await this.syrup.approve(this.chef.address, '1000', { from: alice });
    await this.chef.deposit('10', { from: alice });
    assert.equal((await this.syrup.balanceOf(alice)).toString(), '990');
    await this.chef.emergencyWithdraw({ from: alice });
    assert.equal((await this.syrup.balanceOf(alice)).toString(), '1000');
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '0'
    );
  });
});
