// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function inject(bytes32 head, bytes body, bytes[] steps) external payable returns(uint count)";
bytes4 constant SELECTOR = IInject.inject.selector;

interface IInject {
    function inject(
        bytes32 head,
        bytes memory body,
        bytes[] calldata steps
    ) external payable returns (uint);
}

abstract contract Inject is IInject, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function inject(
        bytes32 head,
        bytes memory body,
        bytes[] calldata steps
    ) external payable virtual returns (uint);
}
