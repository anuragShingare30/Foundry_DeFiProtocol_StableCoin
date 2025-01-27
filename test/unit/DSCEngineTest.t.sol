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
    uint256 constant public COLLATERAL_AMOUNT = 100 ether;
    uint256 constant public MINT_AMOUNT = 100 ether;

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
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        vm.stopPrank();
        _;
    }
    modifier depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateralAndMintDSC(weth, COLLATERAL_AMOUNT, MINT_AMOUNT);
        vm.stopPrank();
        _;
    }


    // Price Feed functions test

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


    // constructor params test

    address[] public tokenAddresses = [weth];
    address[] public priceFeedAddresses = [wethUsdPriceFeed,wbtcUsdPriceFeed];
    function test_RevertIf_TokenAddressesLengthNotMatch() public {
        vm.expectRevert(DSCEngine.DSCEngine_MismatchPriceFeedAddresses.selector);
        // create new instance of contract
        new DSCEngine(tokenAddresses,priceFeedAddresses,address(dsc));
    }

    // DEPOSIT COLLATERAL FUNCTION TEST

    function test_RevertIf_CollateralAmountIsZero() public {    
        vm.prank(USER);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
    }
    function test_RevertIf_TokenAddressIsNotValid() public {
        ERC20Mock token = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_InvalidTypeOfCollateralUsed.selector);
        dscEngine.depositCollateral(address(token), COLLATERAL_AMOUNT);
        vm.stopPrank();
    }
    function test_DepositAmountCollateral() public {
        vm.startPrank(USER);
        uint256 INITIAL_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        console.log(INITIAL_BALANCE);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        // vm.expectEmit(true, false, true, COLLATERAL_AMOUNT);
        // emit DSCEngine_depositCollateral(USER, weth, COLLATERAL_AMOUNT);
        uint256 DEPOSIT_BALANCE = dscEngine.getUserCollateralDeposit(weth);
        console.log(DEPOSIT_BALANCE);
        vm.stopPrank();
        assert(INITIAL_BALANCE+COLLATERAL_AMOUNT == DEPOSIT_BALANCE);
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
        ERC20Mock(address(mockDsc)).approve(address(mockDscE),COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_depositCollateralFailed.selector);
        mockDscE.depositCollateral(address(mockDsc), COLLATERAL_AMOUNT);
        vm.stopPrank();
    }   


    // MINT FUNCTION TEST

    function test_amountDSCToMint() public depositCollateral() {
        vm.startPrank(USER);
        uint256 INITIAL_BALANCE = dscEngine.getAmountDSCUserMinted();
        console.log(INITIAL_BALANCE);
        dscEngine.mintDSC(COLLATERAL_AMOUNT);
        uint256 AFTER_MINT_BALANCE = dscEngine.getAmountDSCUserMinted();
        console.log(AFTER_MINT_BALANCE);
        vm.stopPrank();
        assert(INITIAL_BALANCE+COLLATERAL_AMOUNT == AFTER_MINT_BALANCE);
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
        ERC20Mock(weth).approve(address(mockDscE),COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_mintDSCFailed.selector);
        mockDscE.depositCollateralAndMintDSC(weth, COLLATERAL_AMOUNT, MINT_AMOUNT);
        vm.stopPrank();
    }
    function test_RevertsIf_mintAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), MINT_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.mintDSC(0);
    }
    // (Imp.)
    function test_RevertsIf_MintDSCBreaksHealthFactor() public {}


    // DEPOSIT AND MINT FUNCTION TEST

    function test_depositCollateralAndMintDSC() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);
        dscEngine.depositCollateralAndMintDSC(weth, COLLATERAL_AMOUNT, MINT_AMOUNT);
        vm.stopPrank();
    }
    // (Imp.)
    function test_RevertsIf_depositCollateralAndMintDSCBreaksHealthFactor() public {}


    // BURN DSC FUNCTION TEST

    function test_RevertsIf_ZeroBurnAmount() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.burnDSC(0);
        vm.stopPrank();
    }
    function test_BurnMoreThanHave() public {
        vm.startPrank(USER);
        dscEngine.burnDSC(1);
        vm.stopPrank();
    }
    function test_BurnDSCAmount() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        dsc.approve(address(dscEngine), MINT_AMOUNT);
        dscEngine.burnDSC(MINT_AMOUNT);
        vm.stopPrank();
        uint256 userBalance = dsc.balanceOf(USER);
        console.log(userBalance);
        assert(userBalance == 0);
    }


    // REDEEM COLLATERAL FUNCTION TEST

    function test_RevertsIf_ZeroAmount() public depositCollateralAndMintDSC(){
        vm.startPrank(USER);
        dsc.approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_ZeroAmountNotAllowed.selector);
        dscEngine.reedemCollateral(weth, 0);
        vm.stopPrank();
    }
    function test_RevertsIf_RedeemCollateralTransactionFailed() public {
        address owner = msg.sender;
        vm.prank(owner);
        MockFailedTransfer mockDsc = new MockFailedTransfer();
        tokenAddresses = [address(mockDsc)];
        priceFeedAddresses = [wethUsdPriceFeed];
        vm.prank(owner);
        DSCEngine mockDscE = new DSCEngine(tokenAddresses,priceFeedAddresses,address(mockDsc));
        mockDsc.mint(USER, COLLATERAL_AMOUNT);  

        vm.prank(owner);
        mockDsc.transferOwnership(address(mockDscE));

        vm.startPrank(USER);
        ERC20Mock(address(mockDsc)).approve(address(mockDscE),COLLATERAL_AMOUNT);
        mockDscE.depositCollateral(address(mockDsc), COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine_reedemCollateralFailed.selector);
        mockDscE.reedemCollateral(address(mockDsc), COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

}