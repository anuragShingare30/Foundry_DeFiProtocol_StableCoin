// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DeployDSC} from "script/Deploy.s.sol";


contract DecentralizeStableCoinTest is Test{
    DSCEngine dscEngine;
    DecentralizeStableCoin dsc;    

    function setUp() public {
        DeployDSC deployDSC = new DeployDSC();
        (dsc,,) = deployDSC.run();
        
    }

    function test_RevertsIf_ZeroMinting() public {
        vm.startPrank(dsc.owner());
        vm.expectRevert();
        dsc.mint(address(this), 0);
        vm.stopPrank();
    }

    function test_RevertsIf_BurnsZeroDSc() public {
        vm.startPrank(dsc.owner());
        dsc.mint(address(this), 100);
        vm.expectRevert();
        dsc.burn(0);
        vm.stopPrank();
    }

    function test_RevertsIf_BurnsDSCMoreThanMinted() public {
        vm.startPrank(dsc.owner());
        dsc.mint(address(this), 100);
        vm.expectRevert();
        dsc.burn(101);
        vm.stopPrank();
    }

    function test_RevertsIf_BurnssDSCAtZeroAddress() public {
        vm.startPrank(dsc.owner());
        vm.expectRevert();
        dsc.mint(address(0), 100);
        vm.stopPrank();
    }

}