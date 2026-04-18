// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {PeerBase} from "./Base.sol";
import {Cursors, Cur} from "../Cursors.sol";

string constant NAME = "peerPull";

using Cursors for Cur;

/// @title PeerPull
/// @notice Peer that pulls assets from a remote host into this one.
/// Each block in the request is dispatched to `peerPull(peer, input)`, where `peer`
/// is derived from `msg.sender`. Restricted to trusted peers.
abstract contract PeerPull is PeerBase {
    uint internal immutable peerPullId = peerId(NAME);

    constructor(string memory input) {
        emit Peer(host, NAME, input, peerPullId, false);
    }

    /// @notice Override to process a single incoming block from the pull request.
    /// @param peer Host node ID derived from the caller address.
    /// @param input Cursor positioned at the current input block; advance it before returning.
    function peerPull(uint peer, Cur memory input) internal virtual;

    /// @notice Execute the pull peer call.
    function peerPull(bytes calldata request) external onlyPeer returns (bytes memory) {
        (Cur memory input, , ) = cursor(request, 1);
        uint peer = caller();

        while (input.i < input.bound) {
            peerPull(peer, input);
        }

        input.complete();
        return "";
    }
}
