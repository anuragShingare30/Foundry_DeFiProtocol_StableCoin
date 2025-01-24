// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title A testing lottery smart contract
 * @author anurag shingare
 * @notice Here, we are writing test smart contract for our lottery contract
 * @dev We will work with Helperconfig and Deploy script contract to extract our main contract.
*/


contract CodeConstants {
    // MOCK CONTRACT VALUES
    uint256 public constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;

    // CHAIN IDS
    uint public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script,CodeConstants{


    // types
    struct NetworkConfig{
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    // state variables
    NetworkConfig public localNetworkConfig;
    

    // events
    
    // functions
    constructor(){
        if(block.chainid == ETH_SEPOLIA_CHAIN_ID){
            localNetworkConfig = getSepoliaETHConfig();
        }else{
            localNetworkConfig = getAnvilETHConfig();
        }
    }

    function getSepoliaETHConfig() public returns(NetworkConfig memory){
        return NetworkConfig({
            wethUsdPriceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed:0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            wbtc:0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            deployerKey:vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getAnvilETHConfig() public returns(NetworkConfig memory){
        if(localNetworkConfig.wethUsdPriceFeed != address(0)){
            return localNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mock_wethUsdPriceFeed = new MockV3Aggregator(DECIMALS,ETH_USD_PRICE);
        ERC20Mock mock_weth = new ERC20Mock();

        MockV3Aggregator mock_wbtcUsdPriceFeed = new MockV3Aggregator(DECIMALS,BTC_USD_PRICE);
        ERC20Mock mock_wbtc = new ERC20Mock();

        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed:address(mock_wethUsdPriceFeed),
            wbtcUsdPriceFeed:address(mock_wbtcUsdPriceFeed),
            weth:address(mock_weth),
            wbtc:address(mock_wbtc),
            deployerKey:ANVIL_PRIVATE_KEY
        });
    }
}