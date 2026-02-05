// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {DeployedEvent} from "../Events/Node/Deployed.sol";
import {IHostDiscovery} from "../Host.sol";
import {ensureNode} from "../Utils.sol";

abstract contract Discovery is DeployedEvent, IHostDiscovery {
    function deployed(uint id, uint block0, uint8 version, string calldata namespace) external {
        emit Deployed(ensureNode(id, msg.sender), tx.origin, block0, version, namespace);
    }
}
