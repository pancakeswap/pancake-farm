const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const CakeToken = artifacts.require('CakeToken');
const SyrupBar = artifacts.require('SyrupBar');
const MasterChef = artifacts.require('MasterChef');
const MockBEP20 = artifacts.require('libs/MockBEP20');
const LotteryRewardPool = artifacts.require('LotteryRewardPool');

contract('MasterChef', ([alice, bob, carol, dev, minter]) => {
  beforeEach(async () => {
    this.cake = await CakeToken.new({ from: minter });
    this.syrup = await SyrupBar.new(this.cake.address, { from: minter });
    this.lp1 = await MockBEP20.new('LPToken', 'LP1', '1000000', {
      from: minter,
    });
    this.lp2 = await MockBEP20.new('LPToken', 'LP2', '1000000', {
      from: minter,
    });
    this.lp3 = await MockBEP20.new('LPToken', 'LP3', '1000000', {
      from: minter,
    });
    this.lp4 = await MockBEP20.new('LPToken', 'LP4', '1000000', {
      from: minter,
    });
    this.chef = await MasterChef.new(
      this.cake.address,
      this.syrup.address,
      dev,
      '10',
      '10',
      { from: minter }
    );
    await this.cake.transferOwnership(this.chef.address, { from: minter });
    await this.syrup.transferOwnership(this.chef.address, { from: minter });

    await this.lp1.transfer(bob, '2000', { from: minter });
    await this.lp2.transfer(bob, '2000', { from: minter });
    await this.lp3.transfer(bob, '2000', { from: minter });

    await this.lp1.transfer(alice, '2000', { from: minter });
    await this.lp2.transfer(alice, '2000', { from: minter });
    await this.lp3.transfer(alice, '2000', { from: minter });
  });

  it('real case', async () => {
    await time.advanceBlockTo('70');
    this.lottery = await LotteryRewardPool.new(
      this.chef.address,
      this.cake.address,
      dev,
      carol,
      { from: minter }
    );
    await this.lp4.transfer(this.lottery.address, '10', { from: minter });

    await this.chef.add('1000', this.lp1.address, true, { from: minter });
    await this.chef.add('1000', this.lp2.address, true, { from: minter });
    await this.chef.add('500', this.lp3.address, true, { from: minter });
    await this.chef.add('500', this.lp4.address, true, { from: minter });

    assert.equal(
      (await this.lp4.balanceOf(this.lottery.address)).toString(),
      '10'
    );

    await this.lottery.startFarming(4, this.lp4.address, '1', { from: dev });
    await time.advanceBlockTo('80');

    assert.equal((await this.lottery.pendingReward('4')).toString(), '3');
    assert.equal(
      (await this.cake.balanceOf(this.lottery.address)).toString(),
      '0'
    );

    await this.lottery.harvest(4, { from: dev });
    // console.log(await this.lottery.pendingReward(4).toString())

    assert.equal(
      (await this.cake.balanceOf(this.lottery.address)).toString(),
      '0'
    );
    assert.equal((await this.cake.balanceOf(carol)).toString(), '5');
  });

  it('setReceiver', async () => {
    this.lottery = await LotteryRewardPool.new(
      this.chef.address,
      this.cake.address,
      dev,
      carol,
      { from: minter }
    );
    await this.lp1.transfer(this.lottery.address, '10', { from: minter });
    await this.chef.add('1000', this.lp1.address, true, { from: minter });
    await this.lottery.startFarming(1, this.lp1.address, '1', {
      from: dev,
    });
    await this.lottery.harvest(1, { from: dev });
    assert.equal((await this.cake.balanceOf(carol)).toString(), '7');
    await this.lottery.setReceiver(alice, { from: dev });
    assert.equal((await this.lottery.pendingReward('1')).toString(), '7');
    await this.lottery.harvest(1, { from: dev });
    assert.equal((await this.cake.balanceOf(alice)).toString(), '15');
  });

  it('emergencyWithdraw', async () => {});

  it('update admin', async () => {
    this.lottery = await LotteryRewardPool.new(
      this.chef.address,
      this.cake.address,
      dev,
      carol,
      { from: minter }
    );
    assert.equal(await this.lottery.adminAddress(), dev);
    await this.lottery.setAdmin(alice, { from: minter });
    assert.equal(await this.lottery.adminAddress(), alice);
    await this.chef.add('1000', this.lp1.address, true, { from: minter });
    await expectRevert(
      this.lottery.startFarming(1, this.lp1.address, '1', { from: dev }),
      'admin: wut?'
    );
  });
});
