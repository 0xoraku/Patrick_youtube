# Defi

## 基礎知識
これとか？
[What are Decentralized Stablecoins?](https://www.coingecko.com/learn/what-are-decentralized-stablecoins)

## Health Factor
![image](https://github.com/0xoraku/Patrick_youtube/assets/58765874/1983e48e-299b-4fcd-be63-1a69504d4bb3)
[source](https://docs.aave.com/risk/asset-risk/risk-parameters)




## Solidity関連
### external
全てのexternalにはnonReentrantのmodifierをつけるくらいの感覚で良い。

### internal
internal functionの関数名の最初にアンダースコア_をつける。
```solidity
function _name() internal {}
```

## Chainlink
v3Interface等のtest用
```bash
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

## OpenZeppelin
OZのERC20のMockが更新されているので注意。
```bash
forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit
```

## Foundry

### Testについて
- Fuzz testing は、ランダムな入力を使用して、ソフトウェアのバグを見つけるためのテスト手法です。この手法は、入力の範囲を広げ、境界条件をテストすることで、ソフトウェアの予期しない動作を引き出すことができます。Fuzz testingは、手動でテストすることが困難な複雑なシステムや、大量の入力を処理するシステムに特に有効です。Fuzz testingは、セキュリティテストにも使用され、悪意のある入力を模擬することができます。Fuzz testingは、自動化されたテストツールを使用して実行されることが一般的であり、多くの場合、ランダムな入力を生成するために、ランダムジェネレーターが使用されます。
  
- Invariant testingは、スマートコントラクトの不変条件をテストするための手法であり、スマートコントラクトが期待どおりに動作するために必要な条件を表します。不変条件は、スマートコントラクトの状態が変化しても常に真であるべき条件です。Invariant testingは、スマートコントラクトの状態を変更するトランザクションを生成し、そのトランザクションが不変条件を破壊しないことを確認することで、スマートコントラクトの正常性を検証します。

[Foundry docs](https://book.getfoundry.sh/forge/invariant-testing)

### cli
contractのmethodを一覧化
```bash
forge inspect DSCEngine methods
```
