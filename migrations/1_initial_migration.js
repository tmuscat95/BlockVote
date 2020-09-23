var Migrations = artifacts.require("./Migrations.sol");
const TruffleConfig = require('../truffle-config.js');
const Web3 = require('web3');
const { networks } = require('../truffle-config.js');

module.exports = function(deployer) {
  const config = TruffleConfig.networks.electiontest;
  var web3Provider = new Web3.providers.HttpProvider('http://' + config.host + ':' + config.port);
  const web3 = new Web3(web3Provider);
  //console.log('>> Unlocking account ' + config.from);
  //web3.personal.unlockAccount("0x29F884087c79d89B48d8a05D0269265606034c99", "todeskesselkurland", 86400000);


  deployer.deploy(Migrations);
};
