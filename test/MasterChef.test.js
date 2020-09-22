const { expectRevert, time } = require('@openzeppelin/test-helpers');
const CakeToken = artifacts.require('CakeToken');
const SyrupBar = artifacts.require('SyrupBar');
const MasterChef = artifacts.require('MasterChef');
const MockBEP20 = artifacts.require('MockBEP20');

contract('MasterChef', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.cake = await CakeToken.new({ from: alice });
        this.syrup = await SyrupBar.new(this.cake.address, { from: alice });
        this.lp1 = await MockBEP20.new('LPToken', 'LP1', '1000', { from: alice });
        this.lp2 = await MockBEP20.new('LPToken', 'LP2', '1000', { from: alice });
        this.lp3 = await MockBEP20.new('LPToken', 'LP3', '1000', { from: alice });
        this.chef = await MasterChef.new(this.cake.address, this.syrup.address, dev, '1000', '300', { from: alice });
        await this.cake.transferOwnership(this.chef.address, { from: alice });
        await this.syrup.transferOwnership(this.chef.address, { from: alice });
        await this.chef.add('1000', this.lp1.address, true);
        await this.chef.add('1000', this.lp2.address, true);
        await this.chef.add('1000', this.lp3.address, true);
    });


    it('deposit/withdraw, staking/unstaking', async () => {
      await time.advanceBlockTo('280');
      await this.lp1.approve(this.chef.address, '10', { from: alice });
      await this.chef.deposit(1, '2', { from: alice });
      await time.advanceBlockTo('310');
      await this.chef.deposit(1, '0', { from: alice });
      await this.chef.deposit(1, '4', { from: alice });
      await this.chef.deposit(1, '0', { from: alice });
      assert.equal((await this.lp1.balanceOf(alice)).toString(), '994');
      await this.chef.withdraw(1, '4', { from: alice });
      assert.equal((await this.lp1.balanceOf(alice)).toString(), '998');
      assert.equal((await this.cake.balanceOf(alice)).toString(), '3499');
    })

    it('staking/unstaking', async () => {
      await this.lp1.approve(this.chef.address, '10', { from: alice });
      await this.chef.deposit(1, '2', { from: alice }); //0
      await this.chef.withdraw(1, '2', { from: alice }); //1

      await this.cake.approve(this.chef.address, '250', { from: alice });
      await this.chef.enterStaking('240', { from: alice }); //3
      assert.equal((await this.syrup.balanceOf(alice)).toString(), '240');
      assert.equal((await this.cake.balanceOf(alice)).toString(), '10');
      await this.chef.enterStaking('10', { from: alice }); //4
      assert.equal((await this.syrup.balanceOf(alice)).toString(), '250');
      assert.equal((await this.cake.balanceOf(alice)).toString(), '249');
      await this.chef.leaveStaking(250);
      assert.equal((await this.syrup.balanceOf(alice)).toString(), '0');
      assert.equal((await this.cake.balanceOf(alice)).toString(), '749');

    });
});
