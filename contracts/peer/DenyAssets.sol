// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {PeerBase} from "./Base.sol";
import {Blocks, Cursor, Keys, Schemas} from "../Blocks.sol";

using Blocks for Cursor;

string constant NAME = "peerDenyAssets";

abstract contract PeerDenyAssets is PeerBase {
    uint internal immutable peerDenyAssetsId = peerId(NAME);

    constructor() {
        emit Peer(host, NAME, Schemas.Asset, peerDenyAssetsId);
    }

    function peerDenyAsset(bytes32 asset, bytes32 meta) internal virtual returns (bool);

    function peerDenyAssets(bytes calldata request) external payable onlyPeer returns (bytes memory) {
        (Cursor memory input, ) = Blocks.matchingFrom(request, 0, Keys.Asset);
        while (input.i < input.end) {
            (bytes32 asset, bytes32 meta) = input.unpackAsset();
            peerDenyAsset(asset, meta);
        }
        return done(input);
    }
}
