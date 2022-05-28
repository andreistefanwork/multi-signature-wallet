const MultiSignatureWallet = artifacts.require("MultiSignatureWallet");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(MultiSignatureWallet, accounts.splice(0, 3), 2);
};
