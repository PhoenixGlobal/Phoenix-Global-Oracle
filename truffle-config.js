const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
    //   host:"172.168.3.77",
      port: 8545,            // Standard Ethereum port (default: none),// ganache-cli
      network_id: "*",       // Any network (default: none)
      gas: 67219750000,
      gasPrice: 0,
    },
    testnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.5.16",
      //   version: ">=0.4.33 <0.6.0",    // Fetch exact version from solc-bin (default: truffle's version)
      //   docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
         settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
         }
    }
  }
}