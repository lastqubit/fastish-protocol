// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {ActivityEmitter} from "../Activity.sol";

string constant ABI = "event Deposit(uint indexed account, uint indexed eid, uint id, uint amount)";

abstract contract DepositEvent is ActivityEmitter {
    event Deposit(uint indexed account, uint indexed eid, uint id, uint amount);

    constructor() {
        activityEvent(ABI);
    }
}
