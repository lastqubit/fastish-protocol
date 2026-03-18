// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "../core/Host.sol";
import {Destroy} from "../commands/Destroy.sol";
import {DataRef} from "../blocks/Schema.sol";
import {toHostId} from "../utils/Ids.sol";

contract TestDestroyHost is Host, Destroy {
    event DestroyCalled(bytes32 account, bytes routeData);

    constructor(address cmdr)
        Host(address(0), 1, "test")
        Destroy("")
    {
        if (cmdr != address(0)) access(toHostId(cmdr), true);
    }

    function destroy(bytes32 account, DataRef memory rawRoute) internal override {
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        emit DestroyCalled(account, routeData);
    }

    function getDestroyId() external view returns (uint) { return destroyId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}
