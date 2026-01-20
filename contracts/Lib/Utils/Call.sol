// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

// @dev head with any value(selector) as the last uint32 is expected to have a body encoded to work with these call functions.

struct Value {
    uint amount;
}

// Failed call endpoint instead of selector...
error FailedCall(bytes4 selector, address addr, uint size);

function toSelector(uint head) pure returns (bytes4) {
    bytes4 selector = bytes4(uint32(head));
    if (selector == 0) {
        revert();
    }
    return selector;
}

/* function _call(
    address payable addr,
    uint value,
    bytes memory data
) pure returns (bytes memory out) {
    bool success;
    (success, out) = addr.call{value: value}(data);
    if (!success) {
        revert FailedCall(bytes4(data), addr, data.length);
    }
    return out;
} */

// @dev expects last encoded value of body to be empty bytes array(placeholder for step).
function encodeCall(
    uint head,
    bytes memory body,
    bytes calldata step
) pure returns (bytes memory) {
    uint o = body.length + 4 - 32;
    bytes memory call = bytes.concat(toSelector(head), body, step);
    //call.store32no(step.length + 32, step.length);
}

/* function callNext(
    address addr,
    uint head,
    bytes memory body,
    bytes calldata step,
    Value memory total
) pure returns (bytes32, bytes memory) {
    uint v = uint96(bytes12(step[32:44]));
    bytes memory call = encodeCall(head, body, step);
    return abi.decode(callTo(addr, v, total, call), (uint, bytes));
} */
