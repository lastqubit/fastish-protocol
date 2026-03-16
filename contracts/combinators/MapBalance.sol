// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandBase} from "../commands/Base.sol";
import {AssetAmount, BALANCE_KEY, BlockRef, DataRef, ROUTE_KEY, Writer} from "../blocks/Schema.sol";
import {Blocks, Data} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";

using Blocks for BlockRef;
using Data for DataRef;
using Writers for Writer;

abstract contract MapBalance is CommandBase {
    function mapBalance(
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) internal virtual returns (bool keep, AssetAmount memory out);

    function mapBalances(bytes calldata state, uint i, bytes32 account) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(state, i, BALANCE_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.balanceFrom(state, i);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackBalance(state);
            (bool keep, AssetAmount memory out) = mapBalance(account, asset, meta, amount);
            if (keep) writer.appendBalance(out);
            i = ref.end;
        }

        return writer.finish();
    }
}

abstract contract MapBalanceWithRequestRoute is CommandBase {
    function mapBalanceWithRequestRoute(
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount,
        DataRef memory rawRoute
    ) internal virtual returns (bool keep, AssetAmount memory out);

    function mapBalancesWithRequestRoutes(
        bytes calldata state,
        bytes calldata request,
        uint i,
        uint q,
        bytes32 account
    ) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(state, i, BALANCE_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.balanceFrom(state, i);
            DataRef memory rawRoute;
            (rawRoute, q) = Data.routeFrom(request, q);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackBalance(state);
            (bool keep, AssetAmount memory out) = mapBalanceWithRequestRoute(account, asset, meta, amount, rawRoute);
            if (keep) writer.appendBalance(out);
            i = ref.end;
        }

        return writer.finish();
    }
}
