// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function authorize(address[] whitelist) external payable returns (bytes32, bytes)";
bytes4 constant SELECTOR = IAuthorize.authorize.selector;

interface IAuthorize {
    function authorize(
        address[] calldata whitelist
    ) external payable returns (bytes32, bytes memory);
}

abstract contract Authorize is IAuthorize, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function authorize(
        address[] calldata list
    ) external payable onlyAdmin returns (bytes32, bytes memory) {
        for (uint i = 0; i < list.length; i++) {
            access(list[i], true);
        }
        return done();
    }
}
