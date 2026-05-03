// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { NodeCalls } from "../core/Calls.sol";
import { RemoteEvent } from "../events/Remote.sol";
import { Ids, Selectors } from "../utils/Ids.sol";

/// @notice ABI-encode a remote call from a target remote ID and request block stream.
/// @dev Derives the function selector from `target` via `Ids.remoteSelector(target)`.
/// Reverts if `target` is not a valid remote ID.
/// @param target Destination remote node ID embedding the target selector.
/// @param request Input block stream for the remote invocation.
/// @return ABI-encoded calldata for the remote entry point.
function encodeRemoteCall(uint target, bytes calldata request) pure returns (bytes memory) {
    bytes4 selector = Ids.remoteSelector(target);
    return abi.encodeWithSelector(selector, request);
}

/// @title RemoteBase
/// @notice Abstract base for all rootzero remote contracts.
/// Remotes handle inter-host operations and asset allow/deny management
/// between cooperating hosts. Access is restricted to trusted callers via `onlyRemote`.
abstract contract RemoteBase is NodeCalls, RemoteEvent {
    /// @dev Thrown when the commander attempts to call a remote entrypoint directly.
    error CommanderNotAllowed();

    /// @dev Restrict execution to trusted callers, excluding the commander.
    modifier onlyRemote() {
        if (msg.sender == commander) revert CommanderNotAllowed();
        enforceCaller(msg.sender);
        _;
    }

    /// @notice Derive the deterministic node ID for a named remote on this contract.
    /// @param name Remote function name (without argument list).
    /// @return Remote node ID.
    function remoteId(string memory name) internal view returns (uint) {
        return Ids.toRemote(Selectors.remote(name), address(this));
    }
}
