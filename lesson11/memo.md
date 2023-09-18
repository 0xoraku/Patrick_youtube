
## Stringの比較
stringはbytesの配列なので、通常の比較はできない
以下はエラー
assert(expectedName == actualName);
abi.encodePackedでbytesの配列に変換してからkeccak256でハッシュ値を取得
abi.encodePackedは引数として渡された値を連結して、1つのバイト列にエンコードする。
