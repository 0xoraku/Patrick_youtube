//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/*
* @title OracleLib
* @author osoraku
* @notice This library is used to check the Chainlink Oracle for stale data.
* If a price is stale, the function will revert, and render the DSCEngine unusable - this is by design
* we want the DSCEngine to freeze if prices become stale.
* so if the chainlink network explodes and you have a lot of money locked in the protocol
 */

library OracleLib{
    error OracleLib__StalePrice();

    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns(uint80, int256, uint256, uint256, uint80) {
        priceFeed.latestRoundData();
        (uint80 roundID, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();
        return (roundID, answer, startedAt, updatedAt, answeredInRound);
    }
}

