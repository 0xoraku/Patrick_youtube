//userから資金を集める
//資金を引き上げる
//入金の最低金額の設定


// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

contract FundMe {

    uint256 minimumUSD = 5;
    
    //支払い可能にする修飾子payable
    function fund() public payable {
        //条件式require(condition, "falseだった場合")
        //requireで偽だった場合、revertされる。
        //これは、使ったガスを除いて実行前の状態に戻る。
        //msg.valueはコントラクトに送信する量
        // require(msg.value > 1e18, "not enough ETH"); //1e18は0が18桁
        require(msg.value >= minimumUSD);
    }

    // function withdraw() public {}

}
