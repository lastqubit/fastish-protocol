// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Blocks, Cursor, Keys } from "../Blocks.sol";

using Blocks for Cursor;

abstract contract EachRoute {
    function eachRoute(Cursor memory route) internal virtual;

    function forEachRoute(bytes calldata blocks, uint i) internal returns (uint) {
        (Cursor memory routes, ) = Blocks.matchingFrom(blocks, i, Keys.Route);
        while (routes.i < routes.end) {
            eachRoute(routes.take());
        }
        return routes.cursor;
    }
}
