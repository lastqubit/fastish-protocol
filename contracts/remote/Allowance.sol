// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {RemoteBase} from "./Base.sol";
import {AllowanceHook} from "../commands/control/Allowance.sol";
import {Cursors, Cur, Schemas} from "../Cursors.sol";

using Cursors for Cur;

string constant NAME = "remoteAllowance";

/// @title RemoteAllowance
/// @notice Remote that lets a trusted remote host request or refresh its own allowance.
/// Each AMOUNT block in the request is scoped to the remote host and passed to the
/// shared allowance hook as a host-scoped allowance. Restricted to trusted remotes.
abstract contract RemoteAllowance is RemoteBase, AllowanceHook {
    uint internal immutable remoteAllowanceId = remoteId(NAME);

    constructor() {
        emit Remote(host, remoteAllowanceId, NAME, Schemas.Amount, false);
    }

    /// @notice Execute the allowance remote call.
    function remoteAllowance(bytes calldata request) external onlyRemote returns (bytes memory) {
        (Cur memory amounts, , ) = cursor(request, 1);
        uint remote = caller();

        while (amounts.i < amounts.bound) {
            (bytes32 asset, bytes32 meta, uint amount) = amounts.unpackAmount();
            allowance(remote, asset, meta, amount);
        }

        amounts.complete();
        return "";
    }
}
