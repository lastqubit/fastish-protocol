// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { HostAmount, Cursors, Cursor, Writers, Writer, Keys } from "../Cursors.sol";

using Cursors for Cursor;
using Writers for Writer;

abstract contract MapCustody {
    function mapCustody(bytes32 account, HostAmount memory custody) internal virtual returns (HostAmount memory out);

    function mapCustodies(bytes calldata state, uint i, bytes32 account) internal returns (bytes memory) {
        (Cursor memory scan, uint count) = Cursors.openRun(state, i, Keys.Custody);
        Writer memory writer = Writers.allocCustodies(count);

        while (scan.i < scan.end) {
            HostAmount memory custody = scan.unpackCustodyValue();
            HostAmount memory out = mapCustody(account, custody);
            if (out.amount > 0) writer.appendCustody(out);
        }

        return writer.finish();
    }
}




