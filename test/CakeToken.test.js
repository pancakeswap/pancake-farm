const { expectRevert } = require('@openzeppelin/test-helpers');
const CakeToken = artifacts.require('CakeToken');

contract('CakeToken', ([alice, bob, carol]) => {
    beforeEach(async () => {
        this.cake = await CakeToken.new({ from: alice });
    });

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.cake.name();
        const symbol = await this.cake.symbol();
        const decimals = await this.cake.decimals();
        assert.equal(name.valueOf(), 'CakeToken');
        assert.equal(symbol.valueOf(), 'SUSHI');
        assert.equal(decimals.valueOf(), '18');
    });

    it('should only allow owner to mint token', async () => {
        await this.cake.mint(alice, '100', { from: alice });
        await this.cake.mint(bob, '1000', { from: alice });
        await expectRevert(
            this.cake.mint(carol, '1000', { from: bob }),
            'Ownable: caller is not the owner',
        );
        const totalSupply = await this.cake.totalSupply();
        const aliceBal = await this.cake.balanceOf(alice);
        const bobBal = await this.cake.balanceOf(bob);
        const carolBal = await this.cake.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '100');
        assert.equal(bobBal.valueOf(), '1000');
        assert.equal(carolBal.valueOf(), '0');
    });

    it('should supply token transfers properly', async () => {
        await this.cake.mint(alice, '100', { from: alice });
        await this.cake.mint(bob, '1000', { from: alice });
        await this.cake.transfer(carol, '10', { from: alice });
        await this.cake.transfer(carol, '100', { from: bob });
        const totalSupply = await this.cake.totalSupply();
        const aliceBal = await this.cake.balanceOf(alice);
        const bobBal = await this.cake.balanceOf(bob);
        const carolBal = await this.cake.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '90');
        assert.equal(bobBal.valueOf(), '900');
        assert.equal(carolBal.valueOf(), '110');
    });

    it('should fail if you try to do bad transfers', async () => {
        await this.cake.mint(alice, '100', { from: alice });
        await expectRevert(
            this.cake.transfer(carol, '110', { from: alice }),
            'ERC20: transfer amount exceeds balance',
        );
        await expectRevert(
            this.cake.transfer(carol, '1', { from: bob }),
            'ERC20: transfer amount exceeds balance',
        );
    });
  });
