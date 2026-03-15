// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES, SETUP} from "./Base.sol";
import {AMOUNT, AMOUNT_KEY, BlockRef, DataRef, ROUTE_KEY, Writer} from "../blocks/Schema.sol";
import {Blocks, Data} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "deposit";

using Blocks for BlockRef;
using Data for DataRef;
using Writers for Writer;

// @dev Use `deposit` for externally sourced assets; use `debitFrom` for internal balance deductions.
abstract contract Deposit is CommandBase {
    uint internal immutable depositId = toCommandId(NAME, address(this));

    constructor(string memory route) {
        string memory schema = bytes(route).length == 0 ? AMOUNT : string.concat(AMOUNT, ">", route);
        emit Command(host, NAME, schema, depositId, SETUP, BALANCES);
    }

    function deposit(
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount,
        DataRef memory rawRoute
    ) internal virtual;

    function deposit(
        CommandContext calldata c
    ) external payable onlyCommand(depositId, c.target) returns (bytes memory) {
        uint i = 0;
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(c.request, i, AMOUNT_KEY);
        DataRef memory rawRoute = Data.findFrom(c.request, next, c.request.length, ROUTE_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.amountFrom(c.request, i);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackAmount(c.request);
            deposit(c.account, asset, meta, amount, rawRoute);
            writer.appendBalance(asset, meta, amount);
            i = ref.end;
        }

        return writer.done();
    }
}
