// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { PeerPull } from "../peer/Pull.sol";
import { PeerPush } from "../peer/Push.sol";
import { Blocks, Block, Cursor } from "../Blocks.sol";
import { Ids } from "../utils/Ids.sol";

using Blocks for Block;

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
        Block memory ref = Blocks.at(input.i);
        bytes calldata inputData = msg.data[ref.i:ref.bound];
        emit PeerPullCalled(inputData);
    }

    function peerPush(Cursor memory input) internal override {
        Block memory ref = Blocks.at(input.i);
        bytes calldata inputData = msg.data[ref.i:ref.bound];
        emit PeerPushCalled(inputData);
    }

    function getPeerPullId() external view returns (uint) { return peerPullId; }
    function getPeerPushId() external view returns (uint) { return peerPushId; }
}
