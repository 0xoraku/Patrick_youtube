//userから資金を集める
//資金を引き上げる
//入金の最低金額の設定


// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

//Interfaceは、コントラクトの外部からコントラクトと対話するための方法
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract FundMe {

    //最低入金額 5usd(これをeth用に変換)
    uint256 minimumUSD = 5e18;

    //入金者のリスト
    address[] public funders;

    //誰がいくら送ったか
    // mapping (address => uint256) public addressToAmountFunded;
    mapping (address funder => uint256 amountFunded) public addressToAmountFunded;
    
    //支払い可能にする修飾子payable
    function fund() public payable {
        //条件式require(condition, "falseだった場合")
        //requireで偽だった場合、revertされる。
        //これは、使ったガスを除いて実行前の状態に戻る。
        //msg.valueはコントラクトに送信する量
        // require(msg.value > 1e18, "not enough ETH"); //1e18は0が18桁
        // require(msg.value >= minimumUSD);
        require(getConversionRate(msg.value)> minimumUSD,"not enough ETH");
        //送信者を格納
        funders.push(msg.sender);
        //送金額の累計を更新
        addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
    }

    // function withdraw() public {}

    //chainlinkからETH/USDのpriceを取得
    //https://docs.chain.link/data-feeds/using-data-feeds　参照
    function getPrice() public view returns(uint256){
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

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() public view returns(uint256){
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }


}
