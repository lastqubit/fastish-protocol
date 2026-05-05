// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {PeerBase} from "./Base.sol";
import {Cursors, Cur, Schemas} from "../Cursors.sol";

using Cursors for Cur;

abstract contract AssetPullHook {
    /// @notice Override to process one incoming amount-based asset pull request from a peer host.
    /// @param peer Peer host node ID for this request.
    /// @param asset Requested asset identifier.
    /// @param meta Requested asset metadata slot.
    /// @param amount Requested amount in the asset's native units.
    function assetPull(uint peer, bytes32 asset, bytes32 meta, uint amount) internal virtual;
}

/// @title PeerAssetPull
/// @notice Peer that pulls requested asset amounts from a peer host into this one.
/// Each AMOUNT block in the request calls `assetPull(peer, asset, meta, amount)`.
/// Restricted to trusted peers.
abstract contract PeerAssetPull is PeerBase, AssetPullHook {
    string private constant NAME = "peerAssetPull";
    uint internal immutable peerAssetPullId = peerId(NAME);

    constructor() {
        emit Peer(host, peerAssetPullId, NAME, Schemas.Amount, false);
    }

    /// @notice Execute the asset-pull peer call.
    function peerAssetPull(bytes calldata request) external onlyPeer returns (bytes memory) {
        (Cur memory assets, , ) = cursor(request, 1);
        uint peer = caller();

        while (assets.i < assets.bound) {
            (bytes32 asset, bytes32 meta, uint amount) = assets.unpackAmount();
            assetPull(peer, asset, meta, amount);
        }

        assets.complete();
        return "";
    }
}
