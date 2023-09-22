
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
base64 -i <filename>.svg
```

## tokenURIとImageURI
tokenURIはjson形式でnameやdesc, imageURIを含んだものを更にBase64でエンコードしたもの。
imageURIは画像のURI、SVGをbase64でエンコードしたもの。

## Foundry内でfileを読み込む
デフォルトでは、ファイルシステムへのアクセスは許可されていないため、foundry.toml の fs_permission 設定が必要。

今回の例
```bash
fs_permissions = [{access = "read", path="./img/"}]
```
説明
```bash
# Configures permissions for cheatcodes that touch the filesystem like `vm.writeFile`
# `access` restricts how the `path` can be accessed via cheatcodes
#    `read-write` | `true`   => `read` + `write` access allowed (`vm.readFile` + `vm.writeFile`)
#    `none`| `false` => no access
#    `read` => only read access (`vm.readFile`)
#    `write` => only write access (`vm.writeFile`)
# The `allowed_paths` further lists the paths that are considered, e.g. `./` represents the project root directory
# By default _no_ fs access permission is granted, and _no_ paths are allowed
# following example enables read access for the project dir _only_:
#       `fs_permissions = [{ access = "read", path = "./"}]`
fs_permissions = [] # default: all file cheat codes are disabled

```
https://book.getfoundry.sh/cheatcodes/fs?search=readfile


## Solidityのより細かい説明
https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-ii-creation-vs-runtime-6b9d60ecb44c
