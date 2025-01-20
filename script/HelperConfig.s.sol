// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "lib/forge-std/src/Script.sol";


contract CodeConstants {
    // MOCK CONTRACT VALUES
    


    // CHAIN IDS
    uint public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script{
    
}