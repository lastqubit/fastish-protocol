// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { Remove } from "../commands/Remove.sol";
import { Blocks, Block, Cursor } from "../Blocks.sol";
import { Ids } from "../utils/Ids.sol";

using Blocks for Block;

contract TestRemoveHost is Host, Remove {
    event RemoveCalled(bytes32 account, bytes inputData);

    constructor(address cmdr)
        Host(address(0), 1, "test")
        Remove("")
    {
        if (cmdr != address(0)) access(Ids.toHost(cmdr), true);
    }

    function remove(bytes32 account, Cursor memory input) internal override {
        Block memory ref = Blocks.at(input.i);
        bytes calldata inputData = msg.data[ref.i:ref.bound];
        emit RemoveCalled(account, inputData);
    }

    function getRemoveId() external view returns (uint) { return removeId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}
