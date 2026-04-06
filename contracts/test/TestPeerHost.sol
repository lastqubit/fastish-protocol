// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { PeerPull } from "../peer/Pull.sol";
import { PeerPush } from "../peer/Push.sol";
import { Cursors, Cursor, Keys } from "../Cursors.sol";
import { Ids } from "../utils/Ids.sol";

using Cursors for Cursor;

contract TestPeerHost is Host, PeerPull, PeerPush {
    event PeerPullCalled(bytes inputData);
    event PeerPushCalled(bytes inputData);

    constructor(address cmdr)
        Host(address(0), 1, "test")
        PeerPull("")
        PeerPush("")
    {
        if (cmdr != address(0)) access(Ids.toHost(cmdr), true);
    }

    function peerPull(Cursor memory input) internal override {
        bytes calldata inputData = input.isAt(Keys.Route) ? input.unpackRoute() : msg.data[input.i:input.end];
        emit PeerPullCalled(inputData);
    }

    function peerPush(Cursor memory input) internal override {
        bytes calldata inputData = input.isAt(Keys.Route) ? input.unpackRoute() : msg.data[input.i:input.end];
        emit PeerPushCalled(inputData);
    }

    function getPeerPullId() external view returns (uint) { return peerPullId; }
    function getPeerPushId() external view returns (uint) { return peerPushId; }
}


