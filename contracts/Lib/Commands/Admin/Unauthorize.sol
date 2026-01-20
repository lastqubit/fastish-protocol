// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Command} from "../Base.sol";

string constant ABI = "function unauthorize(address[] blacklist) external payable returns (bytes32, bytes)";
bytes4 constant SELECTOR = IUnauthorize.unauthorize.selector;

interface IUnauthorize {
    function unauthorize(
        address[] calldata blacklist
    ) external payable returns (bytes32, bytes memory);
}

abstract contract Unauthorize is IUnauthorize, Command {
    constructor() {
        emit Endpoint(hostId, toEid(false, SELECTOR), 0, ABI, "");
    }

    function unauthorize(
        address[] calldata list
    ) external payable onlyAdmin returns (bytes32, bytes memory) {
        for (uint i = 0; i < list.length; i++) {
            access(list[i], false);
        }
        return done();
    }
}
