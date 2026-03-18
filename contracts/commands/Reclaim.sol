// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES, CUSTODIES} from "./Base.sol";
import {AssetAmount, HostAmount, CUSTODY_KEY, ROUTE_KEY} from "../Schema.sol";
import {Blocks, BlockRef, Writers, Writer} from "../Blocks.sol";
import {toCommandId} from "../utils/Ids.sol";

using Blocks for BlockRef;
using Writers for Writer;

bytes32 constant NAME = "reclaim";

abstract contract Reclaim is CommandBase {
    uint internal immutable reclaimId = toCommandId(NAME, address(this));

    constructor() {
        emit Command(host, NAME, "", reclaimId, CUSTODIES, BALANCES);
    }

    function reclaim(
        uint host,
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) internal virtual returns (AssetAmount memory);

    function reclaim(
        CommandContext calldata c
    ) external payable onlyCommand(reclaimId, c.target) returns (bytes memory) {
        uint i = 0;
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(c.state, i, CUSTODY_KEY);

        while (i < end) {
            BlockRef memory ref = Blocks.custodyFrom(c.state, i);
            HostAmount memory v = ref.toCustodyValue(c.state);
            AssetAmount memory out = reclaim(v.host, c.account, v.asset, v.meta, v.amount);
            if (out.amount > 0) writer.appendBalance(out);
            i = ref.end;
        }

        return writer.finish();
    }
}
