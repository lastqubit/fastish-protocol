// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { IsAllowedAsset } from "../queries/Assets.sol";

contract TestAllowedAssetQuery is IsAllowedAsset {
    bytes32 public immutable allowedAssetId = bytes32(uint(0xA11));
    bytes32 public immutable allowedMeta = bytes32(uint(0xB22));

    function isAllowedAsset(bytes32 asset, bytes32 meta) internal view override returns (bool allowed) {
        return asset == allowedAssetId && meta == allowedMeta;
    }
}
