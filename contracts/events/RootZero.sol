// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { EventEmitter } from "./Emitter.sol";

string constant ABI = "event RootZero(uint indexed host, bytes32 account, uint deadline, uint value)";

abstract contract RootZeroEvent is EventEmitter {
    event RootZero(uint indexed host, bytes32 account, uint deadline, uint value);

    constructor() {
        emit EventAbi(ABI);
    }
}
