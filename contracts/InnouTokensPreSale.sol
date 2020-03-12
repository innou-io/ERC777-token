pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/crowdsale/validation/IndividuallyCappedCrowdsale.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Registry.sol";
import "./ILockableToken.sol";

// solhint-disable-next-line max-line-length
contract InnouTokensPreSale is Initializable, Ownable, TimedCrowdsale, IndividuallyCappedCrowdsale {
    using SafeMath for uint256;

    // 100% of tokens distribute as follows:
    uint256 constant private INVESTOR_TOKENS_PCT = 75;
    uint256 constant private TEAM_TOKENS_PCT = 10;
    uint256 constant private BOUNTY_TOKENS_PCT = 6;
    uint256 constant private REWARDS_TOKENS_PCT = 9;

    // Mim amount for discounted "big" and "middle" purchases
    uint256 constant private BIG_PURCHASE_LIMIT = 250 ether;
    uint256 constant private MID_PURCHASE_LIMIT = 50 ether;

    IERC1820Registry constant private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    uint256 private _cap;
    uint256 private _bigRate;
    uint256 private _midRate;

    uint256 private _minContribution;
    address private _teamWallet;
    address private _bountyWallet;
    address private _rewardsWallet;

    uint256 private _weiRaisedOffchain;
    uint256 private _purchasedTokens;
    uint256 private _issuerTokenBase;

    /**
     * Event for receiving tokens by this contract (for the sale).
     * @param tokenAmount Number of tokens received (for the sale)
     * @param userData Optional data (refer to ERC-777)
     */
    event TokensReceived(uint256 tokenAmount, bytes userData);

    /**
     * Event for burning (unsold) tokens by this contract.
     * @param tokenAmount Number of tokens burnt
     * @param userData Optional data (refer to ERC-777)
     */
    event TokensBurned(uint256 tokenAmount, bytes userData);

    /**
     * Event for issuing tokens to the Issuer.
     * @param teamTokens amount of tokens issued to founders and the team
     * @param bountyTokens amount of tokens issued to the bounty & marketing pool
     * @param rewardTokens amount of tokens issued to the user rewards & reserves pool
     */
    event TokensToIssuer(
        uint256 teamTokens,
        uint256 bountyTokens,
        uint256 rewardTokens
    );

    /**
     * Event for applying a special rate.
     * @param beneficiary Address of the beneficiary
     * @param rate Special rate applied
     */
    event SpecialRate(address indexed beneficiary, uint256 rate);

    /**
     * Event for setting a cap for a beneficiary.
     * @param beneficiary Address of the beneficiary
     * @param cap Max amount of contribution in wei(s)
     */
    event CapSet(address indexed beneficiary, uint256 cap);

    /**
     * @dev Analog to Constructor (for "upgradable proxy" pattern).
     * @param owner Address that can run special functions (such as "issue tokens settled off-chain")
     * @dev rate The rate for a "small" purchase
     * Note: it is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 100 millions for a token
     * that has 18 decimals, 1 wei will give you 100 million units,
     * or 1/(1e+10) of the token.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     * @param openingTime PreSale opening time
     * @param closingTime PreSale closing time
     * @param cap Max total amount of wei contributed
     * @param capper Address that can set individual caps
     * @param bigRate The discounted rate for a "big" purchase
     * @param midRate The discounted rate for a "middle" purchase
     * @param minContribution Minimum contribution in wei accepted
     */
    function initialize(
        address owner,
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 openingTime,
        uint256 closingTime,
        uint256 cap,
        address capper,
        uint256 bigRate,
        uint256 midRate,
        uint256 minContribution
    ) public initializer
    {
        require(owner != address(0), "invalid owner address");
        require(cap > 0, "cap is 0");
        require(bigRate > 0, "bigRate is 0");
        require(midRate > 0, "midRate is 0");
        require(minContribution > 0, "minContribution is 0");
        require(capper != address(0), "invalid capper address");

        ReentrancyGuard.initialize();
        Ownable.initialize(owner);
        // rate, wallet and tokens get checked (for non-zero values)
        Crowdsale.initialize(rate, wallet, token);
        // openingTime and closingTime get checked (against block.timestamp)
        TimedCrowdsale.initialize(openingTime, closingTime);
        IndividuallyCappedCrowdsale.initialize(capper);

        _cap = cap;
        _bigRate = bigRate;
        _midRate = midRate;
        _minContribution = minContribution;

        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    /**
     * @dev Processes a purchase settled off-chain (and issues tokens to the beneficiary).
     * Only owner may call it.
     * @param beneficiary Recipient of the token purchase
     * @param weiAmount Value settled off-chain
     * @param specialRate Optional special rate
     */
    function boughtTokensOffchain(
        address beneficiary,
        uint256 weiAmount,
        uint256 specialRate
    ) external nonReentrant onlyOwner {
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount
        uint256 tokens;
        if(specialRate > 0) {
            tokens = weiAmount.mul(specialRate);
        } else {
            tokens = _getTokenAmount(weiAmount);
        }

        // update state
        _weiRaisedOffchain = _weiRaisedOffchain.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Issues tokens to the team, bounty and rewards pools.
     * Only owner may call it.
     */
    function issueTokensToIssuer() external nonReentrant onlyOwner {
        require(_purchasedTokens > _issuerTokenBase, "no new tokens to Issuer allowed");
        require(_teamWallet != address(0), "team wallet undefined");
        require(_bountyWallet != address(0), "bounty wallet undefined");
        require(_rewardsWallet != address(0), "rewards wallet undefined");

        // calculate tokens to issue (reminder is ignored)
        uint256 unusedBase = _purchasedTokens.sub(_issuerTokenBase);
        uint256 teamTokensAmount = unusedBase.mul(TEAM_TOKENS_PCT).div(INVESTOR_TOKENS_PCT);
        uint256 bountyTokensAmount = unusedBase.mul(BOUNTY_TOKENS_PCT).div(INVESTOR_TOKENS_PCT);
        uint256 rewardsTokensAmount = unusedBase.mul(REWARDS_TOKENS_PCT).div(INVESTOR_TOKENS_PCT);

        // update state
        _issuerTokenBase = _purchasedTokens;

        // issue
        _issueTokensToIssuer(teamTokensAmount, bountyTokensAmount, rewardsTokensAmount);
    }

    /**
     * @dev Burn tokens held by this contract (which remain unsold).
     * Only owner may call it.
     * @param tokenAmount Number of tokens to burn
     * @param data Optional data (refer to ERC-777)
     */
    function burn(uint256 tokenAmount, bytes calldata data) external nonReentrant onlyOwner {
        address token = address(token());
        bytes memory payload = abi.encodeWithSelector(IERC777(token).burn.selector, tokenAmount, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(payload);
        require(success, "ERC777 burn failed");

        emit TokensBurned(tokenAmount, data);
    }

    /**
     * @dev Extend the PreSale.
     * @param newClosingTime PreSale closing time
     */
    function extendTime(uint256 newClosingTime) public onlyOwner {
        _extendTime(newClosingTime);
    }

    /**
     * @dev ERC777 Recipient implementation.
     * Required to accept tokens minted/sent to this contract (for further sale).
     * Expected to be called by the token contract.
     */
    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
    ) external {
        require(msg.sender == address(token()), "ERC777Recipient: invalid token");
        // When minted tokens get sent from the address 0
        require(from == address(0), "ERC777Recipient: invalid from address");
        emit TokensReceived(amount, userData);
    }

    /**
     * @dev Set once the address where tokens for the founders & team are issued to.
     * @param teamWallet (Optional) address for the team & founders' tokens
     */
    function setTeamWallet(address teamWallet) public onlyOwner {
        require(_teamWallet == address(0), "team wallet already set");
        require(teamWallet != address(0), "invalid team wallet");

        _teamWallet = teamWallet;
    }

    /**
     * @dev Set once the address where tokens for the bounty & marketing pool are issued to.
     * @param bountyWallet (Optional) address for bounty & marketing pool tokens
     */
    function setBountyWallet(address bountyWallet) public onlyOwner {
        require(_bountyWallet == address(0), "bounty wallet already set");
        require(bountyWallet != address(0), "invalid bounty wallet");

        _bountyWallet = bountyWallet;
    }

    /**
     * @dev Set once the address where tokens for the user rewards pool are issued to.
     * @param rewardsWallet (Optional) address for user rewards & reserves pool tokens
     */
    function setRewardsWallet(address rewardsWallet) public onlyOwner {
        require(_rewardsWallet == address(0), "reward wallet already set");
        require(rewardsWallet != address(0), "invalid rewards wallet");

        _rewardsWallet = rewardsWallet;
    }

    /**
     * @dev Returns the rate of tokens per wei.
     * @param weiAmount The consideration being rated
     * @return The number of tokens a buyer gets per wei
     */
    function getRate(uint256 weiAmount) public view returns (uint256 r) {
        if (!isOpen()) {
            return 0;
        }
        if (weiAmount >= BIG_PURCHASE_LIMIT) {
            r = _bigRate;
        } else if (weiAmount >= MID_PURCHASE_LIMIT) {
            r = _midRate;
        } else {
            r = rate();
        }
    }

    /**
     * @return the cap of the PreSale (in wei)
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised().add(_weiRaisedOffchain) >= _cap;
    }

    /**
     * @return the amount of wei raised which settled off-chain
     */
    function weiRaisedOffchain() public view returns (uint256) {
        return _weiRaisedOffchain;
    }

    /**
     * @return the Min contribution accepted (in wei)
     */
    function minContribution() public view returns (uint256) {
        return _minContribution;
    }

    /**
     * @return the address where tokens for the founders & team are issued to
     */
    function teamWallet() public view returns (address) {
        return _teamWallet;
    }

    /**
     * @return the address where tokens for the bounty & marketing pool are issued to
     */
    function bountyWallet() public view returns (address) {
        return _bountyWallet;
    }

    /**
     * @return the address where tokens for the user rewards and reserves pool are issued to
     */
    function rewardsWallet() public view returns (address) {
        return _rewardsWallet;
    }

    /**
     * @return the amount of tokens purchased for consideration paid
     */
    function purchasedTokens() public view returns (uint256) {
        return _purchasedTokens;
    }

    /**
     * @return the number of purchased tokens which already was accounted in
     * calculation of tokens for the Issuer.
     */
    function issuerTokenBase() public view returns (uint256) {
        return _issuerTokenBase;
    }

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param weiAmount The value in wei to be converted into tokens
     * @return The number of tokens the weiAmount will buy
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 currentRate = getRate(weiAmount);
        return currentRate.mul(weiAmount);
    }

    /**
     * @dev Extend parent behavior respecting the Min contribution.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiAmount >= _minContribution, "too small contribution");
        require(weiRaised().add(_weiRaisedOffchain).add(weiAmount) <= _cap, "cap exceeded");
    }

    /**
     * @dev Extend parent behavior locking the tokens just bought and
     * updating the amount of tokens purchased.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        super._processPurchase(beneficiary, tokenAmount);
        _lockTokens(beneficiary, tokenAmount);
        _purchasedTokens = _purchasedTokens.add(tokenAmount);
    }

    function _issueTokensToIssuer(
        uint256 teamTokensAmount,
        uint256 bountyTokensAmount,
        uint256 rewardsTokensAmount
    ) internal {
        _deliverTokens(_teamWallet, teamTokensAmount);
        _deliverTokens(_bountyWallet, bountyTokensAmount);
        _deliverTokens(_rewardsWallet, rewardsTokensAmount);
        emit TokensToIssuer(teamTokensAmount, bountyTokensAmount, rewardsTokensAmount);
    }

    function _lockTokens(address beneficiary, uint256 tokenAmount) private {
        ILockableToken token = ILockableToken(address(token()));
        require(token.lockIn(beneficiary, tokenAmount), "Tokens locking failed");
    }
}
