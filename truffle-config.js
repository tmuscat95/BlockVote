const path = require("path");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "/client/src/contracts"),
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      gas: 99721975,
      //gasPrice: 20000000000,
      network_id: "*", // match any network
      websockets: false
    },
    electiontest : {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      from: "0xAa68840d211dbf304Ad667453B478a73aBC93727"
    }
  
  },
  plugins: ["solidity-coverage","truffle-security"],
  compilers: {
    solc:{
      version: "0.6.2"
    }
  },
  mocha:{
    timeout:9007199254740991
  }
};
