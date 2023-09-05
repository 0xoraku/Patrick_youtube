//userから資金を集める
//資金を引き上げる
//入金の最低金額の設定


// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

//同じ階層にあるlibraryを使う。
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    //uint256型の変数に対してPriceConverter libraryの関数を呼び出せる。
    using PriceConverter for uint256;

    //最低入金額 5usd(これをeth用に変換)
    uint256 public constant MINIMUM_USD = 5e18;

    //入金者のリスト
    address[] public funders;

    //誰がいくら送ったか
    // mapping (address => uint256) public addressToAmountFunded;
    mapping (address funder => uint256 amountFunded) public addressToAmountFunded;

    //コントラクトの所有者
    //immutableは宣言時に初期化され、その後の変更はできない。
    address public immutable i_owner;

    //constructorはコントラクトがdeployしたら呼び出される。
    constructor(){
        i_owner = msg.sender;
    }
    
    //支払い可能にする修飾子payable
    function fund() public payable {
        //条件式require(condition, "falseだった場合")
        //requireで偽だった場合、revertされる。
        //これは、使ったガスを除いて実行前の状態に戻る。
        //msg.valueはコントラクトに送信する量
        // require(msg.value > 1e18, "not enough ETH"); //1e18は0が18桁
        // require(msg.value >= MINIMUM_USD);
        // require(getConversionRate(msg.value)> MINIMUM_USD,"not enough ETH");
        //libraryからgetconversionRateを使う。
        //msg.valueはuint256型の変数なので、usingで関連付けた関数をその後に使える。
        require(msg.value.getConversionRate()> MINIMUM_USD,"not enough ETH");
        //送信者を格納
        funders.push(msg.sender);
        //送金額の累計を更新
        addressToAmountFunded[msg.sender] += msg.value;
    }

    //ownerだけが出金できる
    //onlyOwnerは下で定義しているmodifier
    function withdraw() public onlyOwner{
        //全てのfundersの資金を0にする
        for(uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //fundersのリストをリセット
        funders = new address[](0);

        //送金
        //msg.sender = address
        //payable(msg.sender)は支払い可能なaddress
        //送金の種類はtransfer, send, callの3種

        //transferは失敗時にエラーが発生しロールバックする。
        //payable(msg.sender).transfer(address(this).balance);

        //sendは自分でerrorの場合の対応をする
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success,"failed to send");


        //call ()内で他の関数を呼び出せる。(今回は不要なので"")
        //2つの値を返す(bool callSuccess, bytes memory dataReturned) 
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "failed to send");


    }

    
    modifier onlyOwner() {
        //関数の実行前にチェックする。
        // require(msg.sender == i_owner, "sender is not owner!"); 
        if (msg.sender != i_owner){
            revert NotOwner();
        }
        //関数内を実行する。
        _; 
    }


    //直接このコントラクトを呼ばれた場合の対応
    receive() external payable{
        fund();
    }

    fallback() external payable {
        fund();
    }


}
