// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { Cursors, Cursor, Keys, Schemas, Writer, Writers } from "../Cursors.sol";

string constant NAME = "deposit";

using Cursors for Cursor;
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
        (Cursor memory inputs, uint count) = Cursors.openRun(c.request, 0, Keys.Amount);
        Writer memory writer = Writers.allocBalances(count);

        while (inputs.i < inputs.end) {
            (bytes32 asset, bytes32 meta, uint amount) = inputs.unpackAmount();
            deposit(c.account, asset, meta, amount);
            writer.appendBalance(asset, meta, amount);
        }

        return writer.done();
    }
}




