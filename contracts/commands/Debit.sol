// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { Cursors, Cursor, Keys, Schemas, Writer, Writers } from "../Cursors.sol";

string constant NAME = "debitAccount";

using Cursors for Cursor;
using Writers for Writer;

abstract contract DebitAccount is CommandBase {
    uint internal immutable debitAccountId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Amount, debitAccountId, Channels.Setup, Channels.Balances);
    }

    /// @dev Override to debit externally managed funds from `account`.
    /// Called once per AMOUNT block before a matching BALANCE is emitted.
    function debitAccount(bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual;

    /// @dev Override to customize request parsing or batching for debits.
    /// The default implementation iterates AMOUNT blocks, calls
    /// `debitAccount`, and emits matching BALANCE blocks.
    function debitAccount(bytes32 account, bytes calldata request) internal virtual returns (bytes memory) {
        (Cursor memory inputs, uint count) = Cursors.openRun(request, 0, Keys.Amount);
        Writer memory writer = Writers.allocBalances(count);

        while (inputs.i < inputs.end) {
            (bytes32 asset, bytes32 meta, uint amount) = inputs.unpackAmount();
            debitAccount(account, asset, meta, amount);
            writer.appendBalance(asset, meta, amount);
        }

        return writer.done();
    }

    function debitAccount(
        CommandContext calldata c
    ) external payable onlyCommand(debitAccountId, c.target) returns (bytes memory) {
        return debitAccount(c.account, c.request);
    }
}




