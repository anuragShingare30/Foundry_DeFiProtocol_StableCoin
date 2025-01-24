// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {DecentralizeStableCoin} from "src/DecentralizeStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title A testing lottery smart contract
 * @author anurag shingare
 * @notice Here, we are writing test smart contract for our lottery contract
 * @dev We will work with Helperconfig and Deploy script contract to extract our main contract.
 */

contract DeployDSC is Script{
    uint256 public constant ANVIL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address[]  tokenAddress;
    address[]  priceFeedAddresses;
    
    // CREATED NEW HELPERNETWORK CONFIG INSTANCE
    HelperConfig helperConfig;


    function setUp() public returns(
        DecentralizeStableCoin decentralizeStableCoin,
        DSCEngine dscEngine,
        HelperConfig config
    ){
        HelperConfig helperConfig = new HelperConfig();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = helperConfig.localNetworkConfig();

        tokenAddress = [weth,wbtc];
        priceFeedAddresses = [wethUsdPriceFeed,wbtcUsdPriceFeed];

        vm.startBroadcast(ANVIL_PRIVATE_KEY);
        DecentralizeStableCoin decentralizeStableCoin = new DecentralizeStableCoin();
        DSCEngine dscEngine = new DSCEngine(
            // constructor params
            tokenAddress,
            priceFeedAddresses,
            address(decentralizeStableCoin)
        );

        decentralizeStableCoin.transferOwnership(address(dscEngine));
        vm.stopBroadcast();

        return (decentralizeStableCoin,dscEngine,helperConfig);
    } 

    function run() external returns(
        DecentralizeStableCoin decentralizeStableCoin,
        DSCEngine dscEngine,
        HelperConfig helperConfig
    ){
        return setUp();
    }
}