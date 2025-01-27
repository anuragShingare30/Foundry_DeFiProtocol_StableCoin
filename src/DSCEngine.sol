// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard } from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Decentralize stablecoin engine
 * @author anurag shingare
 * @notice This contract is the core of DSC system(DSCEngine).It handles all the logic to develop an Stablecoin(DSC)
 * @dev To develop an stablecoin we will require an contract(DSCEngine) that contains all functionality and methods.
 * @dev Our stable coin is DecentralizeStableCoin (DSC).
 * @dev The flow of developing an Stablecoin(DSC) will be as followed:
         a. Deploy the ERC20 Token Contract(Minting,Burning,checkBalance)
            - Basic ERC-20 token standard to ensure basic functionality!!
         b. Implement Collateral Deposit (Deposit collateral(ETH/BTC) to get DSC)
         c. Mint Stablecoins (System will mint DSC for depositing collateral ETH)
         d. Price Oracle Integration (system always calculates the correct collateral value in USD)
            - Implements chainlink data feeds to fetch current USD price to peg our DSC close to $1.
         e. Implement Peg Stability Mechanism (Create a mechanism to keep the stablecoin value close to $1)
            - System can mint
            - System can burn
         f. Redemption of Stablecoins (Allow users to redeem their DSC for ETH at the pegged $1 value)
         g. Liquidation System (Protect the system from ETH price drops)
 * @dev Our Stablecoin (DSC) is categorized as:
         a. Pegged by USD value
         b. Algorithmic stability method (Minting,Burning)
         c. Exogenously collateralized by ETH/BTC
         d. Our system should always be "over-collateralized"
            - collateral value in USD > DSC value in USD 
   
   @dev Contract should follows:
      a. Checks
      b. Effects
      c. Interaction
 */



contract DSCEngine is ReentrancyGuard,Ownable{
   //  error
   error DSCEngine_ZeroAmountNotAllowed();
   error DSCEngine_MismatchPriceFeedAddresses();
   error DSCEngine_ZeroAddressNotAllowed();
   error DSCEngine_StableCoinValueCannotBeGreaterThanItsCollateralValue();
   error DSCEngine_BreaksHealthFactor();
   error DSCEngine_TransactionFailed();
   error DSCEngine_InvalidTypeOfCollateralUsed();
   error DSCEngine_NoNeedToLiquidateUser();
   error DSCEngine_HealthfactorOfUserNotImproved();
   error DSCEngine_depositCollateralFailed();
   error DSCEngine_mintDSCFailed();
   error DSCEngine_reedemCollateralFailed();
   error DSCEngine_burnDSCFailed();


   // type declaration

   // (WETH/WBTC) contract address to pricefeed!!!
   mapping (address collateralAddress => address priceFeed) private s_priceFeeds;
   // Manage the users deposit for particular token(WETH/WBTC)
   mapping (address user => mapping(address collateralAddress => uint256 amount)) private s_userCollateralDeposit;
   // manage the minted DSC for user
   mapping (address user => uint256 amountDSCMinted) private s_amountDSCUserMinted;
   // Storing all collateral address in an array so we can add different collateral value
   address[] private s_collateralAddresses;


   // state variables
   uint256 private constant PRICE_FEED_SCALE_FACTOR = 1e10;
   uint256 private constant TOKEN_DECIMAL_STANDARD = 1e18;
   uint256 private constant LIQUIDATION_THRESHOLD = 50; // x% over collateralized
   uint256 private constant MINIMUM_HEALTH_FACTOR = 1;
   uint256 private constant DISCOUNT_PRICE = 10;
   uint256 private constant PRECESION = 100;
   uint256 private constant LIQUIDATION_PRECESION = 1e18;
   // DSC contract instance!!!
   DecentralizeStableCoin private immutable i_dsc;


   // events
   event DSCEngine_depositCollateral(address indexed owner, address tokenCollateralAddress, uint256 indexed amount);
   event DSCEngine_mintDSC(address user,uint256 amountDSCMinted);
   event DSCEngine_reedemDSC(address indexed from,address indexed to,address tokenCollateralAddress,uint256 amount);
   event DSCEngine_burnDSC(address indexed owner, uint256 amount);

   // modifiers
   modifier zeroAmount(uint256 amount){
      if(amount <= 0){
         revert DSCEngine_ZeroAmountNotAllowed();
      }
      _;
   }
   modifier isValidCollateralType(address token){
      if(s_priceFeeds[token] == address(0)){
         revert DSCEngine_InvalidTypeOfCollateralUsed();
      }
      _;
   }

   // External functions
   constructor(
      address[] memory tokenAddress,
      address[] memory priceFeedAddresses,
      address dscAddress   
   ) 
      Ownable(msg.sender){
         if(tokenAddress.length != priceFeedAddresses.length){
            revert DSCEngine_MismatchPriceFeedAddresses();
         }
         for(uint256 i=0;i<tokenAddress.length;i++){
            s_priceFeeds[tokenAddress[i]] = priceFeedAddresses[i];
            s_collateralAddresses.push(tokenAddress[i]);
         }
         i_dsc = DecentralizeStableCoin(dscAddress);
      }




   /**
      @notice depositCollateralAndMintDSC function
      @dev This function combines the flow of depositCollateral() and mintDSC() functions
      @param tokenCollateralAddress Contract address of token deposited by user(WETH/WBTC)
      @param amount amount of Collateral deposited by user
      @param amountDSCToMint The value of DSC user wants to mint
      @notice This function will deposit Collateral and mint DSC in one transaction!!!
    */
   function depositCollateralAndMintDSC(
      address tokenCollateralAddress,
      uint256 amount,
      uint256 amountDSCToMint
   ) external payable {
      depositCollateral(tokenCollateralAddress, amount);
      mintDSC(amountDSCToMint);
   }


   /** 
      @notice depositCollateral function
      @param tokenCollateralAddress Contract address of token deposited by user(WETH/WBTC)
      @param amount Collateral deposited by user
      @dev a feature where users can deposit ETH into a smart contract.
      @dev  For every deposit, calculate how much stablecoin can be issued based on the USD value of ETH.
      @dev  If 1 ETH = $1500 and you have a 150% collateralization ratio, a user depositing 1 ETH can mint 1000 stablecoins.
   */ 
   function depositCollateral(address tokenCollateralAddress, uint256 amount) public zeroAmount(amount) isValidCollateralType(tokenCollateralAddress) nonReentrant {      
      s_userCollateralDeposit[msg.sender][tokenCollateralAddress] += amount;
      emit DSCEngine_depositCollateral(msg.sender,tokenCollateralAddress,amount);

      bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amount);
      if(!success){
         revert DSCEngine_depositCollateralFailed();
      }
   }

   /** 
      @notice mint stablecoin function
      @param amountDSCToMint The value of DSC user wants to mint
      @dev When a user deposits ETH, allow the system to mint and send the equivalent amount of stablecoins to their wallet.
      @dev We have implemented the check for 'Reentrant' attack using an 'nonReentrant' modifier
      @dev This step links ETH collateral with the stablecoin supply.
         $200 ETH(deposited) -> $20 DSC(mint)
   */
   function mintDSC(uint256 amountDSCToMint) public zeroAmount(amountDSCToMint) nonReentrant {
      s_amountDSCUserMinted[msg.sender] += amountDSCToMint;
      _revertIfHealthFactorOfUserBreaks(msg.sender);
      bool success = i_dsc.mint(msg.sender, amountDSCToMint);
      if(!success){
         revert DSCEngine_mintDSCFailed();
      }

      emit DSCEngine_mintDSC(msg.sender,amountDSCToMint);   
   }


   /** 
      @notice redeemCollateralForDsc function
      @param tokenCollateralAddress Contract address of token deposited by user(WETH/WBTC)
      @param amountCollateral The amount of collateral user wants to redeem
      @param amountDSC Amount of DSC user wants to burn.
      @notice redeemCollateralForDsc function will combinely execute the functions in redeem flow
      @dev The flow which we will follow for redeeming is:
         a. Check User's Collateral Balance
         b. After redeeming collateral, Health factor should be greater than 1
         c. Redemption Amount should be greater than zero and Reentrancy Guard and Collateral Type Validity
         d. Sufficient Collateral balance in contract
         e. Burn Stablecoins Before Redemption
   */
   function redeemCollateralForDsc(
      address tokenCollateralAddress,
      uint256 amountCollateral,
      uint256 amountDSC
   ) external zeroAmount(amountCollateral) isValidCollateralType(tokenCollateralAddress) {

      _burnDSC(amountDSC, msg.sender, msg.sender);
      _reedemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
      _revertIfHealthFactorOfUserBreaks(msg.sender);
   }


   /** 
      @notice reedemCollateral function
      @param tokenCollateralAddress Contract address of token deposited by user(WETH/WBTC)
      @param amountCollateral The value of collateral user wants to redeem
      @dev Allow users to redeem their stablecoins for ETH at the pegged $1 value.
      @dev When a user redeems collateral, burn the stablecoins and release the corresponding ETH from the collateral pool.
   */
   function reedemCollateral(
      address tokenCollateralAddress,
      uint256 amountCollateral
   ) public zeroAmount(amountCollateral) isValidCollateralType(tokenCollateralAddress) nonReentrant{
      _reedemCollateral(tokenCollateralAddress, amountCollateral,msg.sender,msg.sender);
      _revertIfHealthFactorOfUserBreaks(msg.sender);
   }

   /** 
      @notice burnDSC function
      @param amount Amount of DSC user wants to redeem.
      @dev The user should burn the amount of DSC equivalent to the value of the collateral they want to redeem.
      @dev This reduces the circulating supply of the stablecoin.
   */
   function burnDSC(uint256 amount) public zeroAmount(amount) {
      _burnDSC(amount, msg.sender, msg.sender);
      _revertIfHealthFactorOfUserBreaks(msg.sender);
   }


   /** 
      @notice liquidate system function
      @param collateral The ERC20 token address of the collateral you're using to make the protocol solvent again.
      @param user The user who needs to get liquidated
      @param debtAmount The amount of DSC(Ex:100 DSC) you want to burn to cover the user's debt.(partially/fully)

      @notice We will partially liquidate the user
      @notice The Liquidator(msg.sender) will get 10% discount on users collateral value
      @dev The flow we will follow for liquidation system is:
         a. Check the users health factor validity
         b. Check the debtAmount liquidator needs to pay ($100 worth of DSC)
         c. liquidator pays partial debt of user ($50 worth of DSC)
         d. liquidator gets the 10% of debt he pays from user. ($50.0 * 1.1 == $55.0)
         e. This results:
            1. User losses $55 worth of DSC
            2. debt reduced from ($100) to ($50)
            3. Health factor of user improved
            4. Liquidator burn $50 worth of DSC and earns $55 worth of ETH for 10% discount
            5. System remains stable and solvent
      
   */
   function liquidate(
      address collateral,
      address user,
      uint256 debtAmount
   ) public isValidCollateralType(collateral) zeroAmount(debtAmount) nonReentrant {

      // check the validity for user to get liquidate
      uint256 startingUserHealthFactor = _getHealthFactor(user);
      if(startingUserHealthFactor > MINIMUM_HEALTH_FACTOR){
         revert DSCEngine_NoNeedToLiquidateUser();
      }

      // get debtAmount in collateral
      // debtAmount -> $100 worth of DSC == 100 wei
      // debtAmountInUsd -> $100 worth of ETH
      uint256 debtAmountInUsd = getDebtAmountInUsd(collateral,debtAmount);

      // get the total amount with 10% discount user need to pay to liquidator
      // debtAmountInUsd -> $100
      // totalAmountOfDebt == ($100) + ($100 * 0.1) == $110 worth of ETH
      uint256 totalAmountOfDebt = ((debtAmountInUsd) + ((debtAmountInUsd * DISCOUNT_PRICE)/PRECESION));

      // transfer the total collateral amount to liquidator
      // user will redeem collateral for DSC
      // and, burn that much amount of DSC
      _reedemCollateral(collateral, totalAmountOfDebt, user, msg.sender);
      _burnDSC(debtAmount, user, msg.sender);

      // check the ending health factor
      uint256 endingUserHealthfactor = _getHealthFactor(user);
      if(endingUserHealthfactor <= startingUserHealthFactor){
         revert DSCEngine_HealthfactorOfUserNotImproved();
      }
      _revertIfHealthFactorOfUserBreaks(user);
   }

   function getHealthFactor() public {}


   
   // Internal functions

   function _getUserInfo(address user) internal view returns(uint256 totalDSCMinted,uint256 collateralValueInUSD){
      totalDSCMinted = s_amountDSCUserMinted[user];
      collateralValueInUSD = getUserCollateralValue(user);
   }

   function _getHealthFactor(address user) private view returns(uint256 healthFactor){
      (uint256 totalDSCMinted, uint256 collateralValueInUSD) = _getUserInfo(user);
      if(totalDSCMinted >= collateralValueInUSD){
         revert DSCEngine_StableCoinValueCannotBeGreaterThanItsCollateralValue();
      }
      uint256 collateralAdjustedForThreshold = ((collateralValueInUSD * LIQUIDATION_THRESHOLD) / PRECESION);
      return ((collateralAdjustedForThreshold * PRICE_FEED_SCALE_FACTOR) / totalDSCMinted);
   }

   function _revertIfHealthFactorOfUserBreaks(
      // address tokenCollateralAddress,
      address user) 
      internal view returns(uint256){
      // check the health factor (check user have enough ETH!!!)
      // A (userHealthFactor > 1) means the user is safely collateralized.
      // A (userHealthFactor ≤ 1) means the user is undercollateralized, they need to be liquidated.
      uint256 userHealthFactor = _getHealthFactor(user);
      if(userHealthFactor <= MINIMUM_HEALTH_FACTOR){
         revert DSCEngine_BreaksHealthFactor();
      }
      return userHealthFactor;
   }


   // Private functions

   function _reedemCollateral(
      address tokenCollateralAddress,
      uint256 amountCollateral,
      address from,
      address to
   ) private zeroAmount(amountCollateral) isValidCollateralType(tokenCollateralAddress) nonReentrant {
      s_userCollateralDeposit[from][tokenCollateralAddress] -= amountCollateral;
      emit DSCEngine_reedemDSC(from,to,tokenCollateralAddress,amountCollateral);

      bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
      if(!success){
         revert DSCEngine_reedemCollateralFailed();
      }
   }

   function _burnDSC(
      uint256 amount,
      address onBehalfOf,
      address dscFrom
   ) private zeroAmount(amount){
      s_amountDSCUserMinted[onBehalfOf] -= amount;
      emit DSCEngine_burnDSC(onBehalfOf,amount);

      bool success = i_dsc.transferFrom(dscFrom, address(this), amount);
      if(!success){
         revert DSCEngine_burnDSCFailed();
      }

      i_dsc.burn(amount);
   }



   // getter function

   function getUserCollateralValue(address user) public view returns(uint256 totalCollateralValueInUSD){
      for(uint256 i=0;i<s_collateralAddresses.length;i++){
         address collateralAddress = s_collateralAddresses[i];
         uint256 amount = s_userCollateralDeposit[user][collateralAddress];
         totalCollateralValueInUSD += getUSDValue(collateralAddress,amount);
      }
   }

   // Converts ETH(wei) to USD value
   // 1e18 wei -> $3427.89
   function getUSDValue(address collateralAddress,uint256 amount) public view returns(uint256){
      AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[collateralAddress]);
      (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
      
      // (price * 1e10 * amountInETH) / 1e18  == $3426.09737...
      return (((uint256(price) * PRICE_FEED_SCALE_FACTOR) * amount ) / TOKEN_DECIMAL_STANDARD);
   }

   // Converts USD amount(debt in wei) to collateral(ETH) token amount
   // $100 -> 0.05 ether
   // 100 1e18 -> 5e16
   function getDebtAmountInUsd(address collateral,uint256 amount) public view returns(uint256 debtAmountInUsd){
      AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[collateral]);
      (,int price,,,) = priceFeed.latestRoundData();

      // amount(wei) -> 100 * 1e18
      // LIQUIDATION_PRECESION -> 1e18
      // price(from chainlink) -> 200000000 == 2 * 1e8
      // PRICE_FEED_SCALE_FACTOR -> 1e10
      debtAmountInUsd = (amount * LIQUIDATION_PRECESION) / (uint256(price) * PRICE_FEED_SCALE_FACTOR);
   }

   function getUserCollateralDeposit(address tokenAddress) public view returns(uint256){
      return s_userCollateralDeposit[msg.sender][tokenAddress];
   }

   function getAmountDSCUserMinted() public view returns(uint256){
      return s_amountDSCUserMinted[msg.sender];
   }


}