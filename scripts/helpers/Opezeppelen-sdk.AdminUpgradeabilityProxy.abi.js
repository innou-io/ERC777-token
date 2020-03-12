module.exports = getOpenzeppelinUpgradesAdminUpgradeabilityProxyContractJson().abi;

function getOpenzeppelinUpgradesAdminUpgradeabilityProxyContractJson() {
    /** Extracted "as is" from the package:
     "name": "@openzeppelin/upgrades",
     "url": "git+https://github.com/OpenZeppelin/openzeppelin-sdk.git"
     "homepage": "https://github.com/OpenZeppelin/openzeppelin-sdk/tree/master/packages/lib#readme",
     "version": "2.7.1"
     "gitHead": "709c0778284255c63bbbee28296c4df8aa5cf3df",
     */
    return {
        "fileName": "AdminUpgradeabilityProxy.sol",
        "contractName": "AdminUpgradeabilityProxy",
        "sourcePath": "contracts/upgradeability/AdminUpgradeabilityProxy.sol",
        "abi": [
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "newImplementation",
                        "type": "address"
                    }
                ],
                "name": "upgradeTo",
                "outputs": [],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "newImplementation",
                        "type": "address"
                    },
                    {
                        "name": "data",
                        "type": "bytes"
                    }
                ],
                "name": "upgradeToAndCall",
                "outputs": [],
                "payable": true,
                "stateMutability": "payable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [],
                "name": "implementation",
                "outputs": [
                    {
                        "name": "",
                        "type": "address"
                    }
                ],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "newAdmin",
                        "type": "address"
                    }
                ],
                "name": "changeAdmin",
                "outputs": [],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [],
                "name": "admin",
                "outputs": [
                    {
                        "name": "",
                        "type": "address"
                    }
                ],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "inputs": [
                    {
                        "name": "_logic",
                        "type": "address"
                    },
                    {
                        "name": "_admin",
                        "type": "address"
                    },
                    {
                        "name": "_data",
                        "type": "bytes"
                    }
                ],
                "payable": true,
                "stateMutability": "payable",
                "type": "constructor"
            },
            {
                "payable": true,
                "stateMutability": "payable",
                "type": "fallback"
            },
            {
                "anonymous": false,
                "inputs": [
                    {
                        "indexed": false,
                        "name": "previousAdmin",
                        "type": "address"
                    },
                    {
                        "indexed": false,
                        "name": "newAdmin",
                        "type": "address"
                    }
                ],
                "name": "AdminChanged",
                "type": "event"
            },
            {
                "anonymous": false,
                "inputs": [
                    {
                        "indexed": true,
                        "name": "implementation",
                        "type": "address"
                    }
                ],
                "name": "Upgraded",
                "type": "event"
            }
        ],
    };
}
