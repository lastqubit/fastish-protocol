// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";
import {Amount} from "../../Utils/Amount.sol";

string constant ABI = "function relocate(address payable to, uint min, uint max) external payable returns (bytes32, bytes)";
bytes4 constant SELECTOR = IRelocate.relocate.selector;

interface IRelocate {
    function relocate(
        address payable to,
        uint min,
        uint max
    ) external payable returns (bytes32, bytes memory);
}

abstract contract Relocate is IRelocate, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function relocate(
        address payable to,
        uint min,
        uint max
    ) external payable onlyAdmin returns (bytes32, bytes memory) {
        _call(to, Amount.resolve(address(this).balance, min, max), "");
        return done();
    }
}
