require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });

const { singletons } = require('@openzeppelin/test-helpers');

module.exports = async function (deployer, network, accounts) {
    console.log(`network: ${network}`);
    if (network === 'development' || network === 'develop' ) {
        console.log('deploying an ERC1820 registry (for ERC777 tokens)');
        await singletons.ERC1820Registry(accounts[0]);
    }
};
