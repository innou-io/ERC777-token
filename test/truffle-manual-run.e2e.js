/** run in two terminals:
truffle develop
truffle --network develop exec test/truffle-manual-run.e2e.js
*/

'use strict';

require('@openzeppelin/test-helpers/configure')({ provider: web3.currentProvider, environment: 'truffle' });
const { singletons, time } = require('@openzeppelin/test-helpers');
const oz = require('@openzeppelin/cli');

if (!global.artifacts) { global.artifacts = artifacts; }
if (!global.web3) { global.web3 = web3; }

// For truffle exec
module.exports = function(callback) {
    main().then(() => callback()).catch(err => callback(err))
};

async function main(){
    const {networkType, networkId} = await getNetworkTypeAndId();
    console.log(`network type: ${networkType}`);
    console.log(`network id: ${networkId}`);

    if (networkType !== 'private') {
        throw new Error("This script is expected to run on the private network");
    }

    const addresses = await getAddresses();
    console.log(addresses);

    await deployErc1820Registry(networkId, networkType, addresses.deployer);

    const ozOptions = {};
    await initOz(networkId, networkType, addresses.deployer, ozOptions);

    const contracts = {};

    contracts.token = await deployUpgradableContract(
        { contractAlias: 'InnouToken', methodName: 'initialize', methodArgs: [] },
        ozOptions
    );

    const now = parseInt(((new Date()) / 1000).toString());
    const preSaleInitArgs  = [
        addresses.owner,        // owner
        20e+3,                  // baseRate
        addresses.wallet,       // wallet
        contracts.token.address,// token
        now + 30,               // openingTime
        now + 180,              // closingTime
        ether(100),          // cap
        addresses.capper,       // capper
        100e+3,                 // bigRate
        50e+3,                  // midRate
        ether(5),            // minContribution
    ];

    contracts.presale = await deployUpgradableContract(
        { contractAlias: 'InnouTokensPreSale', methodName: 'initialize', methodArgs: preSaleInitArgs },
        ozOptions
    );

    const logs = [];
    await testBaseScenario(addresses, contracts, logs)
        .finally(() => {
            console.log(JSON.stringify(logs, null, 2));
        });
}

async function testBaseScenario(addresses, contracts, logs) {
    console.log("Running and testing the Base scenario");
    const {
        deployer, owner, minter, capper, wallet, teamWallet, bountyWallet, rewardsWallet, investor, fiatInvestor
    } = addresses;
    const {token, presale} = contracts;

    const logStep = getLogger(logs);

    logStep('setMinter', await token.methods.addMinter(minter).send({from: deployer}));
    logStep('setPauser', await token.methods.addPauser(presale.address).send({from: deployer}));
    logStep('initialMint', await token.methods.mint(presale.address, presale.address, e18(100e+6), '0x0', '0x0').send({from: minter, gas: 300000}));
    logStep('overMinting', await token.methods.mint(presale.address, presale.address, e18(401e+6), '0x0', '0x0').send({from: minter, gas: 300000}).then(_ => { throw new Error('must throw'); }).catch(e => e || `reverted as expected`));
    logStep('setInvestorCap', await presale.methods.setCap(investor, ether(50)).send({from: capper}));
    await advanceTimeToPresaleStart();
    logStep('investorPays', await web3.eth.sendTransaction({from: investor, to: presale.address, value: ether(5), gas: 500000}));
    logStep('investorBuys', await presale.methods.buyTokens(investor).send({from: fiatInvestor, value: ether(10), gas: 400000}));
    logStep('extendTime', await presale.methods.extendTime(parseInt((new Date())/1000 + 10800)).send({from: owner}));
    logStep('issuerTokens1', await presale.methods.issueTokensToIssuer().send({from: owner, gas: 400000}).then(_ => { throw new Error('must throw'); }).catch(e => e || `reverted as expected`));
    logStep('setFiatInvestorCap', await presale.methods.setCap(fiatInvestor, ether(20)).send({from: capper}));
    logStep('fiatBuy1', await presale.methods.boughtTokensOffchain(fiatInvestor, ether(6), 0).send({from: owner, gas: 400000}));
    logStep('fiatBuy2', await presale.methods.boughtTokensOffchain(fiatInvestor, ether(7), 2).send({from: owner, gas: 400000}));
    logStep('setTeamWallet', await presale.methods.setTeamWallet(teamWallet).send({from: owner}));
    logStep('setBountyWallet', presale.methods.setBountyWallet(bountyWallet).send({from: owner}));
    logStep('setRewardsWallet', await presale.methods.setRewardsWallet(rewardsWallet).send({from: owner}));
    logStep('issuerTokens2', await presale.methods.issueTokensToIssuer().send({from: owner, gas: 400000}));
    const unsoldTokens = await token.methods.balanceOf(presale.address).call();
    const preBurnSupply = await token.methods.totalSupply().call();
    logStep('burnTokens', presale.methods.burn(unsoldTokens, str2bytes(`burning unsold tokens`)).send({from: owner, gas: 400000}));

    logStep('finalLogs', {
        events: await presale.getPastEvents({fromBlock: 0, toBlock: 1000}),
        unsoldTokens,
        preBurnSupply,
        postBurnSupply: await token.methods.totalSupply().call(),
        endTokenBalances: {
            presale: await token.methods.balanceOf(presale.address).call(),
            investor: await token.methods.balanceOf(investor).call(),
            fiatInvestor: await token.methods.balanceOf(fiatInvestor).call(),
            teamWallet: await token.methods.balanceOf(teamWallet).call(),
            bountyWallet: await token.methods.balanceOf(bountyWallet).call(),
            rewardsWallet: await token.methods.balanceOf(rewardsWallet).call(),
        }
    });

    async function advanceTimeToPresaleStart() {
        const openingTime = (await presale.methods.openingTime().call()) * 1;
        const latestBlock = await web3.eth.getBlock('latest');
        if (openingTime > latestBlock.timestamp) {
            await time.increase(openingTime - latestBlock.timestamp + 1);
        }
        if (! await presale.methods.isOpen().call()) {
            throw new Error('PreSale is NOT open');
        }
    }
}

async function getNetworkTypeAndId() {
    const networkType = await web3.eth.net.getNetworkType();
    const networkId = await web3.eth.net.getId();
    return {networkType, networkId};
}

async function getAddresses() {
    const addresses = {};
    [
        addresses.deployer,
        addresses.owner,
        addresses.minter,
        addresses.capper,
        addresses.wallet,
        addresses.teamWallet,
        addresses.bountyWallet,
        addresses.rewardsWallet,
        addresses.investor,
        addresses.fiatInvestor
    ] = await web3.eth.getAccounts();
    return addresses;
}

async function deployErc1820Registry(networkId, networkType, from) {
    const network = networkId.toString();
    if (networkType === 'private' ) {
        console.log(`deploying an ERC1820 registry on network ${networkId}`);
        await singletons.ERC1820Registry(from);
    } else {
        console.log(`!!! Skipping ERC1820 registry deployment for network ${networkId}`);
    }
}

async function initOz(networkId, networkType, from, ozOptions) {
    console.log('initializing Openzeppelin-sdk-cli');
    Object.assign(
        ozOptions,
        await oz.ConfigManager.initNetworkConfiguration({network: 'develop', from})
    );
    await oz.scripts.push(ozOptions);

    await oz.scripts.add({
        contractsData: [{ name: 'InnouToken', alias: 'InnouToken' }]
    });
    await oz.scripts.add({
        contractsData: [{ name: 'InnouTokensPreSale', alias: 'InnouTokensPreSale' }]
    });
}

async function deployUpgradableContract(contractParams, ozOptions) {
    console.log(`Deploying contract ${contractParams.contractAlias}`);
    const contract  = await oz.scripts.create(
        Object.assign(contractParams, ozOptions)
    );
    console.log(`Contract ${contractParams.contractAlias} deployed at ${contract.address}`);
    return contract;
}

function getLogger(logs = []) {
    function logStep(step, txReceipt) {
        console.log(`== step: ${step}`);
        txReceipt['__step'] = step;
        logs.push(txReceipt);
    }
    logStep._logs = logs;
    return logStep;
}

function ether(n) {
    return web3.utils.toWei((n).toString(), 'ether');
}

function e18(n) {
    return ether(n);
}

function str2bytes(s) {
    return web3.utils.hexToBytes(web3.utils.stringToHex(s || ''));
}
