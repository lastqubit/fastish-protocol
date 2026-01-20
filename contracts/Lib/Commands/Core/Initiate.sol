// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function initiate(uint account, bytes step) external payable returns (bytes32, bytes)";
bytes4 constant SELECTOR = IInitiate.initiate.selector;

interface IInitiate {
    function initiate(
        uint account,
        bytes calldata step
    ) external payable returns (bytes32, bytes memory);
}

function encodeInitiate(uint account) pure returns (bytes32, bytes memory) {
    return (SELECTOR, abi.encode(account, ""));
}

abstract contract Initiate is IInitiate, Command {
    uint internal immutable initiateId = toEid(false, SELECTOR);

    constructor(string memory params) {
        emit Endpoint(hostId, initiateId, 0, ABI, params);
    }

    function isLocalInitiate(uint eid) internal view returns (bool) {
        return eid == initiateId;
    }

    function initiate(
        uint account,
        bytes calldata step
    ) external payable virtual returns (bytes32, bytes memory);
}
