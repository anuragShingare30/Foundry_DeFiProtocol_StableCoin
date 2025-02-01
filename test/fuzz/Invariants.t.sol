// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DeployDSC} from "script/Deploy.s.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

/**
 * @title  Writing invariant test for DSCEngine contract.
 * @author anurag shingare
 * @notice We will write fuzz test for our invarients
 * @dev The invarients which we will cover:
        a. totalDSCMinted should always be less than totalDepositCollateral.
 */

contract Invariants is StdInvariant,Test{
    DSCEngine dscEngine;
    DecentralizeStableCoin dsc;
    HelperConfig helperConfig;
    Handler handler;

    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerKey;

    function setUp() public {
        DeployDSC deployDSC = new DeployDSC();
        (dsc,dscEngine,helperConfig) = deployDSC.run();
        (wethUsdPriceFeed,wbtcUsdPriceFeed,weth,wbtc,deployerKey) = helperConfig.localNetworkConfig();
        handler = new Handler(dscEngine,dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWBtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUSDValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscEngine.getUSDValue(wbtc, totalWBtcDeposited);

        console.log("totalSupply:",totalSupply);
        console.log("totalWethDeposited",totalWethDeposited);
        console.log("totalWBtcDeposited",totalWBtcDeposited);
        
        uint256 count = handler.timesMintIsCalled();
        console.log("Times my mint function is called:",count);

        assert(wethValue+wbtcValue >= totalSupply);
    }
    
    
}