// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {EventEmitter} from "./Emitter.sol";

string constant ABI = "event Rushed(uint indexed host, bytes32 account, uint deadline, uint value)";

abstract contract RushedEvent is EventEmitter {
    event Rushed(uint indexed host, bytes32 account, uint deadline, uint value);

    constructor() {
        emit EventAbi(ABI);
    }
}
