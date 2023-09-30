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


## OpenZeppelin
[fallback関数でdelegatecallを呼び出すproxy contract](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol)

[Proxy upgradeのパターンの解説](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies)

#### CLI
[openzeppelin-contracts-upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)
```bash
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
```

## TransparentとUUPS Proxies
[OpenZeppelin doc](https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent-vs-uups)

以下、chatGPTより
```
Solidityで書かれたスマートコントラクトは、一旦デプロイされると、コードの変更が不可能です。しかし、デザインパターンの1つである「プロキシ」を使うことで、スマートコントラクトのロジックをアップデートすることができるようになります。

以下は、Solidityでの2つの主要なプロキシアップグレードパターンについての説明です。

1. **Transparent Proxies**
   - **動作**: Transparent Proxiesは2つのコントラクトから構成されます: Proxy ContractとImplementation Contractです。Proxy Contractには状態変数が保存され、Implementation Contractには実際のビジネスロジックが格納されます。ユーザーがProxy Contractにトランザクションを送信すると、それはfallback関数を介してImplementation Contractにデリゲートされます。
   - **透明性**: この方法は「透明」と呼ばれるのは、ユーザーは背後のImplementation Contractの存在を意識することなくProxy Contractと直接対話できるからです。
   - **セキュリティ**: Implementationの変更は管理者によってのみ行われるため、管理者の権限を正確に制御することが非常に重要です。

2. **UUPS (Universal Upgradeable Proxy Standard) Proxies**
   - **動作**: UUPSもTransparent Proxiesと同様に、Proxy ContractとImplementation Contractの2つから構成されます。しかし、UUPSはアップグレードの方法が異なり、よりガス効率的です。
   - **EIP-1822**: UUPSのアイディアはEIP-1822で提案されています。
   - **アップグレードメカニズム**: UUPSでは、Proxy Contractが直接Implementation Contractのアドレスを変更することができる特別な関数を持っています。これにより、ガスコストを大幅に削減することができます。
   - **セキュリティ**: UUPSのアップグレード方法は、実行される前に検証されるため、間違ったアップグレードが行われるリスクを減少させます。

どちらのパターンも、スマートコントラクトのアップグレードを可能にするものですが、それぞれに利点と欠点があります。どちらを選ぶかは、特定のアプリケーションの要件と目的によって異なります。
```

