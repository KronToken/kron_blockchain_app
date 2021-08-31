const HDWalletProvider = require('truffle-hdwallet-provider-privkey');
const privateKey = "cc35a9f029e15b0b6de95482785a1755380f4b63fb1ac5d57afd23e289f9f4d1";
const kovanEndpointUrl = "https://kovan.infura.io/v3/07ba989d282b48cfb312cc0a8c3b4bc5";
const ropstenEndpointUrl = "https://ropsten.infura.io/v3/07ba989d282b48cfb312cc0a8c3b4bc5";
const rinkebyEndpointUrl = "https://rinkeby.infura.io/v3/07ba989d282b48cfb312cc0a8c3b4bc5"

module.exports = {
    networks: {
      development: {
        host: "127.0.0.1",
        port: 7545,
        network_id: "*" // Match any network id
      },
      kovan: {
        provider: function() {
          return new HDWalletProvider(
            //private keys array
            [privateKey],
            //url to ethereum node
            kovanEndpointUrl
          )
        },
        gas: 5000000,
        gasPrice: 25000000000,
        network_id: 42
      },
      ropsten: {
        provider: function() {
          return new HDWalletProvider(
            //private keys array
            [privateKey],
            //url to ethereum node
            ropstenEndpointUrl
          )
        },
        gas: 5000000,
        gasPrice: 25000000000,
        network_id: 42
      },
      rinkeby: {
        provider: function() {
          return new HDWalletProvider(
            //private keys array
            [privateKey],
            //url to ethereum node
            rinkebyEndpointUrl
          )
        },
        gas: 5000000,
        gasPrice: 25000000000,
        network_id: 4
      }
    },
    contracts_directory: './build/contracts/',
    contracts_build_directory: './build/abis/',
    compilers: {
      solc: {
        version: "^0.8.0"
      }
    }
};