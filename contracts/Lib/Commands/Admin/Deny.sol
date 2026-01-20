// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function deny(uint[] ids) external payable returns (bytes32, bytes)";
bytes4 constant SELECTOR = IDeny.deny.selector;

interface IDeny {
    function deny(
        uint[] calldata ids
    ) external payable returns (bytes32, bytes memory);
}

abstract contract Deny is IDeny, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function deny(
        uint[] calldata ids
    ) external payable virtual returns (bytes32, bytes memory);
}
