// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Query} from "./Base.sol";

string constant ABI = "function getTrusted(address addr) external view returns (bool)";
bytes4 constant SELECTOR = IGetTrusted.getTrusted.selector;

interface IGetTrusted {
    function getTrusted(address addr) external view returns (bool);
}

abstract contract GetTrusted is IGetTrusted, Query {
    constructor() {
        emit Endpoint(hostId, toEid(SELECTOR), 0, ABI, "");
    }

    function getTrusted(address addr) external view virtual returns (bool);
}
