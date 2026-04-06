// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { AssetAmount, HostAmount, Cursors, Cursor, Writers, Writer, Keys } from "../Cursors.sol";

using Cursors for Cursor;
using Writers for Writer;

abstract contract CustodyToBalance {
    function custodyToBalance(bytes32 account, HostAmount memory custody) internal virtual returns (AssetAmount memory);

    function custodiesToBalances(bytes calldata blocks, uint i, bytes32 account) internal returns (bytes memory) {
        (Cursor memory scan, uint count) = Cursors.openRun(blocks, i, Keys.Custody);
        Writer memory writer = Writers.allocBalances(count);

        while (scan.i < scan.end) {
            HostAmount memory custody = scan.unpackCustodyValue();
            AssetAmount memory out = custodyToBalance(account, custody);
            writer.appendNonZeroBalance(out);
        }

        return writer.finish();
    }
}




