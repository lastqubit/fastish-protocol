// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { Writer } from "../Blocks.sol";
import { Keys } from "../blocks/Keys.sol";
import { Schemas } from "../blocks/Schema.sol";
import { Blocks, Block, Keys } from "../Blocks.sol";
import { Writers } from "../blocks/Writers.sol";

string constant NAME = "deposit";

using Blocks for Block;
using Writers for Writer;

// @dev Use `deposit` for externally sourced assets; use `debitAccountToBalance` for internal balance deductions.
abstract contract Deposit is CommandBase {
    uint internal immutable depositId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Amount, depositId, Channels.Setup, Channels.Balances);
    }

    /// @dev Override to receive externally sourced funds for `account`.
    /// Called once per AMOUNT block and followed by a matching BALANCE output.
    function deposit(
        bytes32 account,
        bytes32 asset,
        bytes32 meta,
        uint amount
    ) internal virtual;

    function deposit(
        CommandContext calldata c
    ) external payable onlyCommand(depositId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint q = 0;
        (Writer memory writer, uint cursor) = Writers.allocBalancesFrom(c.request, q, Keys.Amount);

        while (q < cursor) {
            Block memory ref = Blocks.from(c.request, q);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackAmount();
            deposit(account, asset, meta, amount);
            writer.appendBalance(asset, meta, amount);
            q = ref.cursor;
        }

        return writer.done();
    }
}
