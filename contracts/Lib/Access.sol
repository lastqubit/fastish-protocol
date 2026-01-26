// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {addrOr, toAccountId} from "./Utils.sol";

abstract contract AccessControl {
    address internal immutable cmdr;
    uint internal immutable admin;

    mapping(address => bool) internal authorized;

    error Unauthorized(address addr);

    constructor(address commander) {
        cmdr = addrOr(commander, address(this));
        admin = toAccountId(cmdr);
    }

    modifier onlyTrusted() {
        ensureTrusted(msg.sender);
        _;
    }

    modifier onlyAuthorized() {
        ensureAuthorized(msg.sender);
        _;
    }

    modifier onlyAdmin(uint account) {
        ensureAdmin(msg.sender, account);
        _;
    }

    function auth(address addr, bool allow) private pure returns (address) {
        if (allow == false) {
            revert Unauthorized(addr);
        }
        return addr;
    }

    function isTrusted(address addr) internal view virtual returns (bool) {
        if (addr == address(0)) return false;
        return addr == cmdr || addr == address(this) || authorized[addr];
    }

    function ensureTrusted(address addr) internal view returns (address) {
        return auth(addr, isTrusted(addr));
    }

    function ensureAuthorized(address addr) internal view returns (address) {
        return auth(addr, addr != address(0) && authorized[addr]);
    }

    function ensureAdmin(address addr, uint account) internal view returns (address) {
        return auth(addr, addr == cmdr && account == admin);
    }
}
