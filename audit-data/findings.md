### [M-#] Looping through players array to check for duplicates in `PuppyRaffle::enterRaffle` is a potential denial of service (DoS) attack, increamtally increasing the gas cost of the transaction with each new player added to the array.

**Description:** The `PuppyRaffle::enterRaffle` function loops through the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means the gas costs for players who enter right when the raffle starts will be dramatically lower than the gas costs for players who enter right before the raffle ends. Every additional address in the `players` array, is an additional check the loop will have to make.

```javascript
@>  for (uint256 i = 0; i < players.length - 1; i++) {
        for (uint256 j = i + 1; j < players.length; j++) {
            require(
                players[i] != players[j],
                "PuppyRaffle: Duplicate player"
            );
        }
    }
```

**Impact:** The gas costs for raffle entrants will greatly increase as more players enter the raffle. Discouraging the later users from entering, and causing a rush at the start of a raffle to be one of the first entrants in the queue. 

An attacker might make the `players` array so big, that no one else enters, guarenteeing thenselves the win.

**Proof of Concept:**

If we have 2 sets of 100 players enter, the gas costs will be as such:
- 1st set of 100 players: 6271948 wei
- 2nd set of 100 players: 18068128 wei

This is almost a 3x increase in gas costs for the 2nd set of players.

<details>
<summary>POC code</summary>
Paste the following test into `PuppyRaffleTest.t.sol`

```javascript
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
        assertTrue(gasCostSecond > gasCostFirst);
    }
```
</details>

**Recommended Mitigation:** 

1. Consider allowing duplicates. Users can make new wallet addresses anyways, so a duplicate check doesn't prevent the same person from entering multiple times, only the same wallet address.
2. Use a mapping to keep track of players who have already entered the raffle. This will allow you to check for duplicates without looping through the entire `players` array. Time complexity of a mapping lookup is O(1), while looping through an array is O(n).

```diff
+    mapping(address => uint256) public addressToRaffleId;
+    uint256 public raffleId = 0;
    .
    .
    .
    function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
+            addressToRaffleId[newPlayers[i]] = raffleId;            
        }

-        // Check for duplicates
+       // Check for duplicates only from the new players
+       for (uint256 i = 0; i < newPlayers.length; i++) {
+          require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate player");
+       }    
-        for (uint256 i = 0; i < players.length; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }
        emit RaffleEnter(newPlayers);
    }
.
.
.
    function selectWinner() external {
+       raffleId = raffleId + 1;
        require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
```

Alternatively, you could use OpenZeppelin's [EnumerableSet](https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet)
