// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, HostAmount } from "../blocks/Schema.sol";
import { Keys } from "../blocks/Keys.sol";
import { Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";
using Blocks for Block;
using Writers for Writer;

string constant SEBTB = "swapExactBalanceToBalance";
string constant SECTB = "swapExactCustodyToBalance";

abstract contract SwapExactBalanceToBalance is CommandBase {
    uint internal immutable swapExactBalanceToBalanceId = commandId(SEBTB);

    constructor(string memory input) {
        emit Command(host, SEBTB, input, swapExactBalanceToBalanceId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to swap an exact balance input into a balance output.
    /// Implementations validate and unpack `rawInput` as needed.
    function swapExactBalanceToBalance(
        bytes32 account,
        AssetAmount memory balance,
        Block memory rawInput
    ) internal virtual returns (AssetAmount memory out);

    function swapExactBalanceToBalance(
        CommandContext calldata c
    ) external payable onlyCommand(swapExactBalanceToBalanceId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(c.state, i, Keys.Balance);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            AssetAmount memory balance = ref.toBalanceValue();
            AssetAmount memory out = swapExactBalanceToBalance(c.account, balance, input);
            writer.appendNonZeroBalance(out);
            i = ref.cursor;
        }

        return writer.finish();
    }
}

abstract contract SwapExactCustodyToBalance is CommandBase {
    uint internal immutable swapExactCustodyToBalanceId = commandId(SECTB);

    constructor(string memory input) {
        emit Command(host, SECTB, input, swapExactCustodyToBalanceId, Channels.Custodies, Channels.Balances);
    }

    /// @dev Override to swap an exact custody input into a balance output.
    /// Implementations validate and unpack `rawInput` as needed.
    function swapExactCustodyToBalance(
        bytes32 account,
        HostAmount memory custody,
        Block memory rawInput
    ) internal virtual returns (AssetAmount memory out);

    function swapExactCustodyToBalance(
        CommandContext calldata c
    ) external payable onlyCommand(swapExactCustodyToBalanceId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocBalancesFrom(c.state, i, Keys.Custody);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            HostAmount memory custody = ref.toCustodyValue();
            AssetAmount memory out = swapExactCustodyToBalance(c.account, custody, input);
            writer.appendNonZeroBalance(out);
            i = ref.cursor;
        }

        return writer.finish();
    }
}
