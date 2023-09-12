## Solidity style guide
 - imports
- errors
- interfaces, libraries, contracts
- Type declarations
- State variables
- Events
- Modifiers
- Functions

Layout of Functions:
- constructor
- receive function (if exists)
- fallback function (if exists)
- external
- public
- internal
- private
- view & pure functions


## Best Practice
CEI: Checks-Effects-Interactions
「Checks」で、コントラクトへの入力を検証して、コントラクトが有効な状態であることを確認します。次に、「Effects」ステップで、入力とその他の関連情報に基づいて、コントラクトの状態を更新します。最後に、「Interactions」ステップで、他のコントラクトや外部システムとのやり取りを行います。
Re-entrancy攻撃を抑える

## Test
arrange, act, assert は、テスト駆動開発（TDD）の手法の一つで、テストの構造を明確にするために使用されます。

arrange は、テストの前提条件を設定するために使用されます。このステップでは、テストに必要なオブジェクトやデータを作成し、テストの環境を準備します。

act は、テスト対象のコードを実行するために使用されます。このステップでは、テスト対象のコードに対して、必要な入力を提供し、コードを実行します。

assert は、テストの結果を検証するために使用されます。このステップでは、テスト対象のコードの出力や状態を検証し、期待通りの結果が得られたかどうかを確認します。

テスト駆動開発では、最初にテストを書き、その後にコードを書くことが推奨されます。この手法により、開発者は、コードが期待通りに動作することを確認するための自動化されたテストを持つことができます。また、テスト駆動開発により、開発者は、コードの品質を向上させ、バグを減らすことができます。


## Words
#### Topic
トピックは、Eventのログに含まれるトピックスの配列であり、Eventのフィルタリングに使用されます。
topic[0]は常にイベント自体のハッシュを指し、最大3つのインデックス付き引数を持つことができ、それぞれがtopicに反映される。

## Ref
- (Chainlink vrf)[https://docs.chain.link/vrf/v2/introduction]
- (Chainlink automation)[https://docs.chain.link/chainlink-automation/introduction]
- (Chainlink Network address)[https://docs.chain.link/vrf/v2/subscription/supported-networks]
- (FoundryでEventをTestする事例)[https://book.getfoundry.sh/cheatcodes/expect-emit?highlight=expectemit#expectemit]
- (solmate,library等)[https://github.com/transmissions11/solmate]
