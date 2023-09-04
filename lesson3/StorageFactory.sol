// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage[] public listOfSimpleStorage;

    function createSimpleStorageContract() public {
        SimpleStorage newSimpleStorage = new SimpleStorage();
        listOfSimpleStorage.push(newSimpleStorage);
    }

    //SimpleStorageコントラクトのstore関数でお気に入り数字を登録
    function sfStore(uint256 _simpleStorageIndex, uint256 _newSimpleStorageNumber) public {
        //address
        //abi
        listOfSimpleStorage[_simpleStorageIndex].store(_newSimpleStorageNumber);
    }

    //同上で、retrieve関数でお気に入りnumを読み取る
    function stGet(uint256 _simpleStorageIndex) public view returns(uint256) {
        return listOfSimpleStorage[_simpleStorageIndex].retrieve();
    }

}
