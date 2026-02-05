// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {EventEmitter} from "../Emitter.sol";

string constant ABI = "event Deployed(uint indexed host, address indexed origin, uint block0, uint8 version, string namespace)";

abstract contract DeployedEvent is EventEmitter {
    event Deployed(uint indexed host, address indexed origin, uint block0, uint8 version, string namespace);

    constructor() {
        emit Signature(ABI);
    }
}
