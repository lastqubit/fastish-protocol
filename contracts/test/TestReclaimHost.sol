// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "../core/Host.sol";
import {Reclaim} from "../commands/Reclaim.sol";
import {AssetAmount} from "../blocks/Schema.sol";
import {toHostId} from "../utils/Ids.sol";

contract TestReclaimHost is Host, Reclaim {
    event ReclaimCalled(uint hostId, bytes32 account, bytes32 asset, bytes32 meta, uint amount);

    constructor(address cmdr)
        Host(address(0), 1, "test")
        Reclaim()
    {
        if (cmdr != address(0)) access(toHostId(cmdr), true);
    }

    function reclaim(uint hostId, bytes32 account, bytes32 asset, bytes32 meta, uint amount)
        internal override returns (AssetAmount memory)
    {
        emit ReclaimCalled(hostId, account, asset, meta, amount);
        return AssetAmount(asset, meta, amount);
    }

    function getReclaimId() external view returns (uint) { return reclaimId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}
