// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

library Head {
    uint8 internal constant NODE = 8;
    uint8 internal constant ID = 1;
    uint8 internal constant CONTEXT = 2; // Tail
    uint8 internal constant STEP = 3;
    uint8 internal constant FACTOR = 4;
    uint8 internal constant SIGNED = 5;
    uint8 internal constant PACKET = 6;
    uint8 internal constant ENDPOINT = 7; // lower

    error BadHead(uint word);

    function chainId() internal view returns (uint32) {
        if (block.chainid > type(uint32).max) {
            revert();
        }
        return uint32(block.chainid);
    }

    function ensure(uint head, uint value) internal pure returns (uint) {
        if (head != value) {
            revert BadHead(head);
        }
        return head;
    }

    // Use this insted of Id.host
/*     function node(address addr) internal view returns (uint) {
        uint n = uint(uint160(addr));
        n |= uint(chainId()) << 160;
        n |= uint(NODE) << 248;
        return n;
    }

    function endpoint(
        uint32 selector,
        address addr
    ) internal view returns (uint) {
        uint n = uint(uint160(addr));
        n |= uint(chainId()) << 160;
        n |= uint(selector) << 216;
        n |= uint(ENDPOINT) << 248;
        return n;
    } */

/*     function context(
        uint8 steps,
        uint32 reqOffset,
        uint32 chunkOffset
    ) internal pure returns (uint) {
        uint h = uint(reqOffset);
        h |= uint(chunkOffset) << 32;
        h |= uint(steps) << 240;
        h |= uint(CONTEXT) << 248;
        return h;
    } */

    function request(uint head, bytes4 selector) internal pure returns (uint) {
        head |= uint(uint32(selector)) << 216;
        head |= uint(STEP) << 248;
        return head;
    }

    function chunk(uint head, bytes4 selector) internal pure returns (uint) {
        head |= uint(uint32(selector)) << 216;
        head |= uint(FACTOR) << 248;
        return head;
    }

    function build(uint8 v, uint88 m, uint160 b) private pure returns (uint) {
        uint e = uint(b);
        e |= uint(m) << 160;
        e |= uint(v) << 248;
        return e;
    }

    function src(uint8 cat, uint56 c, uint24 s) private pure returns (uint88) {
        uint88 m = uint88(s);
        m |= uint88(c) << 24;
        m |= uint88(cat) << 80;
        return m;
    }

    /*     function ensure(uint head, uint8 ver) internal pure returns (uint) {
        if (ver != uint8(head >> 248)) {
            revert BadHeader(head);
        }
        return head;
    } */

    function patch(uint head, uint8 ver) internal pure returns (uint) {
        return head |= uint(ver) << 248; // works ??
    }

    function version(uint head) internal pure returns (uint8) {
        return uint8(head >> 248);
    }

    function meta(uint head) internal pure returns (uint88) {
        return uint88(head >> 160);
    }

    function body(uint head) internal pure returns (uint160) {
        return uint160(head);
    }

    /*     function call(uint88 value, address addr) internal pure returns (uint) {
        return build(CALL, value, uint160(addr));
    } */

    /*     function admin(uint nodeId) internal pure returns (uint) {
        return patch(nodeId, ADMIN);
    } */

    /*     function request(uint nodeId) internal pure returns (uint) {
        return patch(nodeId, STEP);
    } */

/*     function context(uint nodeId) internal pure returns (uint) {
        return patch(nodeId, CONTEXT);
    } */

    /*     function input(uint88 cat) internal pure returns (uint) {
        return build(INPUT, cat, 0);
    } */

    // entire uint head can be used as ref
    function packet(uint24 lid, uint160 num) internal view returns (uint) {
        return build(PACKET, src(0, chainId(), lid), num);
    }

    /*     function id(
        uint8 cat,
        uint24 lid,
        address addr
    ) internal view returns (uint) {
        return build(ID, src(cat, Block.chainId(), lid), uint160(addr));
    } */

    function get(bytes calldata data) internal pure returns (uint) {
        return data.length == 0 ? 0 : abi.decode(data, (uint));
    }
}
