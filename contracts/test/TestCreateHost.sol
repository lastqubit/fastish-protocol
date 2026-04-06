// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { Create } from "../commands/Create.sol";
import { Cursors, Cursor, Keys } from "../Cursors.sol";
import { Ids } from "../utils/Ids.sol";
using Cursors for Cursor;

contract TestCreateHost is Host, Create {
    event CreateCalled(bytes32 account, bytes inputData);

    constructor(address cmdr)
        Host(address(0), 1, "test")
        Create("")
    {
        if (cmdr != address(0)) access(Ids.toHost(cmdr), true);
    }

    function create(bytes32 account, Cursor memory input) internal override {
        bytes calldata inputData = input.isAt(Keys.Route) ? input.unpackRoute() : msg.data[input.i:input.end];
        emit CreateCalled(account, inputData);
    }

    function getCreateId() external view returns (uint) { return createId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}


