pragma solidity ^0.5.0;

import "./openzeppelin-modified/contracts-ethereum-package/ERC777.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/roles/MinterRole.sol";

/**
 * @dev Extension of {ERC777} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 */
contract ERC777Mintable is Initializable, ERC777, MinterRole {

    /**
     * @dev `defaultOperators` may be an empty array.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        address minter
    ) public initializer {
        MinterRole.initialize(minter);
        ERC777.initialize(name, symbol, defaultOperators);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {Transfer} events.
     *
     * Requirements
     *
     * - the caller must have the {MinterRole}.
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) public onlyMinter returns (bool) {
        _preValidateMinting(operator, account, amount, userData, operatorData);
        _mint(operator, account, amount, userData, operatorData);
        return true;
    }

    /**
     * @dev Child contracts MAY overwrite this function to revert on unwanted calls.
     */
    function _preValidateMinting(
        address,        // operator
        address,        // account,
        uint256,        // amount,
        bytes memory,   // userData
        bytes memory    // operatorData
    ) internal view
    {
    }

    uint256[50] private ______gap;
}
