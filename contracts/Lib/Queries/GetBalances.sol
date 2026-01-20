// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Query} from "./Base.sol";

string constant ABI = "function getBalances(uint account, uint[] ids) external view returns (uint[] balances)";
bytes4 constant SELECTOR = IGetBalances.getBalances.selector;

interface IGetBalances {
    function getBalances(
        uint account,
        uint[] calldata ids
    ) external view returns (uint[] memory);
}

abstract contract GetBalances is IGetBalances, Query {
    constructor() {
        emit Endpoint(hostId, toEid(SELECTOR), 0, ABI, "");
    }

    function getBalances(
        uint account,
        uint[] calldata ids
    ) external view virtual returns (uint[] memory);
}
