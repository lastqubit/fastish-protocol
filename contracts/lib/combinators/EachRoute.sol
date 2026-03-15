// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {CommandBase} from "../commands/Base.sol";
import {DataRef, ROUTE_KEY} from "../blocks/Schema.sol";
import {Data} from "../blocks/Readers.sol";

// Iterates sibling route blocks until the first non-route block, e.g. `ROUTE; ROUTE; ROUTE`.
abstract contract EachRoute is CommandBase {
    function eachRoute(DataRef memory rawRoute) internal virtual;

    function forEachRoute(bytes calldata blocks, uint i) internal {
        while (i < blocks.length) {
            (DataRef memory ref, uint next) = Data.from(blocks, i);
            if (ref.key != ROUTE_KEY) break;
            eachRoute(ref);
            i = next;
        }
        // return next?
    }
}
