// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {RemoteBase} from "./Base.sol";
import {DenyAssetsHook} from "../commands/control/DenyAssets.sol";
import {Cursors, Cur, Schemas} from "../Cursors.sol";

using Cursors for Cur;

string constant NAME = "remoteDenyAssets";

/// @title RemoteDenyAssets
/// @notice Remote that blocks a list of (asset, meta) pairs on behalf of a remote host.
/// Each ASSET block in the request calls `denyAsset`. Restricted to trusted remotes.
abstract contract RemoteDenyAssets is RemoteBase, DenyAssetsHook {
    uint internal immutable remoteDenyAssetsId = remoteId(NAME);

    constructor() {
        emit Remote(host, remoteDenyAssetsId, NAME, Schemas.Asset, false);
    }

    /// @notice Execute the deny-assets remote call.
    function remoteDenyAssets(bytes calldata request) external onlyRemote returns (bytes memory) {
        (Cur memory assets, , ) = cursor(request, 1);

        while (assets.i < assets.bound) {
            (bytes32 asset, bytes32 meta) = assets.unpackAsset();
            denyAsset(asset, meta);
        }

        assets.complete();
        return "";
    }
}





