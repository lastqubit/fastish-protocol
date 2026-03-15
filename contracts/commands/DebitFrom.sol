// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES, SETUP} from "./Base.sol";
import {AMOUNT, AMOUNT_KEY, BlockRef, Writer} from "../blocks/Schema.sol";
import {Blocks} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";
import {ensureBalanceRef} from "../utils/Assets.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "debitFrom";

using Blocks for BlockRef;
using Writers for Writer;

abstract contract DebitFrom is CommandBase {
    uint internal immutable debitFromId = toCommandId(NAME, address(this));

    constructor() {
        emit Command(host, NAME, AMOUNT, debitFromId, SETUP, BALANCES);
    }

    function debitFrom(bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual returns (uint);

    function debitFrom(bytes32 from, bytes calldata request) internal virtual returns (bytes memory) {
        uint i = 0;
        (Writer memory writer, uint next) = Writers.allocBalancesFrom(request, i, AMOUNT_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.from(request, i);
            if (!ref.isAmount()) break;
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackAmount(request);
            debitFrom(from, asset, meta, amount);
            writer.appendBalance(asset, meta, amount);
            i = ref.end;
        }

        return writer.done();
    }

    function debitFrom(
        CommandContext calldata c
    ) external payable onlyCommand(debitFromId, c.target) returns (bytes memory) {
        return debitFrom(c.account, c.request);
    }
}
