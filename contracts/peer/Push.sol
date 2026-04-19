// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { PeerBase } from "./Base.sol";
import { Cursors, Cur } from "../Cursors.sol";

string constant NAME = "peerPush";

using Cursors for Cur;

abstract contract PeerPushHook {
    /// @notice Override to process a single incoming block from the push request.
    /// @param peer Host node ID derived from the caller address.
    /// @param input Cursor positioned at the current input block; advance it before returning.
    function peerPush(uint peer, Cur memory input) internal virtual;
}

/// @title PeerPush
/// @notice Peer that receives assets pushed from a remote host into this one.
/// Each block in the request is dispatched to `peerPush(peer, input)`, where `peer`
/// is derived from `msg.sender`. Restricted to trusted peers.
abstract contract PeerPush is PeerBase, PeerPushHook {
    uint internal immutable peerPushId = peerId(NAME);

    constructor(string memory input) {
        emit Peer(host, NAME, input, peerPushId, false);
    }

    /// @notice Execute the push peer call.
    function peerPush(bytes calldata request) external onlyPeer returns (bytes memory) {
        (Cur memory input, , ) = cursor(request, 1);
        uint peer = caller();

        while (input.i < input.bound) {
            peerPush(peer, input);
        }

        input.complete();
        return "";
    }
}






