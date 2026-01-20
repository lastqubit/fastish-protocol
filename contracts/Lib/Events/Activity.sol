// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {EventEmitter} from "./Emitter.sol";

abstract contract ActivityEmitter is EventEmitter {
    function activityEvent(string memory _abi) internal {
        emit EventDefinition(false, address(this), block.number, "activity", _abi);
    }
}
