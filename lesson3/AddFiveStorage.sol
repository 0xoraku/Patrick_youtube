// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SimpleStorage} from "SimpleStorage.sol";

//継承の仕方
contract addFiveStorage is SimpleStorage {
    //継承したい関数にはoverride specifierが必要
    //継承される側の関数にはvirtual specifierが必要
    function store(uint256 _newNumber) public override {
        myFavoriteNumber = _newNumber + 5;
    }
}
