// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Cursors, Cursor, Writers, Writer } from "../Cursors.sol";
import { ALLOC_SCALE } from "../blocks/Writers.sol";

using Cursors for Cursor;
using Writers for Writer;

abstract contract InputToBalance {
    function inputToBalance(
        bytes32 account,
        Cursor memory input
    ) internal virtual returns (bytes32 asset, bytes32 meta, uint amount);

    function inputsToBalances(bytes calldata blocks, uint i, bytes32 account) internal returns (bytes memory) {
        (Cursor memory scan, uint count) = Cursors.openInput(blocks, i);
        Writer memory writer = Writers.allocScaledBalances(count, ALLOC_SCALE);

        while (scan.i < scan.end) {
            Cursor memory input = scan.take();
            (bytes32 asset, bytes32 meta, uint amount) = inputToBalance(account, input);
            if (amount > 0) writer.appendBalance(asset, meta, amount);
        }

        return writer.finish();
    }
}



