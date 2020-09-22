
const CakeToken = artifacts.require('CakeToken');

contract('CakeToken', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.cake = await CakeToken.new({ from: minter });
    });


    it('mint', async () => {
        // const num = 0.01 * Math.pow(10, 18);
        // const numAsHex = "0x" + num.toString(16);
        // await this.cake.mint(alice, num)
    })

});
