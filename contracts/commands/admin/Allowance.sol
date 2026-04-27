// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, State } from "../Base.sol";
import { HostedAmount, Cursors, Cur, Schemas } from "../../Cursors.sol";
using Cursors for Cur;

string constant NAME = "allowance";

abstract contract AllowanceHook {
    /// @notice Apply or revoke one host-scoped allowance.
    /// Called once per ALLOWANCE block in the request. Implementations decide
    /// how the allowance is represented, e.g. ERC-20 approval, an internal cap,
    /// or another host-specific authorization record.
    /// @param allowance Host, asset, meta, and amount describing the allowed cap.
    function allowance(HostedAmount memory allowance) internal virtual;
}

/// @title Allowance
/// @notice Admin command that applies cross-host allowance entries via a virtual hook.
/// Each ALLOWANCE block grants or updates a host-scoped asset cap. Only callable by the admin account.
abstract contract Allowance is CommandBase, AllowanceHook {
    uint internal immutable allowanceId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Allowance, allowanceId, State.Empty, State.Empty, false);
    }

    function allowance(CommandContext calldata c) external onlyAdmin(c.account) returns (bytes memory) {
        (Cur memory request, , ) = cursor(c.request, 1);

        while (request.i < request.bound) {
            HostedAmount memory allowed = request.unpackAllowanceValue();
            allowance(allowed);
        }

        request.complete();
        return "";
    }
}
