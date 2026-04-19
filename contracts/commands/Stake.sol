// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, State } from "./Base.sol";
import { HostAmount, Cur, Cursors } from "../Cursors.sol";

string constant SCTP = "stakeCustodyToPosition";

using Cursors for Cur;

abstract contract StakeCustodyToPositionHook {
    /// @dev Override to stake a custody position into a non-balance setup
    /// target described by `request`.
    function stakeCustodyToPosition(bytes32 account, HostAmount memory custody, Cur memory request) internal virtual;
}

/// @title StakeCustodyToPosition
/// @notice Command that stakes CUSTODY state positions into a non-balance target
/// described by the request stream. Produces no output state.
abstract contract StakeCustodyToPosition is CommandBase, StakeCustodyToPositionHook {
    uint internal immutable stakeCustodyToPositionId = commandId(SCTP);

    constructor(string memory input) {
        emit Command(host, SCTP, input, stakeCustodyToPositionId, State.Custodies, State.Empty, false);
    }

    function stakeCustodyToPosition(
        CommandContext calldata c
    ) external onlyCommand(stakeCustodyToPositionId, c.target) returns (bytes memory) {
        (Cur memory state, , ) = cursor(c.state, 1);
        Cur memory request = cursor(c.request);

        while (state.i < state.bound) {
            HostAmount memory custody = state.unpackCustodyValue();
            stakeCustodyToPosition(c.account, custody, request);
        }

        state.complete();
        return "";
    }
}








