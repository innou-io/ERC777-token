pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/lifecycle/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./ERC777Mintable.sol";
import "./Vestable.sol";
import "./ILockableToken.sol";

contract InnouToken is Initializable, Context, ERC777Mintable, Pausable, Vestable, ILockableToken {
    using SafeMath for uint256;

    string internal constant NAME = "INNOU.IO Token";
    string internal constant SYMBOL = "INNOU";

    // Just as Ether processed in wei, operations with tokens are processed in "atom"
    // that is the smallest and indivisible unit of the token: 1 token = 1x10^18 atom(s)

    // Maximum amount of tokens (expressed in "atom") which can be ever minted:
    uint256 internal constant MAX_SUPPLY = 500e24;          // 500.000.000 tokens

    // Start of the vesting period (UNIX time)
    uint256 private constant VESTING_START = 1590969600;    // 2020-06-01T00:00:00+00:00;
    // End of the vesting period (UNIX time)
    uint256 private constant VESTING_END = 1622505600;      // 2021-06-01T00:00:00+00:00;

    /**
     * @dev Analog to Constructor (for "upgradable proxy" pattern).
     */
    function initialize() public initializer {
        address sender = _msgSender();
        address[] memory defaultOperators;
        ERC777Mintable.initialize(NAME, SYMBOL, defaultOperators, sender);
        Pausable.initialize(sender);
    }

    /**
     * @dev Lock in given amount of tokens for a holder
     * no matter if the holder has this token amount or not yet.
     * Only the address with the `pauser` role can call it.
     *
     * @param holder Address of the holder
     * @param amount Token amount to lock in
     * @return bool(true)
     */
    function lockIn(address holder, uint256 amount) external onlyPauser returns (bool) {
        super._lockIn(holder, amount);
        return true;
    }

    /**
     * @return maximum amount of tokens that can be ever issued
     * quoted in "atom" (the smallest and indivisible token)
     */
    function supplyCap() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // @dev Overwrites parent behaviour respecting `MAX_SUPPLY` limit.
    function _preValidateMinting(address, address, uint256 amount, bytes memory, bytes memory ) internal view {
        require(amount.add(totalSupply()) <= MAX_SUPPLY, "Supply limit exceeded");
    }

    // @dev Overwrites parent behaviour reverting spending in respect of locked tokens and when paused.
    function _preValidateSpending(address from, uint256 amount) internal view whenNotPaused {
        uint256 lockedAmount = lockedNow(from);
        if (lockedAmount > 0) {
            require(balanceOf(from) > lockedAmount.add(amount), "not enough tokens or tokens locked");
        }
    }

    // @dev Sets (overwrites) the vesting period start
    function _vestingStart() private pure returns (uint256) {
        return VESTING_START;
    }

    // @dev Sets (overwrites) the vesting period end
    function _vestingEnd() private pure returns (uint256) {
        return VESTING_END;
    }

    uint256[50] private ______gap;
}
