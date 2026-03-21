// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES, CUSTODIES} from "./Base.sol";
import {BALANCE_KEY, CUSTODY_KEY, ROUTE_EMPTY, MINIMUM, DataPairRef} from "../blocks/Schema.sol";
import {Data, DataRef, Writers, Writer} from "../Blocks.sol";

using Data for DataRef;
using Writers for Writer;

string constant ALFCTB = "addLiquidityFromCustodiesToBalances";
string constant ALFBTB = "addLiquidityFromBalancesToBalances";
string constant RLFCTB = "removeLiquidityFromCustodyToBalances";
string constant RLFBTB = "removeLiquidityFromBalanceToBalances";

abstract contract AddLiquidityFromCustodiesToBalances is CommandBase {
    uint internal immutable addLiquidityFromCustodiesToBalancesId = commandId(ALFCTB);

    constructor(string memory maybeRoute) {
        string memory schema = string.concat(bytes(maybeRoute).length == 0 ? ROUTE_EMPTY : maybeRoute, ">", MINIMUM);
        emit Command(host, ALFCTB, schema, addLiquidityFromCustodiesToBalancesId, CUSTODIES, BALANCES);
    }

    // @dev implementation extracts the requested minimum liquidity output from rawRoute.innerMinimum()
    // and may append up to three balances per custody pair: two refunds plus the liquidity receipt.
    function addLiquidityFromCustodiesToBalances(
        Writer memory out,
        bytes32 account,
        DataPairRef memory rawCustodies,
        DataRef memory rawRoute
    ) internal virtual;

    function addLiquidityFromCustodiesToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(addLiquidityFromCustodiesToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, CUSTODY_KEY, 15_000);

        while (i < end) {
            DataRef memory route;
            (route, q) = Data.routeFrom(c.request, q);
            (DataPairRef memory custodies, uint next) = Data.twoFrom(c.state, i);
            addLiquidityFromCustodiesToBalances(writer, c.account, custodies, route);
            i = next;
        }

        return writer.finish();
    }
}

abstract contract RemoveLiquidityFromCustodyToBalances is CommandBase {
    uint internal immutable removeLiquidityFromCustodyToBalancesId = commandId(RLFCTB);

    constructor(string memory maybeRoute) {
        string memory schema = string.concat(bytes(maybeRoute).length == 0 ? ROUTE_EMPTY : maybeRoute, ">", MINIMUM, ">", MINIMUM);
        emit Command(host, RLFCTB, schema, removeLiquidityFromCustodyToBalancesId, CUSTODIES, BALANCES);
    }

    // @dev implementation extracts requested minimum outputs from rawRoute and
    // may append up to two balances per custody input when removing liquidity.
    function removeLiquidityFromCustodyToBalances(
        Writer memory out,
        bytes32 account,
        DataRef memory rawCustody,
        DataRef memory rawRoute
    ) internal virtual;

    function removeLiquidityFromCustodyToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(removeLiquidityFromCustodyToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, CUSTODY_KEY, 20_000);

        while (i < end) {
            DataRef memory route;
            (route, q) = Data.routeFrom(c.request, q);
            (DataRef memory custody, uint next) = Data.from(c.state, i);
            removeLiquidityFromCustodyToBalances(writer, c.account, custody, route);
            i = next;
        }

        return writer.finish();
    }
}

abstract contract AddLiquidityFromBalancesToBalances is CommandBase {
    uint internal immutable addLiquidityFromBalancesToBalancesId = commandId(ALFBTB);

    constructor(string memory maybeRoute) {
        string memory schema = string.concat(bytes(maybeRoute).length == 0 ? ROUTE_EMPTY : maybeRoute, ">", MINIMUM);
        emit Command(host, ALFBTB, schema, addLiquidityFromBalancesToBalancesId, BALANCES, BALANCES);
    }

    // @dev implementation extracts the requested minimum liquidity output from rawRoute.innerMinimum()
    // and may append up to three balances per balance pair: two refunds plus the liquidity receipt.
    function addLiquidityFromBalancesToBalances(
        Writer memory out,
        bytes32 account,
        DataPairRef memory rawBalances,
        DataRef memory rawRoute
    ) internal virtual;

    function addLiquidityFromBalancesToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(addLiquidityFromBalancesToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, BALANCE_KEY, 15_000);

        while (i < end) {
            DataRef memory route;
            (route, q) = Data.routeFrom(c.request, q);
            (DataPairRef memory balances, uint next) = Data.twoFrom(c.state, i);
            addLiquidityFromBalancesToBalances(writer, c.account, balances, route);
            i = next;
        }

        return writer.finish();
    }
}

abstract contract RemoveLiquidityFromBalanceToBalances is CommandBase {
    uint internal immutable removeLiquidityFromBalanceToBalancesId = commandId(RLFBTB);

    constructor(string memory maybeRoute) {
        string memory schema = string.concat(bytes(maybeRoute).length == 0 ? ROUTE_EMPTY : maybeRoute, ">", MINIMUM, ">", MINIMUM);
        emit Command(host, RLFBTB, schema, removeLiquidityFromBalanceToBalancesId, BALANCES, BALANCES);
    }

    // @dev implementation extracts requested minimum outputs from rawRoute and
    // may append up to two balances per balance input when removing liquidity.
    function removeLiquidityFromBalanceToBalances(
        Writer memory out,
        bytes32 account,
        DataRef memory rawBalance,
        DataRef memory rawRoute
    ) internal virtual;

    function removeLiquidityFromBalanceToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(removeLiquidityFromBalanceToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, BALANCE_KEY, 20_000);

        while (i < end) {
            DataRef memory route;
            (route, q) = Data.routeFrom(c.request, q);
            (DataRef memory balance, uint next) = Data.from(c.state, i);
            removeLiquidityFromBalanceToBalances(writer, c.account, balance, route);
            i = next;
        }

        return writer.finish();
    }
}
