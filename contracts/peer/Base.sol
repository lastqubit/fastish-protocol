// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { OperationBase } from "../core/Operation.sol";
import { PeerEvent } from "../events/Peer.sol";
import { Ids, Selectors } from "../utils/Ids.sol";

abstract contract PeerBase is OperationBase, PeerEvent {
    modifier onlyPeer() {
        enforceCaller(msg.sender);
        _;
    }

    function peerId(string memory name) internal view returns (uint) {
        return Ids.toPeer(Selectors.peer(name), address(this));
    }
}


