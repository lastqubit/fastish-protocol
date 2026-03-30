// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, HostAmount, Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";

string constant BABTB = "borrowAgainstBalanceToBalance";
string constant BACTB = "borrowAgainstCustodyToBalance";

using Blocks for Block;
using Writers for Writer;

abstract contract BorrowAgainstCustodyToBalance is CommandBase {
    uint internal immutable borrowAgainstCustodyToBalanceId = commandId(BACTB);

    constructor(string memory input) {
        emit Command(host, BACTB, input, borrowAgainstCustodyToBalanceId, Channels.Custodies, Channels.Balances);
    }

    /// @dev Override to borrow against a custody position.
    /// Implementations validate and unpack `rawInput` as needed.
    function borrowAgainstCustodyToBalance(
        bytes32 account,
        HostAmount memory custody,
        Block memory rawInput
    ) internal virtual returns (AssetAmount memory);

    function borrowAgainstCustodyToBalance(
        CommandContext calldata c
    ) external payable onlyCommand(borrowAgainstCustodyToBalanceId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(c.state, i, Keys.Custody);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            HostAmount memory custody = ref.toCustodyValue();
            AssetAmount memory out = borrowAgainstCustodyToBalance(c.account, custody, input);
            writer.appendNonZeroBalance(out);
            i = ref.cursor;
        }

        return writer.finish();
    }
}

abstract contract BorrowAgainstBalanceToBalance is CommandBase {
    uint internal immutable borrowAgainstBalanceToBalanceId = commandId(BABTB);

    constructor(string memory input) {
        emit Command(host, BABTB, input, borrowAgainstBalanceToBalanceId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to borrow against a balance position.
    /// Implementations validate and unpack `rawInput` as needed.
    function borrowAgainstBalanceToBalance(
        bytes32 account,
        AssetAmount memory balance,
        Block memory rawInput
    ) internal virtual returns (AssetAmount memory);

    function borrowAgainstBalanceToBalance(
        CommandContext calldata c
    ) external payable onlyCommand(borrowAgainstBalanceToBalanceId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(c.state, i, Keys.Balance);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            AssetAmount memory balance = ref.toBalanceValue();
            AssetAmount memory out = borrowAgainstBalanceToBalance(c.account, balance, input);
            writer.appendNonZeroBalance(out);
            i = ref.cursor;
        }

        return writer.finish();
    }
}
