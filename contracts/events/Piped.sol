// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { EventEmitter } from "./Emitter.sol";

string constant ABI = "event Piped(bytes32 indexed account, uint deadline, uint value)";

/// @notice Emitted for root-level protocol actions (e.g. governance or protocol-wide operations).
abstract contract PipedEvent is EventEmitter {
    /// @param account Account identifier associated with the action.
    /// @param deadline Expiry timestamp of the action.
    /// @param value Native value associated with the action.
    event Piped(bytes32 indexed account, uint deadline, uint value);

    constructor() {
        emit EventAbi(ABI);
    }
}
