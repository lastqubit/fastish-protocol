// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { PeerBase } from "./Base.sol";
import { Blocks, Cursor, Keys, Schemas } from "../Blocks.sol";

using Blocks for Cursor;

string constant NAME = "peerAllowAssets";

abstract contract PeerAllowAssets is PeerBase {
    uint internal immutable peerAllowAssetsId = peerId(NAME);

    constructor() {
        emit Peer(host, NAME, Schemas.Asset, peerAllowAssetsId);
    }

    function peerAllowAsset(bytes32 asset, bytes32 meta) internal virtual returns (bool);

    function peerAllowAssets(bytes calldata request) external payable onlyPeer returns (bytes memory) {
        (Cursor memory input, ) = Blocks.matchingFrom(request, 0, Keys.Asset);
        while (input.i < input.end) {
            (bytes32 asset, bytes32 meta) = input.unpackAsset();
            peerAllowAsset(asset, meta);
        }
        return done(input);
    }
}
