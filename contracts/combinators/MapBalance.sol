// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {AssetAmount, BALANCE_KEY, ROUTE_KEY} from "../Schema.sol";
import {Blocks, BlockRef, Data, DataRef, Writers, Writer} from "../Blocks.sol";

using Blocks for BlockRef;
using Data for DataRef;
using Writers for Writer;

abstract contract MapBalance {
    function mapBalance(bytes32 account, AssetAmount memory balance) internal virtual returns (AssetAmount memory out);

    function mapBalances(bytes calldata state, uint i, bytes32 account) internal returns (bytes memory) {
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(state, i, BALANCE_KEY);

        while (i < end) {
            BlockRef memory ref = Blocks.balanceFrom(state, i);
            AssetAmount memory balance = ref.toBalanceValue(state);
            AssetAmount memory out = mapBalance(account, balance);
            if (out.amount > 0) writer.appendBalance(out);
            i = ref.end;
        }

        return writer.finish();
    }
}

abstract contract MapBalanceWithRequestRoute {
    function mapBalanceWithRequestRoute(
        bytes32 account,
        AssetAmount memory balance,
        DataRef memory rawRoute
    ) internal virtual returns (AssetAmount memory out);

    function mapBalancesWithRequestRoutes(
        bytes calldata state,
        bytes calldata request,
        uint i,
        uint q,
        bytes32 account
    ) internal returns (bytes memory) {
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(state, i, BALANCE_KEY);

        while (i < end) {
            DataRef memory route;
            (route, q) = Data.routeFrom(request, q);
            BlockRef memory ref = Blocks.balanceFrom(state, i);
            AssetAmount memory balance = ref.toBalanceValue(state);
            AssetAmount memory out = mapBalanceWithRequestRoute(account, balance, route);
            if (out.amount > 0) writer.appendBalance(out);
            i = ref.end;
        }

        return writer.finish();
    }
}

abstract contract SplitBalanceWithRequestRoute {
    function splitBalanceWithRequestRoute(
        bytes32 account,
        DataRef memory rawBalance,
        DataRef memory rawRoute
    ) internal virtual returns (AssetAmount memory a, AssetAmount memory b);

    function splitBalancesWithRequestRoutes(
        bytes calldata state,
        bytes calldata request,
        uint i,
        uint q,
        bytes32 account
    ) internal returns (bytes memory) {
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(state, i, BALANCE_KEY);

        while (i < end) {
            DataRef memory balance;
            DataRef memory route;
            (balance, i) = Data.balanceFrom(state, i);
            (route, q) = Data.routeFrom(request, q);
            (AssetAmount memory a, AssetAmount memory b) = splitBalanceWithRequestRoute(account, balance, route);
            if (a.amount > 0) writer.appendBalance(a);
            if (b.amount > 0) writer.appendBalance(b);
        }

        return writer.finish();
    }
}
