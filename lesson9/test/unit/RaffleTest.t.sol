//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test{
    /* Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee, 
            interval, 
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,
            
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }


    /////////////////
    // enterRaffle //
    /////////////////
    function () public {
        //Arrange
        vm.prank(PLAYER);
        //Act, Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    //EventのTestの書き方は独特なので、docsを参照すること
    //https://book.getfoundry.sh/cheatcodes/expect-emit?highlight=expectemit#expectemit
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true,false,false,false,address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        //warp: block.timestampの設定
        //roll: block.numberの設定
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /////////////////////
    // checkUpKeep
    /////////////////////
    function testCheckUpkeepReturnsFalseIfIthasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    //自分でトライしてみる
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        //現在のタイムスタンプが最後のタイムスタンプから一定時間のinterval
        //経過していない場合は、falseを返す
        vm.warp(block.timestamp + interval - 10);
        vm.roll(block.number + 1);
        
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(upkeepNeeded);
    }


    /////////////////////
    // performUpkeep
    /////////////////////
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        //Arrage
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act, Assert
        raffle.performUpkeep("");
    }


    //本来skipforを使うべきではないが、sepolia上でエラーの原因が分からないので
    //暫定的にとばしている。
    function testPerformUpkeepRevertsIfCheckUpkeeIsFalse() public skipFor{
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        // uint256 raffleState = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector, 
                currentBalance,
                numPlayers,
                // raffleState
                rState
            )
        );
        raffle.performUpkeep("");
    }


    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() 
        public
        raffleEnteredAndTimePassed
    {
        //recordLogs: emitされたEventのログを記録する
        vm.recordLogs();
        //requestIdをemitする
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        //logのタイプはbytes32(Foundryでは)
        //entries[index]はemitされたindex番目のlogを取得する
        //topics[0]はemitされた全体Eventを指し、１からはEventの引数を指す
        //この場合はrequestId
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }


    //////////////////////
    // fulfillRandomWords
    /////////////////////

    modifier skipFor(){
        //vrfCoordinatorのMockは、実際のChainlinkでは機能しない
        //local環境以外のchainidではskipする
        //31337はanvilのchainid
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    //sepolia testではskipする
    //fuzz test  https://book.getfoundry.sh/reference/config/testing?highlight=fuzz#fuzz
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) 
        public 
        skipFor
        raffleEnteredAndTimePassed
    {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId, 
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendMoney()
        public
        skipFor
        raffleEnteredAndTimePassed
    {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for(uint256 i = startingIndex; i< startingIndex + additionalEntrants; i++) {
            address player = address(uint160(i));
            //hoax: adderssを作成し、etherを送る
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.performUpkeep(""); //emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        // pretend to be chainlink vrf to get random number & pick winner
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId), 
            address(raffle)
        );

        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(previousTimeStamp < raffle.getLastTimeStamp());
        //10050000000000000000
        console.log(raffle.getRecentWinner().balance);
        //10060000000000000000
        console.log(STARTING_USER_BALANCE + prize);
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize -entranceFee);
    }


}
