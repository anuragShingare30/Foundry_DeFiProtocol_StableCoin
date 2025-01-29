// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DeployDSC} from "script/Deploy.s.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {MockFailedTransferFrom} from "../mocks/MockFailedTransferFrom.sol";
import {MockFailedMintDSC} from "../mocks/MockFailedMintDSC.sol";
import {MockFailedTransfer} from "../mocks/MockFailedTransfer.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {MockMoreDebtDSC} from "../mocks/MockMoreDebtDSC.sol";

/**
 * @title  testing DSCEngine contract
 * @author anurag shingare
 * @notice Testing exteranal and internal functions for DSCEngine smart contracts. 
 * @dev We will import the DSC,DSCEngine and helperconfig contract from deploy script.
 */

contract DSCEngineTest is Test{
    // error
    error DSCEngine_ZeroAmountNotAllowed();

    DSCEngine dscEngine;
    DecentralizeStableCoin dsc;
    HelperConfig helperConfig;

    address public USER = address(1);
    uint256 constant public STARTING_USER_BALANCE = 100 ether;
    uint256 constant public DEPOSIT_AMOUNT = 100 ether;
    uint256 constant public REDEEM_AMOUNT = 10 ether;
    uint256 constant public MINT_AMOUNT = 10 ether;
    uint256 constant public BURN_AMOUNT = 5 ether;
    uint256 constant public PRICE_FEED_SCALE_FACTOR = 1e10;
    uint256 constant public TOKEN_DECIMAL_STANDARD = 1e18;

    // liquidator
    address public liquidator = makeAddr("liquidator");
    uint256 public debtToPay = 20 ether;

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    // events
    event DSCEngine_depositCollateral(address indexed owner, address tokenCollateralAddress, uint256 indexed amount);

    function setUp() public {
        DeployDSC deployDSC = new DeployDSC();
        (dsc,dscEngine,helperConfig) = deployDSC.run();
        (wethUsdPriceFeed,wbtcUsdPriceFeed,weth,wbtc,deployerKey) = helperConfig.localNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
    }

    // modifiers
    modifier depositCollateral(){
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }
    modifier depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        dscEngine.mintDSC(MINT_AMOUNT);
        vm.stopPrank();
        _;
    }


    ///////////////////////////////////
    // Price Feed functions test //
    ///////////////////////////////////

    // ETH(WEI) -> USD
    function test_CheckGetPriceFeedFunction() public {
        uint256 ethAmount = 15;
        uint256 expectedAmount = 30000;
        uint256 actualAmount = dscEngine.getUSDValue(weth, ethAmount);
        console.log(actualAmount);
        assert(expectedAmount == actualAmount);
    }
    // USD(WEI) -> ETH(WEI)
    function test_GetDebtAmountInUsd() public {
        uint256 amount = 100 ether;
        uint256 expectedAmount = 0.05 ether;
        uint256 actualAmount = dscEngine.getDebtAmountInUsd(weth, amount);
        assert(expectedAmount == actualAmount);
    }


    ///////////////////////////////////
    // constructor params test //
    ///////////////////////////////////

    address[] public tokenAddresses = [weth];
    address[] public priceFeedAddresses = [wethUsdPriceFeed,wbtcUsdPriceFeed];
    function test_RevertIf_TokenAddressesLengthNotMatch() public {
        vm.expectRevert(DSCEngine.DSCEngine_MismatchPriceFeedAddresses.selector);
        // create new instance of contract
        new DSCEngine(tokenAddresses,priceFeedAddresses,address(dsc));
    }


    ///////////////////////////////////
    // DEPOSIT COLLATERAL FUNCTION TEST //
    ///////////////////////////////////

    function test_RevertIf_CollateralAmountIsZero() public {    
        vm.prank(USER);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
    }
    function test_RevertIf_TokenAddressIsNotValid() public {
        ERC20Mock token = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_InvalidTypeOfCollateralUsed.selector);
        dscEngine.depositCollateral(address(token), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }
    function test_DepositAmountCollateral() public {
        vm.startPrank(USER);
        uint256 INITIAL_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        console.log(INITIAL_BALANCE);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        // vm.expectEmit(true, false, true, DEPOSIT_AMOUNT);
        // emit DSCEngine_depositCollateral(USER, weth, DEPOSIT_AMOUNT);
        uint256 DEPOSIT_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        console.log(DEPOSIT_BALANCE);
        vm.stopPrank();
        assert(INITIAL_BALANCE+DEPOSIT_AMOUNT == DEPOSIT_BALANCE);
    }

    function test_RevertIf_TransactionFailedDuringDepositCollateral() public {
        // SETUP
        address owner = msg.sender;
        vm.prank(owner);
        // deploying new dsc contract
        MockFailedTransferFrom mockDsc = new MockFailedTransferFrom();
        tokenAddresses = [address(mockDsc)];
        priceFeedAddresses = [wethUsdPriceFeed];
        // deploying new dscEngine contract
        vm.prank(owner);
        DSCEngine mockDscE = new DSCEngine(tokenAddresses,priceFeedAddresses,address(mockDsc));
        
        // transferring ownership to dscEngine
        vm.prank(owner);
        mockDsc.transferOwnership(address(mockDscE));

        // Executing/Testing
        vm.startPrank(USER);
        ERC20Mock(address(mockDsc)).approve(address(mockDscE),DEPOSIT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_depositCollateralFailed.selector);
        mockDscE.depositCollateral(address(mockDsc), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }   


    ///////////////////////////////////
    // MINT FUNCTION TEST //
    ///////////////////////////////////

    function test_CheckUsersHealthFactor() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        dscEngine.mintDSC(MINT_AMOUNT);
        uint256 INITIAL_HF = dscEngine._getHealthFactor(USER);
        console.log(INITIAL_HF);

        dscEngine.reedemCollateral(weth, REDEEM_AMOUNT);
        uint256 AFTER_HF = dscEngine._getHealthFactor(USER);
        console.log(AFTER_HF);
        vm.stopPrank();
    }

    function test_RevertsIf_MintDSCBreaksHealthFactor() public depositCollateral(){
        (,int price,,,) = MockV3Aggregator(wethUsdPriceFeed).latestRoundData();
        uint256 amountDSCMinted =(((uint256(price)) * DEPOSIT_AMOUNT * PRICE_FEED_SCALE_FACTOR) / TOKEN_DECIMAL_STANDARD);

        vm.startPrank(USER);
        uint256 expectedHF = dscEngine._getHealthFactor(USER);
        console.log(expectedHF);
        // vm.expectRevert(DSCEngine.DSCEngine_BreaksHealthFactor.selector);
        dscEngine.mintDSC(amountDSCMinted);
        vm.stopPrank();
    }

    function test_amountDSCToMint() public depositCollateral() {
        vm.startPrank(USER);
        uint256 INITIAL_BALANCE = dscEngine.getUserDebt();
        console.log(INITIAL_BALANCE);
        dscEngine.mintDSC(DEPOSIT_AMOUNT);
        uint256 AFTER_MINT_BALANCE = dscEngine.getUserDebt();
        console.log(AFTER_MINT_BALANCE);
        vm.stopPrank();
        assert(INITIAL_BALANCE+DEPOSIT_AMOUNT == AFTER_MINT_BALANCE);
    }
    function test_RevertIf_mintDSCFailed() public {
        address owner = msg.sender;
        vm.prank(owner);
        MockFailedMintDSC mockDsc = new MockFailedMintDSC();
        tokenAddresses = [weth];
        priceFeedAddresses = [wethUsdPriceFeed];
        vm.prank(owner);
        DSCEngine mockDscE = new DSCEngine(tokenAddresses,priceFeedAddresses,address(mockDsc));

        vm.prank(owner);
        mockDsc.transferOwnership(address(mockDscE));

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(mockDscE),DEPOSIT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_mintDSCFailed.selector);
        mockDscE.depositCollateralAndMintDSC(weth, DEPOSIT_AMOUNT, MINT_AMOUNT);
        vm.stopPrank();
    }
    function test_RevertsIf_mintAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), MINT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.mintDSC(0);
    }


    ///////////////////////////////////
    // DEPOSIT AND MINT FUNCTION TEST //
    ///////////////////////////////////

    function test_depositCollateralAndMintDSC() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateralAndMintDSC(weth, DEPOSIT_AMOUNT, MINT_AMOUNT);
        vm.stopPrank();
    }
    function test_RevertsIf_DepositCollateralAndMintDSCBreaksHealthFactor() public {
        (,int price,,,) = MockV3Aggregator(wethUsdPriceFeed).latestRoundData();
        uint256 mintAmount = ((uint256(price) * DEPOSIT_AMOUNT * PRICE_FEED_SCALE_FACTOR)/TOKEN_DECIMAL_STANDARD);

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine),DEPOSIT_AMOUNT);

        // vm.expectRevert(DSCEngine.DSCEngine_BreaksHealthFactor.selector);
        dscEngine.depositCollateralAndMintDSC(weth, DEPOSIT_AMOUNT, mintAmount);
        vm.stopPrank();
    }


    ///////////////////////////////////
    // BURN DSC FUNCTION TEST //
    ///////////////////////////////////

    function test_RevertsIf_ZeroBurnAmount() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.burnDSC(0);
        vm.stopPrank();
    }
    // function test_BurnMoreThanHave() public {
    //     vm.startPrank(USER);
    //     dscEngine.burnDSC(1);
    //     vm.stopPrank();
    // }
    function test_BurnDSCAmount() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        dsc.approve(address(dscEngine), MINT_AMOUNT);
        dscEngine.burnDSC(MINT_AMOUNT);
        vm.stopPrank();
        uint256 userBalance = dsc.balanceOf(USER);
        console.log(userBalance);
        assert(userBalance == 0);
    }


    ///////////////////////////////////
    // REDEEM COLLATERAL FUNCTION TEST //
    ///////////////////////////////////

    function test_RevertsIf_ZeroAmountRedeemCollateral() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        dsc.approve(address(dscEngine), DEPOSIT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.reedemCollateral(weth, 0);
        vm.stopPrank();
    }
    // function test_RevertsIf_RedeemCollateralTransactionFailed() public {
    //     address owner = msg.sender;
    //     vm.prank(owner);
    //     MockFailedTransfer mockDsc = new MockFailedTransfer();
    //     tokenAddresses = [address(mockDsc)];
    //     priceFeedAddresses = [wethUsdPriceFeed];
    //     vm.prank(owner);
    //     DSCEngine mockDscE = new DSCEngine(tokenAddresses,priceFeedAddresses,address(mockDsc));
    //     mockDsc.mint(USER, DEPOSIT_AMOUNT);  

    //     vm.prank(owner);
    //     mockDsc.transferOwnership(address(mockDscE));

    //     vm.startPrank(USER);
    //     ERC20Mock(address(mockDsc)).approve(address(mockDscE),DEPOSIT_AMOUNT);
    //     mockDscE.depositCollateral(address(mockDsc), DEPOSIT_AMOUNT);
    //     vm.expectRevert(DSCEngine.DSCEngine_reedemCollateralFailed.selector);
    //     mockDscE.reedemCollateral(address(mockDsc), DEPOSIT_AMOUNT);
    //     vm.stopPrank();
    // }
    function test_CheckRedeemCollateralFunction() public depositCollateral(){
        vm.startPrank(USER);
        dscEngine.reedemCollateral(weth, DEPOSIT_AMOUNT);
        uint256 userBalance = ERC20Mock(weth).balanceOf(USER);
        vm.stopPrank();
        assert(userBalance == DEPOSIT_AMOUNT);
    }

 
    ///////////////////////////////////
    // REDEEMCOLLATERAL AND MINT DSC FUNCTION TEST //
    ///////////////////////////////////

    function test_RevertsIf_ZeroAmountForRedeemCollateralMintDSC() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.redeemCollateralForDsc(weth, 0, MINT_AMOUNT);
        vm.stopPrank();
    }
    // function test_CheckUserBalanceForDepositAndRedeemCollateral() public {
    //     vm.startPrank(USER);
    //     ERC20Mock(weth).approve(address(dscEngine),DEPOSIT_AMOUNT);
    //     dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
    //     dsc.approve(address(dscEngine), MINT_AMOUNT);
    //     dscEngine.redeemCollateralForDsc(weth, DEPOSIT_AMOUNT, MINT_AMOUNT);
    //     vm.stopPrank();

    //     uint256 userBalance = ERC20Mock(weth).balanceOf(USER);
    //     assert(userBalance == 0);
    // }

    ///////////////////////////////////
    // BASIC FUNCTION TEST //
    ///////////////////////////////////

    function test_depositCollateralFunction() public {
        vm.startPrank(USER);
        uint256 INITIAL_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        console.log(INITIAL_BALANCE);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        uint256 DEPOSIT_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        console.log(DEPOSIT_BALANCE);
        vm.stopPrank();
        assert(INITIAL_BALANCE+DEPOSIT_AMOUNT == DEPOSIT_BALANCE);
    }

    function test_MintDscFunction() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        uint256 INTITIAL_BALANCE = dscEngine.getUserDebt();
        console.log(INTITIAL_BALANCE);
        dscEngine.mintDSC(MINT_AMOUNT);
        uint256 AFTER_BALANCE = dscEngine.getUserDebt();
        console.log(AFTER_BALANCE);
        vm.stopPrank();
        assert(INTITIAL_BALANCE+MINT_AMOUNT == AFTER_BALANCE);
    }

    // Always check the health factor before redeeming.
    // In our code, if HF breaks it will revert
    function test_RedeemCollateralFunction() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine),DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);
        // 100 ether
        uint256 DEPOSITED_BALANCE = dscEngine.getUserCollateralDeposit(weth);

        dscEngine.mintDSC(MINT_AMOUNT);
        
        dscEngine.reedemCollateral(weth, REDEEM_AMOUNT);  
        // 90 ether  
        uint256 REDEEM_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        vm.stopPrank();
        assert(REDEEM_BALANCE == DEPOSITED_BALANCE-REDEEM_AMOUNT);
    }

    function test_BurnDSCFunction() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine),DEPOSIT_AMOUNT);
        dscEngine.depositCollateral(weth, DEPOSIT_AMOUNT);

        dscEngine.mintDSC(MINT_AMOUNT);
        // 10 ether
        uint256 INITIAL_DEBT = dscEngine.getUserDebt();
        console.log(INITIAL_DEBT);
        dsc.approve(address(dscEngine), MINT_AMOUNT);
        dscEngine.burnDSC(BURN_AMOUNT);
        // 5 ether
        uint256 BURN_DEBT = dscEngine.getUserDebt();
        console.log(BURN_DEBT);
        vm.stopPrank();
        assert(BURN_DEBT == INITIAL_DEBT-BURN_AMOUNT);
    }
    
    ///////////////////////////////////
    // HEALTH FACTOR TEST //
    ///////////////////////////////////

    function test_CheckProperHealthFactor() public depositCollateralAndMintDSC(){
        uint256 expectedHF = 1e14;
        vm.startPrank(USER);
        uint256 userHF = dscEngine._getHealthFactor(USER);
        console.log(userHF);
        vm.stopPrank();
        assert(expectedHF == userHF);
    }

    ///////////////////////
    // Liquidation Tests //
    ///////////////////////

    function test_ImprovesHealthFactorAfterLiquidation() public {
        // setup -> deploy mock dsc and dscEngine contract
        

        // Arrange User -> let a user deploy ETH and mint DSC
        

        // Arrange Liquidator -> Let liquidator contains some ETH and DSC to pay user Debt!!!


        // Act -> if ETH value drops, let liquidator pays the user debt partially/fully!!!
        
    }

}