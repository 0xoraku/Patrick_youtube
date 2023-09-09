// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

/*Testの種類
1.Unit
　特定のコードをテストする
2.Integration
　外部のコードに対してどう作用するかをテストする
3.Forked
　本番環境を想定したテスト
4.Staging
　prodではなく、本番環境でテスト
*/

//forge coverageでどの程度テストを行ったかを確認できる。

contract FundMeTest is Test {
    FundMe fundMe;

    //test用のユーザーアドレスを作成する。
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external{
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //test用のユーザーアドレスにETHを送る。
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public{
        // msg.sender -> FundMeTest -> FundMe
        //console.log(fundMe.i_owner());
        //console.log(msg.sender);
        //段階１
        //これはエラー。Fundmeを呼び出すのはFundMeTestコントラクト。
        //msg.senderはFundMeTestコントラクトを呼び出す。
        // assertEq(fundMe.i_owner(), msg.sender);
        //address(this)はFundMeTestコントラクトのアドレス。
        // assertEq(fundMe.i_owner(), address(this));

        //段階２
        //DeployFundMeをimportすることで再びmsg.senderが
        //Fundmeを呼び出す
        //FundMe.sol内でi_owner()をprivateにして、
        //getOwner()からi_onwer()を呼び出すように変更した。
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        //Foundry内では、ChainlinkのAggregatorV3Interfaceのアドレス
        //を指定できない。従って、ただのtestでは下記のgetVersion()はエラーになる。
        //下記のように、fork-urlを指定して、本番環境を想定したテストを行う。
        //forge test --match-test testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL
        //HelperConfigfileを作成し、networkに対応させても良い。
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    //fundの金額が5ドル未満の場合にはエラーになるかのテスト
    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // expect a revert
        //5ドル未満のETHを送る場合はエラーになるべき。
        fundMe.fund(); //send 0 eth
    }

    //fundの入金額と、送金者が一致するかのテスト
    function testFundUpdatesFundedDataStructure() public {
        //prankの説明についてはhttps://book.getfoundry.sh/cheatcodes/prank?highlight=prank#prank
        vm.prank(USER); // pretend to be USER。次のTxはこのUserから送られたとみなす。
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    //fundersの配列にfunderが追加されているかのテスト
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    //以下のmodifierはfund関数を使いまわす用
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    //Owner以外がwithdrawをできないことのテスト
    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert(); // 次の行はエラーになるはず
        fundMe.withdraw();
    }

    /**
    Testの実行方法
    Arrange: テストの前提条件を設定します。テスト対象のオブジェクトを作成し、必要なデータを準備します。
    Act: テスト対象のオブジェクトに対して、テストを実行するためのアクションを実行します。
    Assert: テストの結果を検証します。テスト対象のオブジェクトが期待通りの結果を返すかどうかを確認します。
     */
    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        //Act
        //gas priceを加味する。
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();

        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();

        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }

}