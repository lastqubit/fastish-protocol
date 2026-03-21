// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "../core/Host.sol";
import {
    AddLiquidityFromCustodiesToBalances,
    RemoveLiquidityFromCustodyToBalances,
    AddLiquidityFromBalancesToBalances,
    RemoveLiquidityFromBalanceToBalances
} from "../commands/Liquidity.sol";
import {Data} from "../blocks/Data.sol";
import {AssetAmount, DataPairRef, DataRef, HostAmount, Writer} from "../blocks/Schema.sol";
import {Writers} from "../blocks/Writers.sol";
import {toHostId} from "../utils/Ids.sol";

using Data for DataRef;
using Writers for Writer;

contract TestLiquidityHost is
    Host,
    AddLiquidityFromCustodiesToBalances,
    RemoveLiquidityFromCustodyToBalances,
    AddLiquidityFromBalancesToBalances,
    RemoveLiquidityFromBalanceToBalances
{
    bytes32 internal constant LP_FROM_CUSTODIES_ASSET = bytes32(uint(0xaaa1));
    bytes32 internal constant LP_FROM_BALANCES_ASSET = bytes32(uint(0xaaa2));
    bytes32 internal constant REDEEM_FROM_CUSTODY_ASSET = bytes32(uint(0xbbb1));
    bytes32 internal constant REDEEM_FROM_BALANCE_ASSET = bytes32(uint(0xbbb2));

    event AddCustodiesMapped(
        bytes32 account,
        bytes32 assetA,
        uint amountA,
        bytes32 assetB,
        uint amountB,
        bytes routeData
    );
    event RemoveCustodyMapped(bytes32 account, bytes32 asset, uint amount, bytes routeData);
    event AddBalancesMapped(
        bytes32 account,
        bytes32 assetA,
        uint amountA,
        bytes32 assetB,
        uint amountB,
        bytes routeData
    );
    event RemoveBalanceMapped(bytes32 account, bytes32 asset, uint amount, bytes routeData);
    event MinimumObserved(bytes32 asset, bytes32 meta, uint amount);

    constructor(address cmdr)
        Host(address(0), 1, "test")
        AddLiquidityFromCustodiesToBalances("route(bytes data)")
        RemoveLiquidityFromCustodyToBalances("route(bytes data)")
        AddLiquidityFromBalancesToBalances("route(bytes data)")
        RemoveLiquidityFromBalanceToBalances("route(bytes data)")
    {
        if (cmdr != address(0)) access(toHostId(cmdr), true);
    }

    function addLiquidityFromCustodiesToBalances(
        Writer memory out,
        bytes32 account,
        DataPairRef memory rawCustodies,
        DataRef memory rawRoute
    ) internal override {
        HostAmount memory a = rawCustodies.a.toCustodyValue();
        HostAmount memory b = rawCustodies.b.toCustodyValue();
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        uint routeLen = rawRoute.bound - rawRoute.i;
        emit AddCustodiesMapped(account, a.asset, a.amount, b.asset, b.amount, routeData);
        emitMinimum(rawRoute);

        out.appendBalance(a.asset, a.meta, a.amount + routeLen);
        out.appendBalance(b.asset, b.meta, b.amount + routeLen + 1);
        out.appendBalance(LP_FROM_CUSTODIES_ASSET, bytes32(routeLen), a.amount + b.amount);
    }

    function removeLiquidityFromCustodyToBalances(
        Writer memory out,
        bytes32 account,
        DataRef memory rawCustody,
        DataRef memory rawRoute
    ) internal override {
        HostAmount memory custody = rawCustody.toCustodyValue();
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        uint routeLen = rawRoute.bound - rawRoute.i;
        emit RemoveCustodyMapped(account, custody.asset, custody.amount, routeData);
        emitMinimum(rawRoute);

        out.appendBalance(custody.asset, custody.meta, custody.amount + routeLen);
        out.appendBalance(REDEEM_FROM_CUSTODY_ASSET, bytes32(routeLen), custody.amount + 10);
    }

    function addLiquidityFromBalancesToBalances(
        Writer memory out,
        bytes32 account,
        DataPairRef memory rawBalances,
        DataRef memory rawRoute
    ) internal override {
        AssetAmount memory a = rawBalances.a.toBalanceValue();
        AssetAmount memory b = rawBalances.b.toBalanceValue();
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        uint routeLen = rawRoute.bound - rawRoute.i;
        emit AddBalancesMapped(account, a.asset, a.amount, b.asset, b.amount, routeData);
        emitMinimum(rawRoute);

        out.appendBalance(a.asset, a.meta, a.amount + routeLen);
        out.appendBalance(b.asset, b.meta, b.amount + routeLen + 2);
        out.appendBalance(LP_FROM_BALANCES_ASSET, bytes32(routeLen), a.amount + b.amount);
    }

    function removeLiquidityFromBalanceToBalances(
        Writer memory out,
        bytes32 account,
        DataRef memory rawBalance,
        DataRef memory rawRoute
    ) internal override {
        AssetAmount memory balance = rawBalance.toBalanceValue();
        bytes calldata routeData = msg.data[rawRoute.i:rawRoute.bound];
        uint routeLen = rawRoute.bound - rawRoute.i;
        emit RemoveBalanceMapped(account, balance.asset, balance.amount, routeData);
        emitMinimum(rawRoute);

        out.appendBalance(balance.asset, balance.meta, balance.amount + routeLen);
        out.appendBalance(REDEEM_FROM_BALANCE_ASSET, bytes32(routeLen), balance.amount + 20);
    }

    function emitMinimum(DataRef memory rawRoute) internal {
        if (rawRoute.bound < rawRoute.end) {
            (bytes32 asset, bytes32 meta, uint amount) = rawRoute.innerMinimum();
            emit MinimumObserved(asset, meta, amount);
        }
    }

    function getAddLiquidityFromCustodiesToBalancesId() external view returns (uint) {
        return addLiquidityFromCustodiesToBalancesId;
    }

    function getRemoveLiquidityFromCustodyToBalancesId() external view returns (uint) {
        return removeLiquidityFromCustodyToBalancesId;
    }

    function getAddLiquidityFromBalancesToBalancesId() external view returns (uint) {
        return addLiquidityFromBalancesToBalancesId;
    }

    function getRemoveLiquidityFromBalanceToBalancesId() external view returns (uint) {
        return removeLiquidityFromBalanceToBalancesId;
    }
}
