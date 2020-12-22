const { expectRevert, time } = require('@openzeppelin/test-helpers');
const CakeToken = artifacts.require('CakeToken');
const MasterChef = artifacts.require('MasterChef');
const SyrupBar = artifacts.require('SyrupBar');
const SousChef = artifacts.require('SousChef');
const MockBEP20 = artifacts.require('libs/MockBEP20');

contract('SousChef', ([alice, bob, carol, dev, minter]) => {
  beforeEach(async () => {
    this.syrup = await MockBEP20.new('LPToken', 'LP1', '1000000', {
      from: minter,
    });
    this.chef = await SousChef.new(this.syrup.address, '40', '300', '400', {
      from: minter,
    });
  });

  it('sous chef now', async () => {
    await this.syrup.transfer(bob, '1000', { from: minter });
    await this.syrup.transfer(carol, '1000', { from: minter });
    await this.syrup.transfer(alice, '1000', { from: minter });
    assert.equal((await this.syrup.balanceOf(bob)).toString(), '1000');

    await this.syrup.approve(this.chef.address, '1000', { from: bob });
    await this.syrup.approve(this.chef.address, '1000', { from: alice });
    await this.syrup.approve(this.chef.address, '1000', { from: carol });

    await this.chef.deposit('10', { from: bob });
    assert.equal(
      (await this.syrup.balanceOf(this.chef.address)).toString(),
      '10'
    );

    await time.advanceBlockTo('300');

    await this.chef.deposit('30', { from: alice });
    assert.equal(
      (await this.syrup.balanceOf(this.chef.address)).toString(),
      '40'
    );
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '40'
    );

    await time.advanceBlockTo('302');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '50'
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
    await time.advanceBlockTo('304');
    //  bob 10, alice 30, carol 40
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '65'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '75'
    );
    assert.equal(
      (await this.chef.pendingReward(carol, { from: carol })).toString(),
      '20'
    );

    await this.chef.deposit('20', { from: alice }); // 305 bob 10, alice 50, carol 40
    await this.chef.deposit('30', { from: bob }); // 306  bob 40, alice 50, carol 40

    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '74'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '110'
    );

    await time.advanceBlockTo('307');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '86'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '125'
    );

    await this.chef.withdraw('20', { from: alice }); // 308 bob 40, alice 30, carol 40
    await this.chef.withdraw('30', { from: bob }); // 309  bob 10, alice 30, carol 40

    await time.advanceBlockTo('310');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '118'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '166'
    );
    assert.equal(
      (await this.syrup.balanceOf(this.chef.address)).toString(),
      '80'
    );

    await time.advanceBlockTo('400');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '568'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '1516'
    );
    assert.equal(
      (await this.chef.pendingReward(carol, { from: alice })).toString(),
      '1915'
    );

    await time.advanceBlockTo('420');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '568'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '1516'
    );
    assert.equal(
      (await this.chef.pendingReward(carol, { from: alice })).toString(),
      '1915'
    );

    await this.chef.withdraw('10', { from: bob });
    await this.chef.withdraw('30', { from: alice });
    await expectRevert(this.chef.withdraw('50', { from: carol }), 'not enough');
    await this.chef.deposit('30', { from: carol });
    await time.advanceBlockTo('450');
    assert.equal(
      (await this.chef.pendingReward(bob, { from: bob })).toString(),
      '568'
    );
    assert.equal(
      (await this.chef.pendingReward(alice, { from: alice })).toString(),
      '1516'
    );
    assert.equal(
      (await this.chef.pendingReward(carol, { from: alice })).toString(),
      '1915'
    );
    await this.chef.withdraw('70', { from: carol });
    assert.equal((await this.chef.addressLength()).toString(), '3');
  });

  it('try syrup', async () => {
    this.cake = await CakeToken.new({ from: minter });
    this.syrup = await SyrupBar.new(this.cake.address, { from: minter });
    this.lp1 = await MockBEP20.new('LPToken', 'LP1', '1000000', {
      from: minter,
    });
    this.chef = await MasterChef.new(
      this.cake.address,
      this.syrup.address,
      dev,
      '1000',
      '300',
      { from: minter }
    );
    await this.cake.transferOwnership(this.chef.address, { from: minter });
    await this.syrup.transferOwnership(this.chef.address, { from: minter });
    await this.lp1.transfer(bob, '2000', { from: minter });
    await this.lp1.transfer(alice, '2000', { from: minter });

    await this.lp1.approve(this.chef.address, '1000', { from: alice });
    await this.cake.approve(this.chef.address, '1000', { from: alice });

    await this.chef.add('1000', this.lp1.address, true, { from: minter });
    await this.chef.deposit(1, '20', { from: alice });
    await time.advanceBlockTo('500');
    await this.chef.deposit(1, '0', { from: alice });
    await this.chef.add('1000', this.lp1.address, true, { from: minter });

    await this.chef.enterStaking('10', { from: alice });
    await time.advanceBlockTo('510');
    await this.chef.enterStaking('10', { from: alice });

    this.chef2 = await SousChef.new(this.syrup.address, '40', '600', '800', {
      from: minter,
    });
    await this.syrup.approve(this.chef2.address, '10', { from: alice });
    await time.advanceBlockTo('590');
    this.chef2.deposit('10', { from: alice }); //520
    await time.advanceBlockTo('610');
    assert.equal(
      (await this.syrup.balanceOf(this.chef2.address)).toString(),
      '10'
    );
    assert.equal(
      (await this.chef2.pendingReward(alice, { from: alice })).toString(),
      '400'
    );
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
