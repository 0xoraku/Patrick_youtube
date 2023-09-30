## delegatecall
コントラクト A がコントラクト B への delegatecall を実行すると、B のコードが実行される。
この時、contract A のStorage、msg.sender および msg.value を使用される。 
storageslotの名前は違っても良いが順番、型がとても重要。

例）
```solidity
contract B {
uint public num;
address public sender;
...
}

contract A {
uint public randomNum;
address public owner;
...
}
```
このように名前が違っていてもよい。

```solidity
contract B {
uint public num;
address public sender;
...
}

contract A {
bool public isZero;
uint256 public hoge;
...
}
```
このように型が違うとTransactionは成功するが、意味のないものとなる。

## Solidity
インライン アセンブリ ブロックは、assembly { ... } でマークされます。
中括弧内のコードは Yul 言語のコードです。
```solidity
library GetCode {
    function at(address addr) public view returns (bytes memory code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
            // allocate output byte array - this could also be done without assembly
            // by using code = new bytes(size)
            code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr, add(code, 0x20), 0, size)
        }
    }
}
```
[assembly](https://docs.soliditylang.org/en/latest/assembly.html)

[Yul](https://docs.soliditylang.org/en/latest/yul.html#yul)
