const path = require("path");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      gasPrice: 1,
      network_id: "*", // match any network
      websockets: true
    }
  
  },
  compilers: {
    solc:{
      version: "0.6.2"
    }
  }
};
