// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DeployDSC} from "script/Deploy.s.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

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
    uint256 constant public COLLATERAL_AMOUNT = 10 ether;

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;


    function setUp() public {
        DeployDSC deployDSC = new DeployDSC();
        (dsc,dscEngine,helperConfig) = deployDSC.run();
        (wethUsdPriceFeed,wbtcUsdPriceFeed,weth,wbtc,deployerKey) = helperConfig.localNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
    }

    function test_CheckGetPriceFeedFunction() public {
        uint256 ethAmount = 15;
        uint256 expectedAmount = 30000;
        uint256 actualAmount = dscEngine.getUSDValue(weth, ethAmount);
        console.log(actualAmount);
        assert(expectedAmount == actualAmount);
    }

    function test_RevertIf_CollateralAmountIsZero() public {    
        vm.prank(USER);
        ERC20Mock(weth).approve(address(dscEngine), COLLATERAL_AMOUNT);

        vm.expectRevert();
        dscEngine.depositCollateral(weth, 0);
    }

}