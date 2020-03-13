/* global require */

const INFURA_KEY = process.env.INFURA_KEY;
const MNEMONIC = process.env.MNEMONIC;           // 12 or 24 words
const PRIV_KEYS = process.env.PRIV_KEYS          // Ignored if `MNEMONIC` provided
    ? process.env.PRIV_KEYS.split(',')  // single key or comma-delimited list of keys expected
    : undefined;

const getInfuraProvider = (() => {
  let providers = {};
  return (network, mnemonicOrPKs = MNEMONIC || PRIV_KEYS) => {
    const uri = `https://${network}.infura.io/v3/${INFURA_KEY}`;
    const hash = (`${mnemonicOrPKs}${uri}`)
        .split('').reduce((a,b)=>{a=((a<<5)-a)+b.charCodeAt(0);return a&a},0)
        .toString();
    return providers[hash]
        ? () => providers[hash]
        : () => {
          if (process.env.TRUFFLE_TEST) throw new Error('Forbidden to use Infura in TRUFFLE_TEST environment');
          const HDWalletProvider = require("@truffle/hdwallet-provider");
          // `mnemonicOrKeys` may be a <string> mnemonic or an <Array> with <string> private key(s)
          providers[hash] = new HDWalletProvider(mnemonicOrPKs, uri);
          return providers[hash];
        }
  }
})();

module.exports = {
  networks: {

    // 'ganache-cli --deterministic' + 'truffle console --network truffle'
    truffle: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },

    // 'truffle develop'
    develop: {
      protocol: 'http',
      host: "127.0.0.1",
      // gas: 5000000,
      // gasPrice: 3e9,
      port: 9545,
      network_id: "*",
    },

    ropsten: {
      provider: getInfuraProvider('ropsten'),
      network_id: "3",
    },

    rinkeby: {
      provider: getInfuraProvider('rinkeby'),
      network_id: "4",
      gas: 4000000
    },

    live: {
      network_id: 1,
      provider: getInfuraProvider('mainnet'),
      gasPrice: 7e9,
    },

  },
  // compilers: {
  //   solc: {
  //     version: "0.5.2",
  //     settings: {
  //       optimizer: {
  //         enabled: true,
  //         runs: 200
  //       },
  //       evmVersion: "byzantium"
  //     }
  //   }
  // }
};
