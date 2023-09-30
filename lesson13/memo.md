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
