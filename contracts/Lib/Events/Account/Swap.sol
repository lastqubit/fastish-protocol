// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {ActivityEmitter} from "../Activity.sol";

string constant ABI = "event Swap(uint indexed account, uint indexed eid, uint use, uint accept, uint amount, uint out)";

abstract contract SwapEvent is ActivityEmitter {
    event Swap(
        uint indexed account,
        uint indexed eid,
        uint use,
        uint accept,
        uint amount,
        uint out
    );

    constructor() {
        activityEvent(ABI);
    }
}
