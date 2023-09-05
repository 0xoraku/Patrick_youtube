// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

//Interfaceは、コントラクトの外部からコントラクトと対話するための方法
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*libraryはcontractに似ているが、
ステートを持てない
関数はinternal(publicではなく)
*/

library PriceConverter {
    //chainlinkからETH/USDのpriceを取得
    //https://docs.chain.link/data-feeds/using-data-feeds　参照
    function getPrice() internal view returns(uint256){
        //address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
         /* uint80 roundID ,
            int answer,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound*/
        (,int256 price,,,)= priceFeed.latestRoundData();
        //ドル建てのETH価格
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount) internal view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns(uint256){
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}
