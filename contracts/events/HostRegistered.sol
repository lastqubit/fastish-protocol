// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {EventEmitter} from "./Emitter.sol";

string constant ABI = "event HostRegistered(uint indexed host, uint blocknum, uint16 version, string namespace)";

abstract contract HostRegisteredEvent is EventEmitter {
    event HostRegistered(uint indexed host, uint blocknum, uint16 version, string namespace);

    constructor() {
        emit EventAbi(ABI);
    }
}
