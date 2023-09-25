# Defi


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
