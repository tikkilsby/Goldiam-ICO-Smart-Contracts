pragma solidity ^0.4.11;

import '../token/MintableToken.sol';
import '../SafeMath.sol';
import '../Ownable.sol';
/**
 * @title Goldiam Crowdsale
 * @author Talha Yusuf || Junaid Mushtaq || Hamza Yasin
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  MintableToken private token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public preIcoStartTime;
  uint256 public preIcoEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
  // Bonuses will be calculated here of ICO and Pre-ICO (both inclusive)
  uint256 private preSaleBonus;
  uint256 private preICOBonus;
  uint256 private firstWeekBonus;
  uint256 private secondWeekBonus;
  uint256 private thirdWeekBonus;
  
  
  // wallet address where funds will be saved
  address internal wallet;
  
  // base-rate of a particular Goldiam token
  uint256 public rate;

  // amount of raised money in wei
  uint256 internal weiRaised;

  // Weeks in UTC
  uint256 weekOne;
  uint256 weekTwo;
  uint256 weekThree;
  
  // total supply of token 
  uint256 public totalSupply = 32300000 * 1 ether;
  // public supply of token 
  uint256 public publicSupply = 28300000 * 1 ether;
  // reward supply of token 
  uint256 public reserveSupply = 3000000 * 1 ether;
  // bounty supply of token 
  uint256 public bountySupply = 1000000 * 1 ether;
  // preSale supply of the token
  uint256 public preSaleSupply = 8000000 * 1 ether;
  // preICO supply of token 
  uint256 public preicoSupply = 8000000 * 1 ether;
  // ICO supply of token 
  uint256 public icoSupply = 12300000 * 1 ether;
  // Remaining Public Supply of token 
  uint256 public remainingPublicSupply = publicSupply;
  // Remaining Bounty Supply of token 
  uint256 public remainingBountySupply = bountySupply;
  // Remaining company Supply of token 
  uint256 public remainingReserveSupply = reserveSupply;
  /**
   *  @bool checkBurnTokens
   *  @bool upgradeICOSupply
   *  @bool grantCompanySupply
   *  @bool grantAdvisorSupply     
  */
  bool private checkBurnTokens;
  bool private upgradePreICOSupply;
  bool private upgradeICOSupply;
  bool private grantReserveSupply;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // Goldiam Crowdsale constructor
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    // Goldiam token creation 
    token = createTokenContract();

    // Pre-sale start Time
    preStartTime = now;
    
    // Pre-sale end time
     preEndTime = preStartTime + 5 minutes;

    // Pre-ICO start time
    preIcoStartTime = preEndTime;

    // Pre-ICO end time
    preIcoEndTime = preIcoStartTime + 5 minutes;

    // // ICO start Time
     ICOstartTime = preIcoEndTime;

    // ICO end Time
    ICOEndTime = ICOstartTime + 15 minutes;

    // Base Rate of GOL Token
    rate = _rate;

    // Multi-sig wallet where funds will be saved
    wallet = _wallet;

    /** Calculations of Bonuses in ICO or Pre-ICO */
    preSaleBonus = SafeMath.div(SafeMath.mul(rate,30),100); 
    preICOBonus = SafeMath.div(SafeMath.mul(rate,25),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);

    /** ICO bonuses week calculations 604800 */
    weekOne = SafeMath.add(ICOstartTime, 3 minutes);
    weekTwo = SafeMath.add(weekOne, 3 minutes);
    weekThree = SafeMath.add(weekTwo, 3 minutes);

    checkBurnTokens = false;
    upgradePreICOSupply = false;
    upgradeICOSupply = false;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);  
  }

  // High level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    // minimum investment should be 0.10 ETH 
    require(weiAmount >= 0.10 * 1 ether);
    
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 supplyTokens = 0;
    uint256 bonusTokens = 0;
  // calculating the Pre-Sale, Pre-ICO and ICO bonuses on the basis of timing
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) {
        require(preSaleSupply > 0);
        
        bonusTokens = SafeMath.add(bonusTokens, weiAmount.mul(preSaleBonus));
        supplyTokens = SafeMath.add(supplyTokens, weiAmount.mul(rate));
        tokens = SafeMath.add(bonusTokens, supplyTokens);
        
        require(preSaleSupply >= supplyTokens);
        require(icoSupply >= bonusTokens);

        preSaleSupply = preSaleSupply.sub(supplyTokens);
        icoSupply = icoSupply.sub(bonusTokens);
        remainingPublicSupply = remainingPublicSupply.sub(tokens);

    }else if ((accessTime >= preIcoStartTime) && (accessTime < preIcoEndTime)) {

        if (!upgradePreICOSupply) {
          preicoSupply = preicoSupply.add(preSaleSupply);
          upgradePreICOSupply = true;
        }
        require(preicoSupply > 0);

        bonusTokens = SafeMath.add(bonusTokens, weiAmount.mul(preICOBonus));
        supplyTokens = SafeMath.add(supplyTokens, weiAmount.mul(rate));
        tokens = SafeMath.add(bonusTokens, supplyTokens);
        
        require(preicoSupply >= supplyTokens);
        require(icoSupply >= bonusTokens);

        preicoSupply = preicoSupply.sub(supplyTokens);
        icoSupply = icoSupply.sub(bonusTokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);

    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
        if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        require(icoSupply > 0);

        if ( accessTime <= weekOne ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwo) {
          tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
        } else if ( accessTime < weekThree ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else {
      revert();
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);
    // tokens are minting here
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    // funds are forwarding
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens

  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }

  // @return true if burnToken function has ended
  function burnToken() onlyOwner public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    checkBurnTokens = true;
    token.burnTokens(remainingPublicSupply);
    totalSupply = SafeMath.sub(totalSupply, remainingPublicSupply);
    remainingPublicSupply = 0;
    preSaleSupply = 0;
    preicoSupply = 0;
    icoSupply = 0;

    return true;
  }

  /** 
     * @return true if bountyFunds function has ended
     * @param beneficiary address where owner wants to transfer tokens
     * @param valueToken value of token
  */
  function bountyFunds(address beneficiary, uint256 valueToken) onlyOwner public { 

    valueToken = SafeMath.mul(valueToken, 1 ether);
    require(remainingBountySupply >= valueToken);
    remainingBountySupply = SafeMath.sub(remainingBountySupply,valueToken);
    token.mint(beneficiary, valueToken);
  } 

  /**
      @return true if grantRewardToken function has ended  
  */
    function grantRewardToken() onlyOwner public {

    require(!grantReserveSupply);
    grantReserveSupply = true;
    token.mint(0x00000000000000000000000000000000, remainingReserveSupply);
    
    remainingReserveSupply = 0;
    
  }

/** 
   * Function transferToken works to transfer tokens to the specified address on the
     call of owner within the crowdsale timestamp.
   * @param beneficiary address where owner wants to transfer tokens
   * @param tokens value of token
 */
  function transferToken(address beneficiary, uint256 tokens) onlyOwner public {

    require(ICOEndTime > now);
    tokens = SafeMath.mul(tokens,1 ether);
    require(remainingPublicSupply >= tokens);
    remainingPublicSupply = SafeMath.sub(remainingPublicSupply,tokens);
    token.mint(beneficiary, tokens);

  }

  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }

  function getPublicSupply() onlyOwner public returns (uint256) {
    return remainingPublicSupply;
  }
}

