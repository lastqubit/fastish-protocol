// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandBase} from "../commands/Base.sol";
import {AMOUNT_KEY, AssetAmount, BlockRef, DataRef, ROUTE_KEY, Writer} from "../blocks/Schema.sol";
import {Blocks, Data} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";

using Blocks for BlockRef;
using Data for DataRef;
using Writers for Writer;

abstract contract AmountToBalance is CommandBase {
    function amountToBalance(
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) internal virtual returns (AssetAmount memory);

    function amountsToBalances(bytes calldata blocks, uint i, bytes32 account) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(blocks, i, AMOUNT_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.amountFrom(blocks, i);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackAmount(blocks);
            AssetAmount memory value = amountToBalance(account, asset, meta, amount);
            writer.appendBalance(value);
            i = ref.end;
        }

        return writer.done();
    }
}

// Route-aware amount transforms read one child route per amount block, e.g. `AMOUNT > ROUTE`.
abstract contract AmountWithChildRouteToBalance is CommandBase {
    function amountWithChildRouteToBalance(
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount,
        DataRef memory rawRoute
    ) internal virtual returns (AssetAmount memory);

    function amountsWithChildRoutesToBalances(
        bytes calldata blocks,
        uint i,
        bytes32 account
    ) internal returns (bytes memory) {
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(blocks, i, AMOUNT_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.amountFrom(blocks, i);
            DataRef memory route = Data.findFrom(blocks, ref.bound, ref.end, ROUTE_KEY);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackAmount(blocks);
            AssetAmount memory out = amountWithChildRouteToBalance(account, asset, meta, amount, route);
            writer.appendBalance(out);
            i = ref.end;
        }

        return writer.done();
    }
}
