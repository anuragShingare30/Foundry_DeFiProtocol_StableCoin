// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library OracleLib{
    // errors
    error OracleLib_StalePrice();

    uint256 public constant TIME = 3 hours; // 10800 seconds


    // Now, in the DSCEngine contract we can replace the latestRoundData() with staleCheckLatestRoundData()
    // Replace latestRoundData() -> staleCheckLatestRoundData()
    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) 
        public 
        view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId,answer,startedAt,updatedAt,answeredInRound) = priceFeed.latestRoundData();
        uint256 TIME_AFTER_FETCHING_DATA = block.timestamp - TIME;
        if(TIME_AFTER_FETCHING_DATA>TIME){
            revert OracleLib_StalePrice();
        }
        return (roundId,answer,startedAt,updatedAt,answeredInRound);
    }
}