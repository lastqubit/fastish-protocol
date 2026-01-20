// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function execute(bytes signed, bytes[] steps) external payable returns(uint count)";
bytes4 constant SELECTOR = IExecute.execute.selector;

interface IExecute {
    function execute(
        bytes calldata signed,
        bytes[] calldata steps
    ) external payable returns (uint);
}

///
function toExecute(
    uint head,
    bytes memory body,
    bytes memory signed,
    bytes[] memory steps
) pure returns (bytes memory) {
    return abi.encodePacked(SELECTOR, abi.encode(head, body, signed, steps));
}

abstract contract Execute is IExecute, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function execute(
        bytes calldata signed,
        bytes[] calldata steps
    ) external payable virtual returns (uint);
}
