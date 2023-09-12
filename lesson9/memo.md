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

## Ref
- (Chainlink vrf)[https://docs.chain.link/vrf/v2/introduction]
- (Chainlink automation)[https://docs.chain.link/chainlink-automation/introduction]
