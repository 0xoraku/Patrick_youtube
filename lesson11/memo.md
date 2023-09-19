
## Stringの比較
stringはbytesの配列なので、通常の比較はできない
以下はエラー
```Solidity
assert(expectedName == actualName);
```
通常はabi.encodePackedでbytesの配列に変換してからkeccak256でハッシュ値を取得する。

ここでabi.encodePackedは、引数として渡された値を連結して、1つのバイト列にエンコードする。
```Solidity
keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
```

svgのコードをterminalでbase64に変換
```bash
base64 -i <filename>
```
