// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Layout} from "./Layout.sol";
import {matchesBase, toLocalBase} from "./Utils.sol";

library Assets {
    error InvalidAsset();

    uint32 constant Value = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Asset) << 8) | uint32(Layout.Value);
    uint32 constant Erc20 = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Asset) << 8) | uint32(Layout.Erc20);
    uint32 constant Erc721 = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Asset) << 8) | uint32(Layout.Erc721);

    function is32(bytes32 asset) internal pure returns (bool) {
        return bytes1(asset) == 0x20;
    }

    function toValue() internal view returns (bytes32) {
        return bytes32(toLocalBase(Value));
    }

    function toErc20(address addr) internal view returns (bytes32) {
        return bytes32(toLocalBase(Erc20) | (uint(uint160(addr)) << 32));
    }

    function toErc721(address issuer) internal view returns (bytes32) {
        return bytes32(toLocalBase(Erc721) | (uint(uint160(issuer)) << 32));
    }

    function key(bytes32 asset, bytes32 meta) internal pure returns (bytes32) {
        if (asset == 0 || (bytes1(asset) == 0x20 && meta != 0)) revert InvalidAsset();
        return bytes1(asset) == 0x20 ? asset : keccak256(bytes.concat(asset, meta));
    }

    function erc20Addr(bytes32 asset) internal view returns (address) {
        if (!matchesBase(asset, toLocalBase(Erc20))) revert InvalidAsset();
        return address(uint160(uint(asset) >> 32));
    }

    function erc721Issuer(bytes32 asset) internal view returns (address) {
        if (!matchesBase(asset, toLocalBase(Erc721))) revert InvalidAsset();
        return address(uint160(uint(asset) >> 32));
    }
}

library Amounts {
    error ZeroAmount();
    error BadAmount(uint amount);

    function ensure(uint amount) internal pure returns (uint) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        return amount;
    }

    function ensure(uint amount, uint min, uint max) internal pure returns (uint) {
        if (amount < min || amount > max) {
            revert BadAmount(amount);
        }
        return amount;
    }

    function ensureKey(bytes32 asset, bytes32 meta, uint amount) internal pure returns (bytes32 key_) {
        ensure(amount);
        return Assets.key(asset, meta);
    }

    function resolve(uint available, uint min, uint max) internal pure returns (uint) {
        uint amount = available > max ? max : available;
        if (amount < min) {
            revert BadAmount(amount);
        }
        return amount;
    }
}



