// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard } from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Decentralize stablecoin engine
 * @author anurag shingare
 * @notice This contract is the core of DSC system(DSCEngine).It handles all the logic to develop an Stablecoin(DSC)
 * @dev To develop an stablecoin we will require an contract(DSCEngine) that contains all functionality and methods.
 * @dev Our stable coin is DecentralizeStableCoin (DSC)
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
         a. Pegged on USD value
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
   error DSCEngine_TransactionFailed();

   // type declaration

   // tokenToPriceFeed
   mapping (address token => address priceFeed) private s_priceFeeds;
   // Manage the users deposit for particular token
   mapping (address user => mapping(address token => uint256 amount)) private s_userCollateralDeposit;
   // manage the minted DSC for user
   mapping (address user => uint256 amountDSCMinted) private s_amountDSCUserMinted;

   // state variables
   DecentralizeStableCoin private immutable i_dsc;

   // events
   event DSCEngine_depositCollateral(address indexed owner, address tokenCollateralAddress, uint256 indexed amount);

   // modifiers
   modifier zeroAmount(uint256 amount){
      if(amount <= 0){
         revert DSCEngine_ZeroAmountNotAllowed();
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
         if(tokenAddress.length != priceFeedAddress.length){
            revert DSCEngine_MismatchPriceFeedAddresses();
         }
         for(uint256 i=0;i<tokenAddress.length;i++){
            s_priceFeeds[tokenAddress[i]] = priceFeedAddresses[i];
         }
         i_dsc = DecentralizeStableCoin(dscAddress);
      }

   function depositCollateralAndMintDSC() external payable {}


   /** 
      @notice depositCollateral function
      @dev This function will deposit collateral(ETH/BTC) in our vault(smart contract)
      @dev We have implemented the check for 'Reentrant' attack using an 'nonReentrant' modifier
      @dev Implemented mapping type to store the deposit collateral amount for particular token(ETH/BTC).
   */ 
   function depositCollateral(address tokenCollateralAddress, uint256 amount) external zeroAmount(amount) nonReentrant {      
      if(s_priceFeeds[tokenCollateralAddress] == address(0)){
         revert DSCEngine_ZeroAddressNotAllowed(); 
      }

      s_userCollateralDeposit[msg.sender][tokenCollateralAddress] += amount;
      emit DSCEngine_depositCollateral(msg.sender,tokenCollateralAddress,amount);

      (bool success,) = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amount);
      if(!success){
         revert DSCEngine_TransactionFailed();
      }
   }

   /** 
      @notice depositCollateral function
      @dev This function will deposit collateral(ETH/BTC) in our vault(smart contract)
      @dev We have implemented the check for 'Reentrant' attack using an 'nonReentrant' modifier
      @dev Implemented mapping type to store the deposit collateral amount for particular token(ETH/BTC).
   */
   function mintDSC(uint256 amountDSCToMint) external zeroAmount(amountDSCToMint) nonReentrant {
      s_amountDSCUserMinted[msg.sender] += amountDSCToMint;
      // function to check minted DSC value in $ < deposited ETH

   }

   function reedemDSCForCollateral() external {}

   function reedemDSC() external {}


   function burnDSC() external {}

   function liquidate() external {}

   function getHealthFactor() external {}



   // Internal functions
   function _getUserInfo(address user) internal view returns(uint256 totalDSCMinted,uint256 collateralValueInUSD){
      totalDSCMinted = s_amountDSCUserMinted[user];
      collateralValueInUSD = s_userCollateralDeposit[user];
   }
   function _getHealthFactor(address user) private view returns(uint256){

   }
   function _revertIfHealthFactorOfUserIsNotGood() internal view {
      // check the health factor (check user have enough ETH!!!)
      revert();
   }
}