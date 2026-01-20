// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Head} from "./Head.sol";

library Id {
    uint internal constant VALUE = uint8(1);
    uint internal constant NODE = uint8(3);
    uint internal constant ENDPOINT = uint8(7);
    uint internal constant ASSET = uint8(8);

    uint internal constant ADDR20 = uint8(2);

    /*     uint8 internal constant NODE = 8;
    uint8 internal constant ID = 1; */

    error ZeroId();
    error BadId(uint id);

    /////////// 208
    function build(
        address addr,
        uint32 chain,
        uint32 selector,
        uint sub,
        uint main
    ) private pure returns (uint) {
        uint id = uint(uint160(addr));
        id |= uint(chain) << 160;
        id |= uint(selector) << 192;
        id |= (sub << 240);
        id |= (main << 248);
        return id;
    }

    function chainId() internal view returns (uint32) {
        if (block.chainid > type(uint32).max) {
            revert();
        }
        return uint32(block.chainid);
    }

    function node(address addr) internal view returns (uint) {
        uint n = uint(uint160(addr));
        n |= uint(chainId()) << 160;
        n |= uint(NODE) << 248;
        return n;
    }

    function endpoint(
        bool open,
        bytes4 selector,
        address addr
    ) internal view returns (uint) {
        return build(addr, chainId(), uint32(selector), 0, ENDPOINT);
    }

    function asset() internal returns (uint) {}

    // Add EVM field ??
    function build(
        address addr,
        uint chain,
        uint format
    ) private pure returns (uint) {
        uint id = uint(uint160(addr));
        id |= chain << 160;
        id |= format << 240;
        id |= uint(Head.ID) << 248;
        return id;
    }

    function create(address addr) internal view returns (uint) {
        return build(addr, chainId(), ADDR20);
    }

    function value() internal view returns (uint) {
        return build(address(0), chainId(), VALUE);
    }

    ////
    /*     function node(address addr) internal view returns (uint) {
        return build(addr, chainId(), NODE);
    } */

    function ensure(uint id) internal pure returns (uint) {
        if (id == 0) {
            revert ZeroId();
        }
        return id;
    }

    function ensure(uint id, address addr) internal pure returns (uint) {
        if (localAddr(id) != addr) {
            revert BadId(id);
        }
        return id;
    }

    ////////////
    function localAddr(uint id) internal pure returns (address) {
        address addr = address(uint160(id));
        /*         if (addr != create(addr)) {
            revert(); ////
        } */
        return addr;
    }

    /*     
    function local(uint id) internal pure returns (uint24) {
        return uint24(evm(id) >> 160);
    } */

    // function ref() body == counter ++
}
