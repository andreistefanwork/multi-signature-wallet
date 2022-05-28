const MultiSignatureWallet = artifacts.require("./MultiSignatureWallet.sol");

contract("MultiSignatureWallet", accounts => {
    let wallet;

    beforeEach(async () => {
        wallet = await MultiSignatureWallet.new(accounts.slice(0, 3), 2);
    });

    it("should accept ether", async () => {
        await web3.eth.sendTransaction({from: accounts[0], to: wallet.address, value: web3.utils.toWei("5", "ether")});

        const actual = await web3.eth.getBalance(wallet.address);

        assert.equal(actual, web3.utils.toWei("5", "ether"), "Didn't accept the sent amount of eth.");
    });

    it("should only allow owners to make transactions", async () => {
        try {
            await wallet.submitTransaction(accounts[5], web3.utils.toWei("5", "ether"), {from: accounts[4]});
            assert(false);
        } catch (e) {
            assert(true);
        }
    });

    it("should create transaction when an owner submits one", async () => {
        await wallet.submitTransaction(accounts[5], web3.utils.toWei("5", "ether"), {from: accounts[1]});

        const transaction = await wallet.transactions(0);

        assert.equal(transaction.to, accounts[5]);
        assert.equal(transaction.amount, web3.utils.toWei("5", "ether"));
    });

    it("should allow approving transactions only once per owner", async () => {
        await wallet.submitTransaction(accounts[5], web3.utils.toWei("5", "ether"), {from: accounts[1]});
        await wallet.approveTransaction(0, {from: accounts[0]});

        try {
            await wallet.approveTransaction(0, {from: accounts[0]});
            assert(false);
        } catch (e) {
            assert(true);
        }
    });

    it("should allow executing transactions only when the majority has approved it", async () => {
        await web3.eth.sendTransaction({from: accounts[0], to: wallet.address, value: web3.utils.toWei("5", "ether")});
        await wallet.submitTransaction(accounts[5], web3.utils.toWei("5", "ether"), {from: accounts[1]});
        await wallet.approveTransaction(0, {from: accounts[0]});

        try {
            await wallet.executeTransaction(0, {from: accounts[0]});
            assert(false);
        } catch (e) {
            assert(true);
        }

        await wallet.approveTransaction(0, {from: accounts[1]});

        await wallet.executeTransaction(0, {from: accounts[0]});
    });
});
