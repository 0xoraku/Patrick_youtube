// SPDX-License-Identifier: MIT
//versionを指定
pragma solidity >=0.8.18 <0.9.0;

contract SimpleStorage {
    uint256 myFavoriteNumber; //0
    //リスト型
    //uint256[] listOfFavoriteNumbers; //[]
    struct Person{
        uint256 favoriteNumber;
        string name;
    }

    // Person public pat = Person({favoritenumber: 12, name:"Pat"});
    //dynamic array
    Person[] public listOfPeople;

    //名前から好きな数を割り出す。Bob => 3など。
    mapping(string=>uint256) public nameToFavoriteNumber;
    
    //AddFiveStorageコントラクトに継承するので修飾子 virtualをつける。
    function store(uint256 _favoriteNumber) public virtual  {
        myFavoriteNumber = _favoriteNumber;
    }

    //viewはステートを読むだけの際に使う。(変数のUpdateなどはできない)
    //Transactioinが発生しないのでGas代を節約できる。
    function retrieve() public view returns(uint256){
        return myFavoriteNumber;
    }

    //calldata, memory, storage
    //calldataとmemoryの変数は一時的に存在するだけ。
    //calldataは関数内で不変でmemoryは可変。
    //storageは永続的に存在する。
    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
