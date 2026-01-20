// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function allow(uint[] ids) external payable returns (bytes32, bytes)";
bytes4 constant SELECTOR = IAllow.allow.selector;

interface IAllow {
    function allow(
        uint[] calldata ids
    ) external payable returns (bytes32, bytes memory);
}

abstract contract Allow is IAllow, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function allow(
        uint[] calldata ids
    ) external payable virtual returns (bytes32, bytes memory);
}
