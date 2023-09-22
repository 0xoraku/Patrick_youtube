//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
callのデータフィールドのみを使用して関数を呼び出すためには、以下をエンコードする必要があります：
関数名
追加したいパラメータ
バイナリレベルまで掘り下げたもの

今、各Contractはそれぞれの関数に関数IDを割り当てます。
これは「関数セレクタ」として知られています。 
「関数セレクタ」は関数シグネチャの最初の4バイトです。
例えば0xa9059cbbはtransfer(address, uint256)の関数セレクタです。
 「関数シグネチャ」は、関数名とパラメータを定義する文字列です。
 例えばtransfer(address, uint256)
  これを見てみましょう
 */

contract CallAnything{
    address public s_someAddress;
    uint256 public s_amount;

    function transfer(address someAddress, uint256 amount) public {
        s_someAddress = someAddress;
        s_amount = amount;
    }

    //以下を実装することで、Transactionのdataフィールドに、
    //関数セレクタとパラメータをエンコードしたものを入れることができる
    function getSelectorOne() public pure returns(bytes4){
        // transfer(address,uint256)の関数セレクタを返す
        return bytes4(keccak256(bytes("transfer(address,uint256)")));//bytes4: 0xa9059cbb
    }

    function getDataToCallTransfer(address someAddress, uint256 amount) public pure returns(bytes memory){
        bytes4 selector = getSelectorOne();
        bytes memory data = abi.encodeWithSelector(selector, someAddress, amount);
        return data;
    }

    //直接transfer関数を呼び出さなくても、以下のようにして呼び出すことができる
    function callTransferFunctionDirectly(address someAddress, uint256 amount) 
        public returns(bytes4, bool) {
            (bool success, bytes memory returnData) = address(this).call(
                //abi.encodeWithSelector(selector, someAddress, amount);
                getDataToCallTransfer(someAddress, amount);
            );
            return (bytes4(returnData), success);
    }

    //bytes4(keccak256(bytes("transfer(address,uint256)")))
    //の代わりに以下のようにしても呼び出すことができる
    function callTransferFunctionDirectlySig(address someAddress, uint256 amount) 
        public returns(bytes4, bool) {
            (bool success, bytes memory returnData) = address(this).call(
                abi.encodeWithSignature("transfer(address,uint256)", someAddress, amount)
            );
            return (bytes4(returnData), success);
    }

}