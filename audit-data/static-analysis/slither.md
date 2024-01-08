INFO:Detectors:
PuppyRaffle.withdrawFees() (src/PuppyRaffle.sol#225-238) sends eth to arbitrary user
Dangerous calls: - (success) = feeAddress.call{value: feesToWithdraw}() (src/PuppyRaffle.sol#236)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
INFO:Detectors:
PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221) uses a weak PRNG: "winnerIndex = uint256(keccak256(bytes)(abi.encodePacked(msg.sender,block.timestamp,block.difficulty))) % players.length (src/PuppyRaffle.sol#176-180)"
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG
INFO:Detectors:
PuppyRaffle.withdrawFees() (src/PuppyRaffle.sol#225-238) uses a dangerous strict equality: - require(bool,string)(address(this).balance == uint256(totalFees),PuppyRaffle: There are currently players active!) (src/PuppyRaffle.sol#228-231)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
INFO:Detectors:
Reentrancy in PuppyRaffle.refund(uint256) (src/PuppyRaffle.sol#123-141):
External calls: - address(msg.sender).sendValue(entranceFee) (src/PuppyRaffle.sol#137)
State variables written after the call(s): - players[playerIndex] = address(0) (src/PuppyRaffle.sol#139)
PuppyRaffle.players (src/PuppyRaffle.sol#24) can be used in cross function reentrancies: - PuppyRaffle.enterRaffle(address[]) (src/PuppyRaffle.sol#95-119) - PuppyRaffle.getActivePlayerIndex(address) (src/PuppyRaffle.sol#146-159) - PuppyRaffle.players (src/PuppyRaffle.sol#24) - PuppyRaffle.refund(uint256) (src/PuppyRaffle.sol#123-141) - PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
INFO:Detectors:
PuppyRaffle.constructor(uint256,address,uint256).\_feeAddress (src/PuppyRaffle.sol#70) lacks a zero-check on : - feeAddress = \_feeAddress (src/PuppyRaffle.sol#78)
PuppyRaffle.changeFeeAddress(address).newFeeAddress (src/PuppyRaffle.sol#242) lacks a zero-check on : - feeAddress = newFeeAddress (src/PuppyRaffle.sol#244)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
INFO:Detectors:
Reentrancy in PuppyRaffle.refund(uint256) (src/PuppyRaffle.sol#123-141):
External calls: - address(msg.sender).sendValue(entranceFee) (src/PuppyRaffle.sol#137)
Event emitted after the call(s): - RaffleRefunded(playerAddress) (src/PuppyRaffle.sol#140)
Reentrancy in PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221):
External calls: - (success) = winner.call{value: prizePool}() (src/PuppyRaffle.sol#216) - \_safeMint(winner,tokenId) (src/PuppyRaffle.sol#220) - returndata = to.functionCall(abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector,\_msgSender(),from,tokenId,\_data),ERC721: transfer to non ERC721Receiver implementer) (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#441-447) - (success,returndata) = target.call{value: value}(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#119)
External calls sending eth: - (success) = winner.call{value: prizePool}() (src/PuppyRaffle.sol#216) - \_safeMint(winner,tokenId) (src/PuppyRaffle.sol#220) - (success,returndata) = target.call{value: value}(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#119)
Event emitted after the call(s): - Transfer(address(0),to,tokenId) (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#343) - \_safeMint(winner,tokenId) (src/PuppyRaffle.sol#220)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
INFO:Detectors:
PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221) uses timestamp for comparisons
Dangerous comparisons: - require(bool,string)(block.timestamp >= raffleStartTime + raffleDuration,PuppyRaffle: Raffle not over) (src/PuppyRaffle.sol#169-172)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp
INFO:Detectors:
Different versions of Solidity are used: - Version used: ['>=0.6.0', '>=0.6.0<0.8.0', '>=0.6.2<0.8.0', '^0.7.6'] - >=0.6.0 (lib/base64/base64.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/access/Ownable.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/introspection/ERC165.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/introspection/IERC165.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/math/SafeMath.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/Context.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/EnumerableMap.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/EnumerableSet.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/Strings.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Enumerable.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Metadata.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/utils/Address.sol#3) - ^0.7.6 (src/PuppyRaffle.sol#3)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used
INFO:Detectors:
PuppyRaffle.\_isActivePlayer() (src/PuppyRaffle.sol#252-259) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
INFO:Detectors:
Pragma version^0.7.6 (src/PuppyRaffle.sol#3) allows old versions
solc-0.7.6 is not recommended for deployment
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Detectors:
Low level call in PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221): - (success) = winner.call{value: prizePool}() (src/PuppyRaffle.sol#216)
Low level call in PuppyRaffle.withdrawFees() (src/PuppyRaffle.sol#225-238): - (success) = feeAddress.call{value: feesToWithdraw}() (src/PuppyRaffle.sol#236)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls
INFO:Detectors:
Loop condition j < players.length (src/PuppyRaffle.sol#108) should use cached array length instead of referencing `length` member of the storage array.
Loop condition i < players.length (src/PuppyRaffle.sol#150) should use cached array length instead of referencing `length` member of the storage array.
Loop condition i < players.length (src/PuppyRaffle.sol#253) should use cached array length instead of referencing `length` member of the storage array.
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#cache-array-length
INFO:Detectors:
PuppyRaffle.commonImageUri (src/PuppyRaffle.sol#41-42) should be constant
PuppyRaffle.legendaryImageUri (src/PuppyRaffle.sol#55-56) should be constant
PuppyRaffle.rareImageUri (src/PuppyRaffle.sol#48-49) should be constant
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-constant
INFO:Detectors:
PuppyRaffle.raffleDuration (src/PuppyRaffle.sol#25) should be immutable
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-immutable
INFO:Slither:. analyzed (16 contracts with 92 detectors), 22 result(s) found
[12:12:07] 4-puppy-raffle-audit$ slither . > slither.md
'forge clean' running (wd: /home/benas/coding/blockchain/security-and-auditing/4-puppy-raffle-audit)
'forge build --build-info --skip _/test/\*\* _/script/\*\* --force' running (wd: /home/benas/coding/blockchain/security-and-auditing/4-puppy-raffle-audit)
INFO:Detectors:
PuppyRaffle.withdrawFees() (src/PuppyRaffle.sol#225-238) sends eth to arbitrary user
Dangerous calls: - (success) = feeAddress.call{value: feesToWithdraw}() (src/PuppyRaffle.sol#236)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
INFO:Detectors:
PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221) uses a weak PRNG: "winnerIndex = uint256(keccak256(bytes)(abi.encodePacked(msg.sender,block.timestamp,block.difficulty))) % players.length (src/PuppyRaffle.sol#176-180)"
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG
INFO:Detectors:
PuppyRaffle.withdrawFees() (src/PuppyRaffle.sol#225-238) uses a dangerous strict equality: - require(bool,string)(address(this).balance == uint256(totalFees),PuppyRaffle: There are currently players active!) (src/PuppyRaffle.sol#228-231)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
INFO:Detectors:
Reentrancy in PuppyRaffle.refund(uint256) (src/PuppyRaffle.sol#123-141):
External calls: - address(msg.sender).sendValue(entranceFee) (src/PuppyRaffle.sol#137)
State variables written after the call(s): - players[playerIndex] = address(0) (src/PuppyRaffle.sol#139)
PuppyRaffle.players (src/PuppyRaffle.sol#24) can be used in cross function reentrancies: - PuppyRaffle.enterRaffle(address[]) (src/PuppyRaffle.sol#95-119) - PuppyRaffle.getActivePlayerIndex(address) (src/PuppyRaffle.sol#146-159) - PuppyRaffle.players (src/PuppyRaffle.sol#24) - PuppyRaffle.refund(uint256) (src/PuppyRaffle.sol#123-141) - PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
INFO:Detectors:
PuppyRaffle.constructor(uint256,address,uint256).\_feeAddress (src/PuppyRaffle.sol#70) lacks a zero-check on : - feeAddress = \_feeAddress (src/PuppyRaffle.sol#78)
PuppyRaffle.changeFeeAddress(address).newFeeAddress (src/PuppyRaffle.sol#242) lacks a zero-check on : - feeAddress = newFeeAddress (src/PuppyRaffle.sol#244)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
INFO:Detectors:
Reentrancy in PuppyRaffle.refund(uint256) (src/PuppyRaffle.sol#123-141):
External calls: - address(msg.sender).sendValue(entranceFee) (src/PuppyRaffle.sol#137)
Event emitted after the call(s): - RaffleRefunded(playerAddress) (src/PuppyRaffle.sol#140)
Reentrancy in PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221):
External calls: - (success) = winner.call{value: prizePool}() (src/PuppyRaffle.sol#216) - \_safeMint(winner,tokenId) (src/PuppyRaffle.sol#220) - returndata = to.functionCall(abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector,\_msgSender(),from,tokenId,\_data),ERC721: transfer to non ERC721Receiver implementer) (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#441-447) - (success,returndata) = target.call{value: value}(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#119)
External calls sending eth: - (success) = winner.call{value: prizePool}() (src/PuppyRaffle.sol#216) - \_safeMint(winner,tokenId) (src/PuppyRaffle.sol#220) - (success,returndata) = target.call{value: value}(data) (lib/openzeppelin-contracts/contracts/utils/Address.sol#119)
Event emitted after the call(s): - Transfer(address(0),to,tokenId) (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#343) - \_safeMint(winner,tokenId) (src/PuppyRaffle.sol#220)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
INFO:Detectors:
PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221) uses timestamp for comparisons
Dangerous comparisons: - require(bool,string)(block.timestamp >= raffleStartTime + raffleDuration,PuppyRaffle: Raffle not over) (src/PuppyRaffle.sol#169-172)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp
INFO:Detectors:
Different versions of Solidity are used: - Version used: ['>=0.6.0', '>=0.6.0<0.8.0', '>=0.6.2<0.8.0', '^0.7.6'] - >=0.6.0 (lib/base64/base64.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/access/Ownable.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/introspection/ERC165.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/introspection/IERC165.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/math/SafeMath.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/Context.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/EnumerableMap.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/EnumerableSet.sol#3) - >=0.6.0<0.8.0 (lib/openzeppelin-contracts/contracts/utils/Strings.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Enumerable.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Metadata.sol#3) - >=0.6.2<0.8.0 (lib/openzeppelin-contracts/contracts/utils/Address.sol#3) - ^0.7.6 (src/PuppyRaffle.sol#3)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used
INFO:Detectors:
PuppyRaffle.\_isActivePlayer() (src/PuppyRaffle.sol#252-259) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
INFO:Detectors:
Pragma version^0.7.6 (src/PuppyRaffle.sol#3) allows old versions
solc-0.7.6 is not recommended for deployment
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Detectors:
Low level call in PuppyRaffle.selectWinner() (src/PuppyRaffle.sol#168-221): - (success) = winner.call{value: prizePool}() (src/PuppyRaffle.sol#216)
Low level call in PuppyRaffle.withdrawFees() (src/PuppyRaffle.sol#225-238): - (success) = feeAddress.call{value: feesToWithdraw}() (src/PuppyRaffle.sol#236)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls
INFO:Detectors:
Loop condition j < players.length (src/PuppyRaffle.sol#108) should use cached array length instead of referencing `length` member of the storage array.
Loop condition i < players.length (src/PuppyRaffle.sol#150) should use cached array length instead of referencing `length` member of the storage array.
Loop condition i < players.length (src/PuppyRaffle.sol#253) should use cached array length instead of referencing `length` member of the storage array.
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#cache-array-length
INFO:Detectors:
PuppyRaffle.commonImageUri (src/PuppyRaffle.sol#41-42) should be constant
PuppyRaffle.legendaryImageUri (src/PuppyRaffle.sol#55-56) should be constant
PuppyRaffle.rareImageUri (src/PuppyRaffle.sol#48-49) should be constant
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-constant
INFO:Detectors:
PuppyRaffle.raffleDuration (src/PuppyRaffle.sol#25) should be immutable
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-immutable
INFO:Slither:. analyzed (16 contracts with 92 detectors), 22 result(s) found
