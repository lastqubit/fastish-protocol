// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { RemoteBase } from "./Base.sol";
import { TransferHook } from "../commands/Transfer.sol";
import { Cursors, Cur, Schemas } from "../Cursors.sol";

using Cursors for Cur;

/// @title RemoteSettle
/// @notice Remote that consumes remote-supplied TRANSACTION blocks through the shared transfer hook.
/// Each TRANSACTION block in the request calls `transfer(value)`. Restricted to trusted remotes.
abstract contract RemoteSettle is RemoteBase, TransferHook {
    string private constant NAME = "remoteSettle";
    uint internal immutable remoteSettleId = remoteId(NAME);

    constructor() {
        emit Remote(host, remoteSettleId, NAME, Schemas.Transaction, false);
    }

    /// @notice Execute the remote-settle call.
    function remoteSettle(bytes calldata request) external onlyRemote returns (bytes memory) {
        (Cur memory state, , ) = cursor(request, 1);

        while (state.i < state.bound) {
            transfer(state.unpackTxValue());
        }

        state.complete();
        return "";
    }
}
