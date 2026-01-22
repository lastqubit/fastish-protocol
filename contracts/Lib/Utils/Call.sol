// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

// @dev head with any value(selector) as the last uint32 is expected to have a body encoded to work with these call functions.

struct Value {
    uint amount;
}

function encodeCall(bytes4 selector, uint account, bytes calldata step) pure returns (bytes memory c) {
    assembly {
        let s := step.length
        c := mload(0x40)

        mstore(0x40, add(c, and(add(add(0x84, s), 0x1f), not(0x1f))))

        mstore(c, add(0x64, s))

        // Store account first
        mstore(add(c, 0x24), account)

        // Write selector bytes
        let ptr := add(c, 0x20)
        mstore8(ptr, byte(0, selector))
        mstore8(add(ptr, 1), byte(1, selector))
        mstore8(add(ptr, 2), byte(2, selector))
        mstore8(add(ptr, 3), byte(3, selector))

        // Store offset
        mstore(add(c, 0x44), 0x40)

        // Copy step length AND data in one operation
        calldatacopy(add(c, 0x64), step.offset, add(s, 0x20))
    }
}
