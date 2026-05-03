// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Keys } from "../Base.sol";
import { Cursors, Cur, Schemas } from "../../Cursors.sol";
import { ControlEvent } from "../../events/Control.sol";
using Cursors for Cur;

abstract contract DenyAssetsHook {
    /// @dev Override to deny a single asset/meta pair.
    /// Called once per ASSET block in the request.
    function denyAsset(bytes32 asset, bytes32 meta) internal virtual;
}

/// @title DenyAssets
/// @notice Control command that blocks a list of (asset, meta) pairs via a virtual hook.
/// Each ASSET block in the request calls `denyAsset`. Only callable by the admin account.
abstract contract DenyAssets is CommandBase, ControlEvent, DenyAssetsHook {
    string private constant NAME = "denyAssets";

    uint internal immutable denyAssetsId = commandId(NAME);

    constructor() {
        emit Control(host, denyAssetsId, NAME, Schemas.Asset, Keys.Empty, Keys.Empty, false);
    }

    function denyAssets(
        CommandContext calldata c
    ) external onlyAdmin(c.account) returns (bytes memory) {
        (Cur memory request, , ) = cursor(c.request, 1);

        while (request.i < request.bound) {
            (bytes32 asset, bytes32 meta) = request.unpackAsset();
            denyAsset(asset, meta);
        }

        request.complete();
        return "";
    }
}






