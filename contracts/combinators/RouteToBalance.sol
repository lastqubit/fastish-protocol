// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandBase} from "../commands/Base.sol";
import {AssetAmount, DataRef, ROUTE_KEY, Writer} from "../blocks/Schema.sol";
import {Data} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";

using Writers for Writer;

abstract contract RouteToBalance is CommandBase {
    function routeToBalance(
        bytes32 account,
        DataRef memory rawRoute
    ) internal virtual returns (AssetAmount memory value);

    function routesToBalances(bytes calldata blocks, uint i, bytes32 account) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(blocks, i, ROUTE_KEY);

        while (i < next) {
            DataRef memory ref;
            (ref, i) = Data.routeFrom(blocks, i);
            AssetAmount memory value = routeToBalance(account, ref);
            writer.appendBalance(value);
        }

        return writer.done();
    }
}
