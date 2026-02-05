// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Node, AccessControl} from "./Node.sol";
import {Authorize} from "./Commands/Core/Admin/Authorize.sol";
import {Unauthorize} from "./Commands/Core/Admin/Unauthorize.sol";
import {Relocate} from "./Commands/Core/Admin/Relocate.sol";
import {IsTrusted} from "./Queries/IsTrusted.sol";

interface IHostDiscovery {
    function deployed(uint id, uint block0, uint8 version, string calldata namespace) external;
}

abstract contract Host is Node, Authorize, Unauthorize, Relocate, IsTrusted {
    constructor(address cmdr, address discovery, uint8 version, string memory namespace) AccessControl(cmdr) {
        if (discovery == address(0)) return;
        IHostDiscovery(discovery).deployed(nodeId, block.number, version, namespace);
    }

    receive() external payable {}
}
