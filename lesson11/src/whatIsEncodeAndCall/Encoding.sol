//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import  {console} from "forge-std/console.sol";

/**
「トランザクションを送信すると、それはバイトコードに「コンパイル」され、
トランザクションの「データ」オブジェクト内に送信されます。 
このデータオブジェクトは、将来のトランザクションがそれと対話する方法を制御します。
 例えば: https://etherscan.io/tx/0x112133a0a74af775234c077c397c8b75850ceb61840b33b23ae06b753da40490
これらのバイトを読み取り理解するためには、特別なリーダーが必要です。
 これは新しいcontractですか？どのように判断できますか？
  このcontractをハードハットまたはリミックスでコンパイルしてみましょう。
  そうすれば、「バイトコード」の出力が表示されます。それがcontractの作成時に送信されるものです。

このバイトコードは、contractを実現するための低レベルのコンピュータ命令を正確に表しています。
 これらの低レベルの命令は、オペコードと呼ばれるものに分散されています。

オペコードは、特別な命令を表す2文字であり、オプションで入力も持つことができます。

以下のリンクでオペコードのリストを見ることができます:
 https://www.evm.codes/ またはこちら: https://github.com/crytic/evm-opcodes

このオペコードリーダーは、抽象的にはEVMと呼ばれることもあります。
EVMは基本的に、コンピュータが読み取るために必要なすべての命令を表します。
 これらのオペコードでバイトコードにコンパイルできる任意の言語は、EVM互換と見なされます。
 そのため、多くのブロックチェーンがこれを行うことができます。
 EVMを理解できるようにするだけで、Solidityスマートコントラクトは
 それらのブロックチェーン上で動作します。

ただし、バイナリを直接読むのは難しい場合もあるため、「アセンブリ」ボタンを押してみませんか？
バイナリがオペコードと入力に変換されます！

 */

contract Encoding {
    function combineStrings() public view returns (string memory) {
        string memory a = "Hello ";
        string memory b = "World!";
        //abi.encodePacked()で文字列を結合する。
        //この時,型はbytesになるのでstringに変換する必要がある。
        string memory result1 = string(abi.encodePacked(a, b));
        console.log("resut1: ",result1);
        //0.8.12以上からはstring.concat()で文字列を結合できる。
        //また、こちらの方がガス消費量が少ない。
        string memory result2 = string.concat(a, b);
        console.log("resut2: ",result2);
        return result1;
    }

    //この関数では、数字の1をバイナリ表現にエンコードします。 
    //つまり、ABIエンコードします。
    function encodeNumber() public pure returns (bytes memory) {
        bytes memory number = abi.encode(1);
        return number; //bytes: 0x0000000000000000000000000000000000000000000000000000000000000001
    }

    function encodeString() public pure returns (bytes memory) {
        bytes memory greeting = abi.encode("hello");
        return greeting; //bytes: 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000
    }

    //上記のencodeでは0が大量にあり、無駄にガスを消費している。
    //encodePackedでそれを解決できる。
    function encodePackedString() public pure returns (bytes memory) {
        bytes memory greeting = abi.encodePacked("hello");
        return greeting; //bytes: 0x68656c6c6f
    }

    //bytesのtypecastでも同じことができる。
    function encodeCastString() public pure returns (bytes memory) {
        bytes memory greeting = bytes("hello");
        return greeting; //bytes: 0x68656c6c6f
    }

    //stringをdecodeするには、abi.decode(原文,(型名))を使う。
    function decodeString() public pure returns (string memory) {
        string memory greeting = abi.decode(encodeString(), (string));
        return greeting; //string: hello
    }

    function multiEncode() public pure returns (bytes memory) {
        bytes memory greeting = abi.encode("hello", "world");
        return greeting; //bytes: 0x00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005776f726c64000000000000000000000000000000000000000000000000000000
    }

    function multiDecode() public pure returns (string memory, string memory) {
        (string memory greeting1, string memory greeting2) = abi.decode(multiEncode(), (string, string));
        return (greeting1, greeting2); //string: hello, string: world
    }

    function multiEncodePacked() public pure returns (bytes memory) {
        bytes memory greeting = abi.encodePacked("hello", "world");
        return greeting; //bytes: 0x68656c6c6f776f726c64
    }

    //次の方法ではrevertされる。
    function multiDecodePacked() public pure returns (string memory) {
        string memory greeting = abi.decode(multiEncodePacked(), (string));
        return greeting; //string: helloworld
    }

    //encodePackedで結合したものをdecodeするには、string()でキャストする必要がある。
    function multiStringCastPacked() public pure returns (string memory) {
        string memory greeting = string(multiEncodePacked());
        return greeting; //string: helloworld
    }


    // 以前にも述べたように、コントラクトを呼び出すには常に2つの要素が必要です：
// 1. ABI
// 2. コントラクトアドレス
// それは事実でしたが、私たちはその巨大なABIファイルは必要ありません。
//私たちが呼び出したい関数を呼び出すためのバイナリを作成する方法だけを知っていれば十分です。

// Solidityには、より「低レベル」なキーワードがいくつかあります。
//具体的には「staticcall」と「call」です。私たちは過去にcallを使用したことがありますが、
// それが何をしているのかはあまり説明していませんでした。
//また、「send」というものもありますが、基本的には忘れてください。

// call：ブロックチェーンの状態を変更するために関数を呼び出す方法です。
// staticcall：これは、（低レベルで）「view」または「pure」な関数呼び出しを行い、
//ブロックチェーンの状態を変更しない可能性があります。

// 関数を呼び出すときは、裏で「call」が呼び出され、すべてがバイナリデータにコンパイルされます。
// 以前にETHを抽選から引き出したときのフラッシュバックを思い出してください。
   function withdraw(address recentWinner) public {
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }
/**
これを覚えていますか？
- {}はトランザクションの特定のフィールド（たとえば値）を渡すことができました。
- {}は特定の関数を呼び出す(call)ためにデータを渡すこともできましたが、
呼び出したい関数はありませんでした！だから、私たちは空の文字列を渡しました。("")
- 私たちはETHしか送信しなかったので、関数を呼び出す必要はありませんでした！
- 関数を呼び出したり、データを送信したい場合は、これらの括弧内で行います！

 */


}