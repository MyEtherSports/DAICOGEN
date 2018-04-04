require('babel-register');
require('babel-polyfill');

var Web3 = require("web3");

var sandboxId = '0123456789';
var url = 'http://localhost:8555/sandbox/' + sandboxId;

const HDWalletProvider = require("truffle-hdwallet-provider-privkey");

var infura_apikey = "<your infura API token>";



module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      network_id: "*", // Match any network id
      gasPrice: 4000000000,
      gasLimit:6469391,
      gas:6469391,
    },
    ropsten: {
      provider: new HDWalletProvider(pkey, "https://ropsten.infura.io/"+infura_apikey),
      network_id: 3,
      gasPrice: 10000000000,
      gasLimit:4700000,
      gas:4700000,
    },
    rinkeby: {
      provider: new HDWalletProvider(pkey, "https://rinkeby.infura.io/"+infura_apikey),
      network_id: 4,
      gasPrice: 4000000000,
      gasLimit:6700000,
      gas:6700000,
    },
    live: {
      provider: new HDWalletProvider(pkey, "https://mainnet.infura.io/"+infura_apikey),
      network_id: 1,
      gasPrice: 2000000000,
      gasLimit:6700000,
      gas:6700000,
    }
    
  }
};


/* For Sandbox
module.exports = {
  provider: new Web3.providers.HttpProvider(url),
  gasPrice: 4000000000,
  gasLimit:6469391,
  gas:6469391,
};
*/
