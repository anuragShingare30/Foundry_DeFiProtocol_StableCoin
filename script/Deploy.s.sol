// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";

contract DeployDSC is Script{
    address private constant ANVIL_PRIVATE_KEY = "";
    address[]  tokenAddress;
    address[]  priceFeedAddresses;

    function setUp() external returns(
        DecentralizeStableCoin decentralizeStableCoin,
        DSCEngine dscEngine
    ){
        vm.startBroadcast(ANVIL_PRIVATE_KEY);
        DecentralizeStableCoin decentralizeStableCoin = new DecentralizeStableCoin();
        DSCEngine dscEngine = new DSCEngine(
            // constructor params
            tokenAddress,
            priceFeedAddresses,
            address(decentralizeStableCoin)
        );
        vm.stopBroadcast();

        return (decentralizeStableCoin,dscEngine);
    }

    function run() external returns(
        DecentralizeStableCoin decentralizeStableCoin,
        DSCEngine dscEngine
    ){
        return setUp();
    }
}