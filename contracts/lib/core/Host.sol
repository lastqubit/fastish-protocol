// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {AccessControl} from "./Access.sol";
import {Authorize} from "../commands/admin/Authorize.sol";
import {Unauthorize} from "../commands/admin/Unauthorize.sol";
import {Relocate} from "../commands/admin/Relocate.sol";
import {IHostDiscovery} from "../discovery/IHostDiscovery.sol";

abstract contract Host is Authorize, Unauthorize, Relocate {
    constructor(address cmdr, address discovery, uint8 version, string memory namespace) AccessControl(cmdr) {
        if (discovery == address(0)) return;
        IHostDiscovery(discovery).announceHost(host, block.number, version, namespace);
    }

    receive() external payable {}
}
