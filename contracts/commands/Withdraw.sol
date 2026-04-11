// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, State } from "./Base.sol";
import { Cursors, Cur, Schemas } from "../Cursors.sol";
using Cursors for Cur;

string constant NAME = "withdraw";

// @dev Use `withdraw` for externally delivered assets; use `creditBalanceToAccount` for internal balance credits.
abstract contract Withdraw is CommandBase {
    uint internal immutable withdrawId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Recipient, withdrawId, State.Balances, State.Empty);
    }

    /// @dev Override to send funds to `account`.
    /// Called once per BALANCE block in state.
    function withdraw(bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual;

    function withdraw(
        CommandContext calldata c
    ) external payable onlyCommand(withdrawId, c.target) returns (bytes memory) {
        (Cur memory state, ) = cursor(c.state, 1);
        Cur memory request = cursor(c.request);
        bytes32 to = request.recipientAfter(c.account);

        while (state.i < state.bound) {
            (bytes32 asset, bytes32 meta, uint amount) = state.unpackBalance();
            withdraw(to, asset, meta, amount);
        }

        state.complete();
        return "";
    }
}





