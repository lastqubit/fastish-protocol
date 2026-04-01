// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, HostAmount, Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";

string constant RFBTB = "repayFromBalanceToBalances";
string constant RFCTB = "repayFromCustodyToBalances";

using Blocks for Block;
using Writers for Writer;

abstract contract RepayFromBalanceToBalances is CommandBase {
    uint internal immutable repayFromBalanceToBalancesId = commandId(RFBTB);
    uint private immutable outScale;
    bool private immutable useInput;

    constructor(string memory maybeInput, uint scaledRatio) {
        outScale = scaledRatio;
        useInput = bytes(maybeInput).length > 0;
        emit Command(host, RFBTB, maybeInput, repayFromBalanceToBalancesId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to repay debt using a balance amount.
    /// `rawInput` is zero-initialized and should be ignored when
    /// `maybeInput` is empty. Implementations validate and unpack it as
    /// needed, and may append returned balances to `out`.
    function repayFromBalanceToBalances(
        bytes32 account,
        AssetAmount memory balance,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function repayFromBalanceToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(repayFromBalanceToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Balance, outScale);

        while (i < end) {
            Block memory input;
            if (useInput) {
                input = Blocks.from(c.request, q);
                q = input.cursor;
            }
            Block memory ref = Blocks.from(c.state, i);
            AssetAmount memory balance = ref.toBalanceValue();
            repayFromBalanceToBalances(c.account, balance, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}

abstract contract RepayFromCustodyToBalances is CommandBase {
    uint internal immutable repayFromCustodyToBalancesId = commandId(RFCTB);
    uint private immutable outScale;
    bool private immutable useInput;

    constructor(string memory maybeInput, uint scaledRatio) {
        outScale = scaledRatio;
        useInput = bytes(maybeInput).length > 0;
        emit Command(host, RFCTB, maybeInput, repayFromCustodyToBalancesId, Channels.Custodies, Channels.Balances);
    }

    /// @dev Override to repay debt using a custody amount.
    /// `rawInput` is zero-initialized and should be ignored when
    /// `maybeInput` is empty. Implementations validate and unpack it as
    /// needed, and may append returned balances to `out`.
    function repayFromCustodyToBalances(
        bytes32 account,
        HostAmount memory custody,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function repayFromCustodyToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(repayFromCustodyToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Custody, outScale);

        while (i < end) {
            Block memory input;
            if (useInput) {
                input = Blocks.from(c.request, q);
                q = input.cursor;
            }
            Block memory ref = Blocks.from(c.state, i);
            HostAmount memory custody = ref.toCustodyValue();
            repayFromCustodyToBalances(c.account, custody, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}
