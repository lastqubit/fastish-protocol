// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Host} from "../Host.sol";
import {Value, useValue} from "../Utils/Value.sol";

uint constant DONE = 1 << 248;
uint constant NEXT = 2 << 248;

uint8 constant INITIATE = 1;
uint8 constant TRANSFER = 2;
uint8 constant UTILIZE = 3;
uint8 constant SETTLE = 4;

interface IUtilize {
    function utilize(
        uint account,
        uint id,
        uint amount,
        bytes calldata data,
        bytes calldata step
    ) external payable returns (bytes32, bytes memory);
}

// @dev open endpoint = user can use endpoint as entry point
abstract contract Command is Host {
    function done() internal pure returns (bytes32, bytes memory) {
        return (0, "");
    }

    function getRequest(
        bytes calldata step
    ) internal pure returns (bytes calldata) {
        return step[64:];
    }
}
