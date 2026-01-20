// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

library Addr {
    error ZeroAddr();
    error BadAddr(address addr);

    function zero(address addr) internal pure returns (bool) {
        return addr == address(0);
    }

    function valid(address addr) internal pure returns (bool) {
        return !zero(addr);
    }

    function or(address addr, address b) internal pure returns (address) {
        return addr == address(0) ? b : addr;
    }

    function ensure(address addr) internal pure returns (address) {
        if (addr == address(0)) {
            revert ZeroAddr();
        }
        return addr;
    }

    function ensure(address addr, address eq) internal pure returns (address) {
        if (addr != eq) {
            revert BadAddr(addr);
        }
        return addr;
    }

    function toUint(address addr) internal pure returns (uint) {
        return uint(uint160(addr));
    }

    function extract(uint value) internal pure returns (address) {
        return address(uint160(value));
    }

    function extract(bytes32 value) internal pure returns (address) {
        return address(uint160(uint(value)));
    }

    function extract(bytes memory data) internal pure returns (address) {
        return abi.decode(data, (address));
    }
}
