// SPDX-License-Identifier: MIT
// @done @audit-i don' use the old version of solidity
// @done @audit-i don't use the floating pragma version
pragma solidity ^0.7.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Base64} from "lib/base64/base64.sol";

/// @title PuppyRaffle
/// @author PuppyLoveDAO
/// @notice This project is to enter a raffle to win a cute dog NFT. The protocol should do the following:
/// 1. Call the `enterRaffle` function with the following parameters:
///    1. `address[] participants`: A list of addresses that enter. You can use this to enter yourself multiple times, or yourself and a group of your friends.
/// 2. Duplicate addresses are not allowed
/// 3. Users are allowed to get a refund of their ticket & `value` if they call the `refund` function
/// 4. Every X seconds, the raffle will be able to draw a winner and be minted a random puppy
/// 5. The owner of the protocol will set a feeAddress to take a cut of the `value`, and the rest of the funds will be sent to the winner of the puppy.
contract PuppyRaffle is ERC721, Ownable {
    using Address for address payable;

    // @done @audit-i use i_ prefix or capital letters for immutable variables
    // @done @audit-g make immutable
    uint256 public immutable entranceFee;

    address[] public players;
    // @done @audit-g make immutable
    uint256 public raffleDuration;
    uint256 public raffleStartTime;
    address public previousWinner;

    // We do some storage packing to save gas
    address public feeAddress;
    // @done @audit-g no need to initialize to zero since it's already zero
    uint64 public totalFees = 0;

    // mappings to keep track of token traits
    mapping(uint256 => uint256) public tokenIdToRarity;
    mapping(uint256 => string) public rarityToUri;
    mapping(uint256 => string) public rarityToName;

    // Stats for the common puppy (pug)
    // @done @audit-i why not make this a constant?
    string private commonImageUri =
        "ipfs://QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8";
    uint256 public constant COMMON_RARITY = 70;
    string private constant COMMON = "common";

    // Stats for the rare puppy (st. bernard)
    // @done @audit-i why not make this a constant?
    string private rareImageUri =
        "ipfs://QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW";
    uint256 public constant RARE_RARITY = 25;
    string private constant RARE = "rare";

    // Stats for the legendary puppy (shiba inu)
    // @done @audit-i why not make this a constant?
    string private legendaryImageUri =
        "ipfs://QmYx6GsYAKnNzZ9A6NvEKV9nf1VaDzJrqDR23Y8YSkebLU";
    uint256 public constant LEGENDARY_RARITY = 5;
    string private constant LEGENDARY = "legendary";

    // Events
    event RaffleEnter(address[] newPlayers);
    event RaffleRefunded(address player);
    event FeeAddressChanged(address newFeeAddress);

    /// @param _entranceFee the cost in wei to enter the raffle
    /// @param _feeAddress the address to send the fees to
    /// @param _raffleDuration the duration in seconds of the raffle
    constructor(
        uint256 _entranceFee,
        address _feeAddress,
        uint256 _raffleDuration
    ) ERC721("Puppy Raffle", "PR") {
        // @done audit-i need to check for zero fee
        entranceFee = _entranceFee;
        // @done @audit-i need to check for zero fee addres
        feeAddress = _feeAddress;
        // @done @audit-i need to check for zero duration
        raffleDuration = _raffleDuration;
        raffleStartTime = block.timestamp;

        rarityToUri[COMMON_RARITY] = commonImageUri;
        rarityToUri[RARE_RARITY] = rareImageUri;
        rarityToUri[LEGENDARY_RARITY] = legendaryImageUri;

        rarityToName[COMMON_RARITY] = COMMON;
        rarityToName[RARE_RARITY] = RARE;
        rarityToName[LEGENDARY_RARITY] = LEGENDARY;
    }

    /// @notice this is how players enter the raffle
    /// @notice they have to pay the entrance fee * the number of players
    /// @notice duplicate entrants are not allowed
    /// @param newPlayers the list of players to enter the raffle
    // @done @audit-i this should be external
    function enterRaffle(address[] memory newPlayers) public payable {
        // @done @audit-i no check for zero address array for newPlayers
        require(
            msg.value == entranceFee * newPlayers.length,
            "PuppyRaffle: Must send enough to enter raffle"
        );
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
        }

        // Check for duplicates
        // @done @audit-g add the players.length to memory variable
        // @skipped @audit-g assert that there are no duplicates before pushing to storage
        // @done @audit-v DOS attack by calling this function with a lot of players
        for (uint256 i = 0; i < players.length - 1; i++) {
            for (uint256 j = i + 1; j < players.length; j++) {
                require(
                    players[i] != players[j],
                    "PuppyRaffle: Duplicate player"
                );
            }
        }

        // @invalid @audit-v we can add duplicate address by calling this function multiple times
        emit RaffleEnter(newPlayers);
    }

    /// @param playerIndex the index of the player to refund. You can find it externally by calling `getActivePlayerIndex`
    /// @dev This function will allow there to be blank spots in the array
    // @done @audit-i this should be external
    function refund(uint256 playerIndex) public {
        // @skipped-invalid @audit-i no check for index out of bounds
        address playerAddress = players[playerIndex];
        require(
            playerAddress == msg.sender,
            "PuppyRaffle: Only the player can refund"
        );
        require(
            playerAddress != address(0),
            "PuppyRaffle: Player already refunded, or is not active"
        );

        // @done @audit-v-f reentrancy -> SC should follow the checks-effects-interactions pattern.
        payable(msg.sender).sendValue(entranceFee);

        players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }

    /// @notice a way to get the index in the array
    /// @param player the address of a player in the raffle
    /// @return the index of the player in the array, if they are not active, it returns 0
    function getActivePlayerIndex(
        address player
    ) external view returns (uint256) {
        // @done @audit-g add the players length to a memory variable
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return i;
            }
        }

        // @done @audit-v this function will return 0 if the player is not active, but it will also return 0 if the first player is active
        return 0;
    }

    /// @notice this function will select a winner and mint a puppy
    /// @notice there must be at least 4 players, and the duration has occurred
    /// @notice the previous winner is stored in the previousWinner variable
    /// @dev we use a hash of on-chain data to generate the random numbers
    /// @dev we reset the active players array after the winner is selected
    /// @dev we send 80% of the funds to the winner, the other 20% goes to the feeAddress
    // @invalid @audit-v no access control for owner
    function selectWinner() external {
        require(
            block.timestamp >= raffleStartTime + raffleDuration,
            "PuppyRaffle: Raffle not over"
        );
        require(players.length >= 4, "PuppyRaffle: Need at least 4 players");
        // @done @audit-v this pseudo-random number generator is not secure
        // @skipped @audit-v players array might contain zero addresses
        // slither-disable-next-line weak-prng
        uint256 winnerIndex = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.timestamp, block.difficulty)
            )
        ) % players.length;
        // @done @audit-v winner might be zero address
        address winner = players[winnerIndex];
        // @done @audit-v players array might contain zero addresses,
        // @done @audit-v so use address(this).balance
        uint256 totalAmountCollected = players.length * entranceFee;
        // @done @audit-i don't leave magic numbers 80 and 20
        // @done @audit-i move them to constant variables
        uint256 prizePool = (totalAmountCollected * 80) / 100;
        uint256 fee = (totalAmountCollected * 20) / 100;
        // @done @audit-v overflow because of uint64
        totalFees = totalFees + uint64(fee);

        uint256 tokenId = totalSupply();

        // We use a different RNG calculate from the winnerIndex to determine rarity
        // @done @audit-v this pseudo-random number generator is not secure
        // @done @audit-v people can revert the tx if they don't like the rarity
        uint256 rarity = uint256(
            keccak256(abi.encodePacked(msg.sender, block.difficulty))
        ) % 100;

        if (rarity <= COMMON_RARITY) {
            tokenIdToRarity[tokenId] = COMMON_RARITY;
        } else if (rarity <= COMMON_RARITY + RARE_RARITY) {
            tokenIdToRarity[tokenId] = RARE_RARITY;
        } else {
            tokenIdToRarity[tokenId] = LEGENDARY_RARITY;
        }

        // @invalid @audit-v follow checks-effects-interactions pattern
        // @invalid @audit-v delete players instantly after the winner is selected
        delete players;
        raffleStartTime = block.timestamp;
        previousWinner = winner; // @done @audit-i can remove the variable from SC

        // @skipped @audit-i use sendValue instead of call as in previous functions
        // @done @audit-v winner can revert the tx
        (bool success, ) = winner.call{value: prizePool}("");
        require(success, "PuppyRaffle: Failed to send prize pool to winner");

        // @done @audit-v reentrancy -> follow checks-effects-interactions pattern. Firstly mint token
        _safeMint(winner, tokenId);
    }

    /// @notice this function will withdraw the fees to the feeAddress
    // @invalid @audit-v no access control for owner
    function withdrawFees() external {
        // @done @audit-v users can deposit funds with selfdestruct and owner wouldn't be able to withdraw fees
        require(
            address(this).balance == uint256(totalFees),
            "PuppyRaffle: There are currently players active!"
        );
        uint256 feesToWithdraw = totalFees;
        totalFees = 0;

        // @skipped @audit-i use sendValue instead of call as in previous functions
        // @done @audit-i add additional checks for zero amount
        // @skipped @audit-v feeAddress can revert the tx
        // slither-disable-next-line arbitrary-send-eth
        (bool success, ) = feeAddress.call{value: feesToWithdraw}("");
        require(success, "PuppyRaffle: Failed to withdraw fees");
    }

    /// @notice only the owner of the contract can change the feeAddress
    /// @param newFeeAddress the new address to send fees to
    function changeFeeAddress(address newFeeAddress) external onlyOwner {
        // @done @audit-v no check for zero address
        feeAddress = newFeeAddress;

        // @done @audit-i we missing the events in other functions
        emit FeeAddressChanged(newFeeAddress);
    }

    // @invalid @audit-v there is no function for winner to claim their prize

    /// @notice this function will return true if the msg.sender is an active player
    // @done @audit-i this function is not used anywhere
    function _isActivePlayer() internal view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /// @notice this could be a constant variable
    function _baseURI() internal pure returns (string memory) {
        return "data:application/json;base64,";
    }

    /// @notice this function will return the URI for the token
    /// @param tokenId the Id of the NFT
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "PuppyRaffle: URI query for nonexistent token"
        );

        uint256 rarity = tokenIdToRarity[tokenId];
        string memory imageURI = rarityToUri[rarity];
        string memory rareName = rarityToName[rarity];

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '"attributes": [{"trait_type": "rarity", "value": ',
                                rareName,
                                '}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
