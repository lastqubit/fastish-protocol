// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Bytes} from "./Bytes.sol";
import {Data} from "./Data.sol";

// @dev blocks describes byte arrays at the end of a parent byte array.
// @dev every blocks start with 4 bytes where 2 byte is the type of block and 2 bytes are the length of the block.

bytes4 constant BLOCKS = 0x00111100;
bytes2 constant STEP = 0x0100;
bytes2 constant FACTOR = 0x0200;

// block: length(2) cat(2) data() totalSize(2)
/* library Blocks {
    using Data for bytes;

    function to16(uint value) private pure returns (uint16) {}

    function length(uint value) private pure returns (uint16) {
        if (value > type(uint16).max) {
            revert();
        }
        return uint16(value);
    }

    function context(
        bytes memory blocks,
        address collector,
        uint fee
    ) internal returns (bytes memory) {}

    function context(bytes calldata step) internal pure returns (bytes memory) {
        bytes2 len = bytes2(uint16(step.length + 6));
        return bytes.concat(STEP, len, step, len);
    }

    function add(
        bytes memory to,
        bytes2 cat,
        bytes calldata data
    ) internal pure returns (bytes memory out) {
        uint16 len = length(data.length + 4);
        uint32 size = uint32(Bytes.last4(to)) + len + 8;
        bytes8 end = bytes8(uint64(size)); // add head
        out = bytes.concat(to, cat, bytes2(len), data, end); // cat bytes 2
        Bytes.store32no(out, size + 32, size);
        return out;
    }
}
 */