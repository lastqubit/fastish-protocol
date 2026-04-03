// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { PeerBase } from "./Base.sol";
import { Blocks, Cursor } from "../Blocks.sol";

string constant NAME = "peerPush";

abstract contract PeerPush is PeerBase {
    uint internal immutable peerPushId = peerId(NAME);

    constructor(string memory input) {
        emit Peer(host, NAME, input, peerPushId);
    }

    function peerPush(Cursor memory input) internal virtual;

    function peerPush(bytes calldata request) external payable onlyPeer returns (bytes memory) {
        uint q = 0;
        while (q < request.length) {
            Cursor memory input = Blocks.cursorFrom(request, q);
            peerPush(input);
            q = input.cursor;
        }

        return done(0, q);
    }
}
