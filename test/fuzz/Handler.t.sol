// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DeployDSC} from "script/Deploy.s.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title  Writing Handler contract for our fuzz testing
 * @author anurag shingare
 * @notice Contract represents the handler contract we will use in Fuzz testing
 */

contract Handler is Test{
    DSCEngine dscE;
    DecentralizeStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor(DSCEngine _dscE,DecentralizeStableCoin _dsc){
        dscE = _dscE;
        dsc = _dsc;
        address[] memory collateralTokens = dscE.getCollateralAddresses();

        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    function depositCollateral(uint256 index,uint256 collateralAmount) public {
        ERC20Mock collateral = _getCollateralTokensAddress(index);
        collateralAmount = bound(collateralAmount, 1, type(uint96).max);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, collateralAmount);
        collateral.approve(address(dscE), collateralAmount);
        dscE.depositCollateral(address(collateral), collateralAmount);
        vm.stopPrank();
    }

    function redeemCollateral(uint256 index,uint256 collateralAmount) public {
        ERC20Mock collateral = _getCollateralTokensAddress(index);
        uint256 maxCollateralWeCanRedeem = dscE.getCollateralBalanceOfUser(msg.sender, address(collateral));
        collateralAmount = bound(collateralAmount, 0, maxCollateralWeCanRedeem);
        if(collateralAmount == 0){
            return;
        }
        dscE.reedemCollateral(address(collateral), collateralAmount);   
    }


    // helper functions
    function _getCollateralTokensAddress(uint256 index) private view returns(ERC20Mock){
        if(index%2 == 0){
            return weth;
        }
        return wbtc;
    }
}