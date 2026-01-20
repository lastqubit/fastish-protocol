// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

// @dev bytes4(EVM=1,ID=1,TYPE,SUB)

// Change node to host ???

library Id {
    uint32 internal constant VALUE = uint32(bytes4(0x01010100));
    uint32 internal constant ACCOUNT = uint32(bytes4(0x01010200));
    uint32 internal constant NODE = uint32(bytes4(0x01010300));
    uint32 internal constant ENDPOINT = uint32(bytes4(0x01010400));
    uint32 internal constant ASSET = uint32(bytes4(0x01010500));

    uint32 internal constant TOKEN = ASSET | 1;

    error ZeroId();
    error BadId(uint id);

    function build(
        address addr,
        uint32 selector,
        uint32 chain,
        uint32 desc
    ) private pure returns (uint) {
        uint id = uint(uint160(addr));
        id |= uint(selector) << 160;
        id |= uint(chain) << 192;
        id |= uint(desc << 224);
        return id;
    }

    function chainId() internal view returns (uint32) {
        if (block.chainid > type(uint32).max) {
            revert();
        }
        return uint32(block.chainid);
    }

    function value() internal view returns (uint) {
        return build(address(0), 0, chainId(), VALUE);
    }

    function token(address addr) internal view returns (uint) {
        return build(addr, 0, chainId(), TOKEN);
    }

    function account(address addr) internal view returns (uint) {
        return build(addr, 0, chainId(), ACCOUNT);
    }

    function node(address addr) internal view returns (uint) {
        return build(addr, 0, chainId(), NODE);
    }

    // add open ??
    function endpoint(
        address addr,
        bytes4 selector
    ) internal view returns (uint) {
        return build(addr, uint32(selector), chainId(), ENDPOINT);
    }

    function ensure(uint id) internal pure returns (uint) {
        if (id == 0) {
            revert ZeroId();
        }
        return id;
    }

    // MUST BE LOCAL
    // (a >> 160) == (b >> 160);
    function accountAddr(uint id) internal pure returns (address) {
        return address(uint160(id));
    }

    function localAccount(uint id) internal pure returns (address) {
        return address(uint160(id));
    }

    function localNode(uint id) internal pure returns (address) {
        return address(uint160(id));
    }

    ////////////
    function localAddr(uint id) internal pure returns (address) {
        address addr = address(uint160(id));
        /*         if (addr != create(addr)) {
            revert(); ////
        } */
        return addr;
    }
}
