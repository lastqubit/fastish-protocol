// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { EventEmitter } from "./Emitter.sol";

string constant ABI =
    "event Remote(uint indexed host, uint id, string name, string request, bool acceptsValue)";

/// @notice Emitted once per remote during host deployment to publish its request schema.
abstract contract RemoteEvent is EventEmitter {
    /// @param host Host node ID that owns this remote.
    /// @param id Remote node ID.
    /// @param name Human-readable remote name.
    /// @param request Schema DSL string describing the remote request shape.
    /// @param acceptsValue Whether the remote entrypoint accepts nonzero `msg.value`.
    event Remote(uint indexed host, uint id, string name, string request, bool acceptsValue);

    constructor() {
        emit EventAbi(ABI);
    }
}



