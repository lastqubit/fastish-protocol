// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "../core/Host.sol";
import {Mint} from "../commands/Mint.sol";
import {DataRef} from "../blocks/Schema.sol";
import {toHostId} from "../utils/Ids.sol";

contract TestMintHost is Host, Mint {
    event MintCalled(bytes32 account, bytes routeData);

    bytes32 public returnAsset;
    bytes32 public returnMeta;
    uint    public returnAmount;

    constructor(address cmdr)
        Host(address(0), 1, "test")
        Mint("")
    {
        if (cmdr != address(0)) access(toHostId(cmdr), true);
    }

    function setReturn(bytes32 asset, bytes32 meta, uint amount) external {
        returnAsset = asset;
        returnMeta  = meta;
        returnAmount = amount;
    }

    function mint(bytes32 account, DataRef memory rawRoute)
        internal override
        returns (bytes32 asset, bytes32 meta, uint amount)
    {
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        emit MintCalled(account, routeData);
        return (returnAsset, returnMeta, returnAmount);
    }

    function getMintId() external view returns (uint) { return mintId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}
