// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {PeerBase} from "./Base.sol";
import {Cursors, Cur, Schemas} from "../Cursors.sol";

string constant NAME = "peerAssetPull";

using Cursors for Cur;

/// @title PeerAssetPull
/// @notice Peer that pulls assets identified by `(asset, meta)` from a remote host into this one.
/// Each ASSET block in the request calls `peerAssetPull(peer, asset, meta)`, where `peer`
/// is derived from `msg.sender`. Restricted to trusted peers.
abstract contract PeerAssetPull is PeerBase {
    uint internal immutable peerAssetPullId = peerId(NAME);

    constructor() {
        emit Peer(host, NAME, Schemas.Asset, peerAssetPullId, false);
    }

    /// @notice Override to process one incoming asset pull request from a remote host.
    /// @param peer Host node ID derived from the caller address.
    /// @param asset Requested asset identifier.
    /// @param meta Requested asset metadata slot.
    function peerAssetPull(uint peer, bytes32 asset, bytes32 meta) internal virtual;

    /// @notice Execute the asset-pull peer call.
    function peerAssetPull(bytes calldata request) external onlyPeer returns (bytes memory) {
        (Cur memory assets, , ) = cursor(request, 1);
        uint peer = caller();

        while (assets.i < assets.bound) {
            (bytes32 asset, bytes32 meta) = assets.unpackAsset();
            peerAssetPull(peer, asset, meta);
        }

        assets.complete();
        return "";
    }
}
