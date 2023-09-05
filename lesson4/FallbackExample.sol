// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

contract FallbackExample {
    uint256 public result;
    //外部から直接このコントラクトを呼ばれた場合の処理
    //recieveはデータがない時
    receive() external payable {
        result = 1;
    }

    //fallbackはデータがあるとき
    fallback() external payable {
        result = 2;
    }
}
