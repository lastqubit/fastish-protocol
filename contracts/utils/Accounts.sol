// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Layout} from "./Layout.sol";
import {isFamily, toLocalBase, toUnspecifiedBase} from "./Utils.sol";

library Accounts {
    error InvalidAccount();

    uint24 constant Family = (uint24(Layout.Evm32) << 8) | uint24(Layout.Account);
    uint32 constant Admin = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Account) << 8) | uint32(Layout.Admin);
    uint32 constant User = (uint32(Layout.Evm32) << 16) | (uint32(Layout.Account) << 8) | uint32(Layout.User);
    uint32 constant Keccak = (uint32(Layout.Opaque32) << 16) | (uint32(Layout.Account) << 8) | uint32(Layout.Keccak);

    function prefix(bytes32 account) internal pure returns (uint32) {
        return uint32(uint(account) >> 224);
    }

    function isAdmin(bytes32 account) internal pure returns (bool) {
        return prefix(account) == Admin;
    }

    function isKeccak(bytes32 account) internal pure returns (bool) {
        return prefix(account) == Keccak;
    }

    function toAdmin(address addr) internal view returns (bytes32) {
        return bytes32(toLocalBase(Admin) | (uint(uint160(addr)) << 32));
    }

    function toUser(address addr) internal pure returns (bytes32) {
        return bytes32(toUnspecifiedBase(User) | (uint(uint160(addr)) << 32));
    }

    function toKeccak(bytes calldata raw) internal pure returns (bytes32) {
        return bytes32(toUnspecifiedBase(Keccak) | uint224(uint256(keccak256(raw))));
    }

    function matchesKeccak(bytes32 account, bytes calldata raw) internal pure returns (bool) {
        return account == toKeccak(raw);
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



