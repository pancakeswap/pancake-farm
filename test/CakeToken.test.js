const { assert } = require("chai");

const CakeToken = artifacts.require('CakeToken');

contract('CakeToken', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.cake = await CakeToken.new({ from: minter });
    });


    it('mint', async () => {
        await this.cake.mint(alice, 1000, { from: minter });
        assert.equal((await this.cake.balanceOf(alice)).toString(), '1000');
    })
});
