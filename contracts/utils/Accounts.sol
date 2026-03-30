// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Layout} from "./Layout.sol";
import {isFamily, toLocalBase, toUnspecifiedBase} from "./Utils.sol";

library Accounts {
    error InvalidAccount();

    uint24 constant Family = (uint24(Layout.Evm32) << 8) | uint24(Layout.Account);
    uint32 constant Admin = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Account) << 8) | uint32(Layout.Admin);
    uint32 constant User = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Account) << 8) | uint32(Layout.User);
    uint32 constant Ref = (uint32(Layout.Ref32) << 16) | (uint32(Layout.Account) << 8) | uint32(Layout.Pointer);

    function prefix(bytes32 account) internal pure returns (uint32) {
        return uint32(uint(account) >> 224);
    }

    function isAdmin(bytes32 account) internal pure returns (bool) {
        return prefix(account) == Admin;
    }

    function isRef(bytes32 account) internal pure returns (bool) {
        return prefix(account) == Ref;
    }

    function toAdmin(address addr) internal view returns (bytes32) {
        return bytes32(toLocalBase(Admin) | (uint(uint160(addr)) << 32));
    }

    function toUser(address addr) internal pure returns (bytes32) {
        return bytes32(toUnspecifiedBase(User) | (uint(uint160(addr)) << 32));
    }

    function toRef(bytes calldata raw) internal pure returns (bytes32 account) {
        uint offset;
        assembly ("memory-safe") {
            offset := raw.offset
        }

        return bytes32((uint(Ref) << 224) | offset);
    }

    function encode(bytes calldata raw) internal pure returns (bytes32 account) {
        return raw.length > 32 ? toRef(raw) : bytes32(raw);
    }

    function resolve(bytes32 account) internal pure returns (bytes calldata raw) {
        if (!isRef(account)) revert InvalidAccount();

        uint offset = uint(account) & ((uint(1) << 224) - 1);
        if (offset < 32 || offset > msg.data.length) revert InvalidAccount();

        uint len;
        assembly ("memory-safe") {
            len := calldataload(sub(offset, 32))
        }

        if (offset + len > msg.data.length) revert InvalidAccount();

        assembly ("memory-safe") {
            raw.offset := offset
            raw.length := len
        }
    }

    function ensureEvm(bytes32 account) internal pure returns (bytes32) {
        if (!isFamily(uint(account), Family)) {
            revert InvalidAccount();
        }
        return account;
    }

    function addrEvm(bytes32 account) internal pure returns (address) {
        return address(uint160(uint(ensureEvm(account)) >> 32));
    }
}
