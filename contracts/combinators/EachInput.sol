// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Blocks, Cursor } from "../Blocks.sol";

using Blocks for Cursor;

abstract contract EachInput {
    function eachInput(Cursor memory input) internal virtual;

    function forEachInput(bytes calldata blocks, uint i) internal returns (uint) {
        (Cursor memory inputs, ) = Blocks.allFrom(blocks, i);
        while (inputs.i < inputs.end) {
            Cursor memory input = inputs.take();
            eachInput(input);
        }
        return inputs.cursor;
    }
}
