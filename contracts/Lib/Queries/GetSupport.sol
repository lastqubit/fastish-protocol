// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Query} from "./Base.sol";

string constant ABI = "function getSupport(uint[] ids) external view returns (uint8[])";
bytes4 constant SELECTOR = IGetSupport.getSupport.selector;

interface IGetSupport {
    function getSupport(
        uint[] calldata ids
    ) external view returns (uint8[] memory);
}

abstract contract GetSupport is IGetSupport, Query {
    constructor() {
        emit Endpoint(hostId, toEid(SELECTOR), 0, ABI, "");
    }

    function getSupport(
        uint[] calldata ids
    ) external view virtual returns (uint8[] memory);
}
