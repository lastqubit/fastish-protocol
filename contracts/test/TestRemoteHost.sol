// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Host } from "../core/Host.sol";
import { RemoteAllowance } from "../remote/Allowance.sol";
import { RemoteAssetPull } from "../remote/AssetPull.sol";
import { RemoteSettle } from "../remote/Settle.sol";
import { Tx } from "../Cursors.sol";

contract TestRemoteHost is Host, RemoteAllowance, RemoteAssetPull, RemoteSettle {
    event RemoteAllowanceCalled(uint remote, bytes32 asset, bytes32 meta, uint amount);
    event RemoteAssetPullCalled(uint remote, bytes32 asset, bytes32 meta, uint amount);
    event RemoteSettleCalled(bytes32 from_, bytes32 to_, bytes32 asset, bytes32 meta, uint amount);

    constructor(address cmdr) Host(cmdr, 1, "test") {}

    function allowance(uint remote, bytes32 asset, bytes32 meta, uint amount) internal override {
        emit RemoteAllowanceCalled(remote, asset, meta, amount);
    }

    function assetPull(uint remote, bytes32 asset, bytes32 meta, uint amount) internal override {
        emit RemoteAssetPullCalled(remote, asset, meta, amount);
    }

    function transfer(Tx memory value) internal override {
        emit RemoteSettleCalled(value.from, value.to, value.asset, value.meta, value.amount);
    }

    function getRemoteAllowanceId() external view returns (uint) { return remoteAllowanceId; }
    function getRemoteAssetPullId() external view returns (uint) { return remoteAssetPullId; }
    function getRemoteSettleId() external view returns (uint) { return remoteSettleId; }
    function getAdminAccount() external view returns (bytes32) { return adminAccount; }
}




