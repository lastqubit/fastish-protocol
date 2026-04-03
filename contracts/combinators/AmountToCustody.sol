// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { HostAmount, Blocks, Cursor, Writers, Writer, Keys } from "../Blocks.sol";

using Blocks for Cursor;
using Writers for Writer;

abstract contract AmountToCustody {
    function amountToCustody(
        uint host,
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) internal virtual returns (HostAmount memory);

    function amountsToCustodies(
        bytes calldata blocks,
        uint i,
        uint host,
        bytes32 account
    ) internal returns (bytes memory) {
        (Cursor memory scan, uint count) = Blocks.matchingFrom(blocks, i, Keys.Amount);
        Writer memory writer = Writers.allocCustodies(count);

        while (scan.i < scan.end) {
            (bytes32 asset, bytes32 meta, uint amount) = scan.unpackAmount();
            HostAmount memory out = amountToCustody(host, account, asset, meta, amount);
            if (out.amount > 0) writer.appendCustody(out);
        }

        return writer.finish();
    }
}
