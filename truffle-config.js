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
    }
  
  },
  plugins: ["solidity-coverage"],
  compilers: {
    solc:{
      version: "0.6.2"
    }
  },
  mocha:{
    timeout:9007199254740991
  }
};
