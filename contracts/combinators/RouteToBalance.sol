// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Cursors, Cursor, Writers, Writer, Keys} from "../Cursors.sol";

using Cursors for Cursor;
using Writers for Writer;

abstract contract RouteToBalance {
    function routeToBalance(
        bytes32 account,
        Cursor memory route
    ) internal virtual returns (bytes32 asset, bytes32 meta, uint amount);

    function routesToBalances(bytes calldata blocks, uint i, bytes32 account) internal returns (bytes memory) {
        (Cursor memory scan, uint count) = Cursors.openTyped(blocks, i, Keys.Route);
        Writer memory writer = Writers.allocBalances(count);

        while (scan.i < scan.end) {
            Cursor memory route = scan.take();
            (bytes32 asset, bytes32 meta, uint amount) = routeToBalance(account, route);
            if (amount > 0) writer.appendBalance(asset, meta, amount);
        }

        return writer.finish();
    }
}


