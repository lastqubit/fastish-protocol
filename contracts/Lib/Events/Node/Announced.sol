// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {EventEmitter} from "../Emitter.sol";

string constant ABI = "event Announced(uint indexed node, address indexed origin, uint block0, string namespace)";

abstract contract AnnouncedEvent is EventEmitter {
    event Announced(uint indexed node, address indexed origin, uint block0, string namespace);

    constructor() {
        emit EventSignature(ABI);
    }
}
