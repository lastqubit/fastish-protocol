// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { AssetAmount, Cursors, Cursor, Writers, Writer, Keys } from "../Cursors.sol";

using Cursors for Cursor;
using Writers for Writer;

abstract contract AmountToBalance {
    function amountToBalance(bytes32 account, AssetAmount memory amount) internal virtual returns (AssetAmount memory);

    function amountsToBalances(bytes calldata blocks, uint i, bytes32 account) internal returns (bytes memory) {
        (Cursor memory scan, uint count) = Cursors.openTyped(blocks, i, Keys.Amount);
        Writer memory writer = Writers.allocBalances(count);

        while (scan.i < scan.end) {
            AssetAmount memory amount = scan.unpackAmountValue();
            AssetAmount memory out = amountToBalance(account, amount);
            writer.appendNonZeroBalance(out);
        }

        return writer.finish();
    }
}


