pragma solidity ^0.5.0;

/**
 * @dev Custom interface to support locking (vesting) of tokens.
 */
interface ILockableToken {
    /**
     * @dev Lock `amount` tokens for a `holder`
     * @notice Implementation MUST revert unauthorized calls.
     *
     * @param holder Address of the holder
     * @param amount Token amount to lock in
     * @return True if locked successfully
     */
    function lockIn(address holder, uint256 amount) external returns (bool);
}
