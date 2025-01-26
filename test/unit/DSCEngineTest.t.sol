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

    function test_RevertIf_TransactionFailed() public {
        
    }   

}