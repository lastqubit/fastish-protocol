// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {RemoteBase} from "./Base.sol";
import {Cursors, Cur, Schemas} from "../Cursors.sol";

string constant NAME = "remoteAssetPull";

using Cursors for Cur;

abstract contract AssetPullHook {
    /// @notice Override to process one incoming amount-based asset pull request from a remote host.
    /// @param remote Remote host node ID for this request.
    /// @param asset Requested asset identifier.
    /// @param meta Requested asset metadata slot.
    /// @param amount Requested amount in the asset's native units.
    function assetPull(uint remote, bytes32 asset, bytes32 meta, uint amount) internal virtual;
}

/// @title RemoteAssetPull
/// @notice Remote that pulls requested asset amounts from a remote host into this one.
/// Each AMOUNT block in the request calls `assetPull(remote, asset, meta, amount)`.
/// Restricted to trusted remotes.
abstract contract RemoteAssetPull is RemoteBase, AssetPullHook {
    uint internal immutable remoteAssetPullId = remoteId(NAME);

    constructor() {
        emit Remote(host, remoteAssetPullId, NAME, Schemas.Amount, false);
    }

    /// @notice Execute the asset-pull remote call.
    function remoteAssetPull(bytes calldata request) external onlyRemote returns (bytes memory) {
        (Cur memory assets, , ) = cursor(request, 1);
        uint remote = caller();

        while (assets.i < assets.bound) {
            (bytes32 asset, bytes32 meta, uint amount) = assets.unpackAmount();
            assetPull(remote, asset, meta, amount);
        }

        assets.complete();
        return "";
    }
}
