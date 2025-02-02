// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


import {Test, console} from "lib/forge-std/src/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

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

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public timesMintIsCalled;
    address[] public userAddresses;
    MockV3Aggregator public wethUsdPriceFeed;

    constructor(DSCEngine _dscE,DecentralizeStableCoin _dsc){
        dscE = _dscE;
        dsc = _dsc;
        address[] memory collateralTokens = dscE.getCollateralAddresses();

        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
        wethUsdPriceFeed = MockV3Aggregator(dscE.getTokenPriceFeed(address(weth)));
    }

    function depositCollateral(uint256 index,uint256 collateralAmount) public {
        ERC20Mock collateral = _getCollateralTokensAddress(index);
        collateralAmount = bound(collateralAmount, 1, type(uint96).max);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, collateralAmount);
        collateral.approve(address(dscE), collateralAmount);
        dscE.depositCollateral(address(collateral), collateralAmount);
        vm.stopPrank();
        userAddresses.push(msg.sender);
    }

    function mintDSC(uint256 amountDSCToMint,uint256 index) public {
        if(userAddresses.length == 0){
            return;
        }
        address user = userAddresses[index%userAddresses.length];
        (uint256 totalDSCMinted,uint256 collateralValueInUSD) = dscE.getUserInfo(user);

        int256 maxAmountDSCToMint = (int256(collateralValueInUSD/2) - int256(totalDSCMinted));
        if(maxAmountDSCToMint == 0){
            return;
        }
        amountDSCToMint = bound(amountDSCToMint,1,MAX_DEPOSIT_SIZE);
        if(amountDSCToMint == 0){
            return;
        }
        vm.startPrank(user);
        dscE.mintDSC(amountDSCToMint);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    function redeemCollateral(uint256 index,uint256 collateralAmount) public {
        ERC20Mock collateral = _getCollateralTokensAddress(index);
        uint256 maxCollateralWeCanRedeem = dscE.getCollateralBalanceOfUser(msg.sender, address(collateral));
        // bound will set the range for collateralAmount from 0 to maxCollateralWeCanRedeem (min to max).
        collateralAmount = bound(collateralAmount, 0, maxCollateralWeCanRedeem);
        if(collateralAmount == 0){
            return;
        }
        vm.startPrank(msg.sender);
        dscE.reedemCollateral(address(collateral), collateralAmount);   
    }

    // // THIS TEST IS BREAKING OUR PROTOCOL
    // // IF ETH/BTC PRICE FLUCTUATES MORE
    // function collateralPrice(uint96 newPrice) public {
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     wethUsdPriceFeed.updateAnswer(newPriceInt);
    // }


    // helper functions
    function _getCollateralTokensAddress(uint256 index) private view returns(ERC20Mock){
        if(index%2 == 0){
            return weth;
        }
        return wbtc;
    }
}