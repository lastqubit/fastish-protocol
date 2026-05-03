// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { RemoteBase } from "./Base.sol";
import { AllowAssetsHook } from "../commands/control/AllowAssets.sol";
import { Cursors, Cur, Schemas } from "../Cursors.sol";

using Cursors for Cur;

string constant NAME = "remoteAllowAssets";

/// @title RemoteAllowAssets
/// @notice Remote that permits a list of (asset, meta) pairs on behalf of a remote host.
/// Each ASSET block in the request calls `allowAsset`. Restricted to trusted remotes.
abstract contract RemoteAllowAssets is RemoteBase, AllowAssetsHook {
    uint internal immutable remoteAllowAssetsId = remoteId(NAME);

    constructor() {
        emit Remote(host, remoteAllowAssetsId, NAME, Schemas.Asset, false);
    }

    /// @notice Execute the allow-assets remote call.
    function remoteAllowAssets(bytes calldata request) external onlyRemote returns (bytes memory) {
        (Cur memory assets, , ) = cursor(request, 1);

        while (assets.i < assets.bound) {
            (bytes32 asset, bytes32 meta) = assets.unpackAsset();
            allowAsset(asset, meta);
        }

        assets.complete();
        return "";
    }
}





