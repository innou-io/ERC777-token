pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title Contract for ERC777 token extended with optional support of a vesting schedule
 *
 * @notice Certain amount of tokens may be locked in for a holder
 * so the holder will only be able to transfer locked tokens out of their wallet
 * after they have vested.
 *
 * @dev Inheriting contracts MUST redefine functions
 */
contract Vestable {
    using SafeMath for uint256;

    // Amount of tokens originally locked (before any unlocking) for all holders
    uint256 _totalLocked;

    // Amount of tokens originally locked (before any unlocking) for a holder
    mapping(address => uint256) private _locked;

    event TokensLocked(address indexed holder, uint256 amount);

    /**
     * @dev Get amount of tokens of a holder being locked right now.
     * @param holder Address of the holder
     * @return Amount of tokens still locked in
     */
    function lockedNow(address holder) public view returns (uint256) {
        return lockedAt(holder, block.timestamp);
    }

    /**
     * @dev Get amount of tokens of a holder locked in at a certain time.
     * @param holder Address of the holder
     * @param time The UNIX time to calculate locked-in tokens at
     * @return Amount of tokens still locked in
     */
    function lockedAt(address holder, uint256 time) public view returns (uint256) {
        uint256 end = _vestingEnd();
        if (time >= end) { return 0; }

        uint256 lockedAmount = _locked[holder];
        if (lockedAmount > 0) {
            uint256 start = _vestingStart();
            if (time > start) {
                return lockedAmount.mul(end.sub(time)).div(end.sub(start));
            } else {
                return lockedAmount;
            }
        }
        return 0;
    }

    /**
     * @dev Get amount of tokens of a holder which were locked in.
     * @param holder Address of the holder
     * @return Amount of tokens of a holder which was locked in
     */
    function locked(address holder) public view returns (uint256) {
        return _locked[holder];
    }

    /**
     * @dev Get the amount of tokens which were locked in for all holders.
     * @return Amount of tokens
     */
    function totalLocked() public view returns (uint256) {
        return _totalLocked;
    }

    /*
     * @return Unix time when the vesting period begins
     */
    function vestingStart() public pure returns (uint256) {
        return _vestingStart();
    }

    /*
     * @return Unix time when the vesting period ends
     */
    function vestingEnd() public pure returns (uint256) {
        return _vestingEnd();
    }

    /**
     * @dev Lock in given amount of tokens for a holder
     * no matter if the holder has this token amount or not yet.
     * @param holder Address of the holder
     * @param amount Token amount to lock in
     */
    function _lockIn(address holder, uint256 amount) internal {
        require(holder != address(0), "VestedTokens: zero holder address");
        require(_vestingEnd() > block.timestamp, "VestedTokens: vesting period ended");

        _totalLocked = _totalLocked.add(amount);
        _locked[holder] = _locked[holder].add(amount);
        emit TokensLocked(holder, amount);
    }

    /*
     * @dev Inheriting contracts MUST redefine it
     * returning UNIX time for the vesting period start
     */
    function _vestingStart() private pure returns (uint256) {
        revert("must be redefined");
    }

    /*
     * @dev Inheriting contracts MUST redefine it
     * returning UNIX time for the vesting period end
     */
    function _vestingEnd() private pure returns (uint256) {
        revert("must be redefined");
    }

    uint256[50] private ______gap;
}
