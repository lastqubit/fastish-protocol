// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "./Base.sol";
import { Blocks, Cursor, HostAmount, Keys } from "../Blocks.sol";
string constant NAME = "supply";

using Blocks for Cursor;

abstract contract Supply is CommandBase {
    uint internal immutable supplyId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, "", supplyId, Channels.Custodies, Channels.Setup);
    }

    /// @dev Override to consume or supply a single custody position.
    /// Called once per CUSTODY block in state.
    function supply(bytes32 account, HostAmount memory value) internal virtual;

    function supply(CommandContext calldata c) external payable onlyCommand(supplyId, c.target) returns (bytes memory) {
        (Cursor memory custodies, ) = Blocks.matchingFrom(c.state, 0, Keys.Custody);
        while (custodies.i < custodies.end) {
            HostAmount memory value = custodies.toCustodyValue();
            supply(c.account, value);
        }

        return done(custodies);
    }
}
