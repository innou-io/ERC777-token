module.exports = getOpenzeppelinUpgradesProxyAdminContractJson().abi;

function getOpenzeppelinUpgradesProxyAdminContractJson() {
    /** Extracted "as is" from the package:
     "name": "@openzeppelin/upgrades",
     "url": "git+https://github.com/OpenZeppelin/openzeppelin-sdk.git"
     "homepage": "https://github.com/OpenZeppelin/openzeppelin-sdk/tree/master/packages/lib#readme",
     "version": "2.7.1"
     "gitHead": "709c0778284255c63bbbee28296c4df8aa5cf3df",
     */
    return {
        "contractName": "ProxyAdmin",
        "sourcePath": "contracts/upgradeability/ProxyAdmin.sol",
        "abi": [
            {
                "constant": true,
                "inputs": [
                    {
                        "name": "proxy",
                        "type": "address"
                    }
                ],
                "name": "getProxyImplementation",
                "outputs": [
                    {
                        "name": "",
                        "type": "address"
                    }
                ],
                "payable": false,
                "stateMutability": "view",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [],
                "name": "renounceOwnership",
                "outputs": [],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "proxy",
                        "type": "address"
                    },
                    {
                        "name": "newAdmin",
                        "type": "address"
                    }
                ],
                "name": "changeProxyAdmin",
                "outputs": [],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": true,
                "inputs": [],
                "name": "owner",
                "outputs": [
                    {
                        "name": "",
                        "type": "address"
                    }
                ],
                "payable": false,
                "stateMutability": "view",
                "type": "function"
            },
            {
                "constant": true,
                "inputs": [],
                "name": "isOwner",
                "outputs": [
                    {
                        "name": "",
                        "type": "bool"
                    }
                ],
                "payable": false,
                "stateMutability": "view",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "proxy",
                        "type": "address"
                    },
                    {
                        "name": "implementation",
                        "type": "address"
                    },
                    {
                        "name": "data",
                        "type": "bytes"
                    }
                ],
                "name": "upgradeAndCall",
                "outputs": [],
                "payable": true,
                "stateMutability": "payable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "proxy",
                        "type": "address"
                    },
                    {
                        "name": "implementation",
                        "type": "address"
                    }
                ],
                "name": "upgrade",
                "outputs": [],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": false,
                "inputs": [
                    {
                        "name": "newOwner",
                        "type": "address"
                    }
                ],
                "name": "transferOwnership",
                "outputs": [],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "constant": true,
                "inputs": [
                    {
                        "name": "proxy",
                        "type": "address"
                    }
                ],
                "name": "getProxyAdmin",
                "outputs": [
                    {
                        "name": "",
                        "type": "address"
                    }
                ],
                "payable": false,
                "stateMutability": "view",
                "type": "function"
            },
            {
                "anonymous": false,
                "inputs": [
                    {
                        "indexed": true,
                        "name": "previousOwner",
                        "type": "address"
                    },
                    {
                        "indexed": true,
                        "name": "newOwner",
                        "type": "address"
                    }
                ],
                "name": "OwnershipTransferred",
                "type": "event"
            }
        ],
    };
}
