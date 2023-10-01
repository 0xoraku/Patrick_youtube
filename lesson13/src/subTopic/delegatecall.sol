// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
*delegatecall は、call と同様の低レベル関数です。 
コントラクト A がコントラクト B への delegatecall を実行すると、
B のコードが実行されます。 この時、contract A のStorage、
msg.sender および msg.value を使用します。 
*/

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
