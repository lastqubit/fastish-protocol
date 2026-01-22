// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Id, Host, AccessControl} from "./Host.sol"; ////
import {Authorize} from "./Commands/Core/Authorize.sol";
import {Unauthorize} from "./Commands/Core/Unauthorize.sol";
import {Relocate} from "./Commands/Core/Relocate.sol";
import {GetTrusted} from "./Queries/GetTrusted.sol";
import {IDiscovery} from "./Discovery.sol";

abstract contract Node is Host, Authorize, Unauthorize, Relocate, GetTrusted {
    uint public immutable valueId = Id.value();

    constructor(address rush, address discovery, string memory name) AccessControl(rush) {
        IDiscovery(discovery).announce(name);
    }

    function getTrusted(address addr) external view override returns (bool) {
        return isTrusted(addr);
    }

    receive() external payable {}
}
