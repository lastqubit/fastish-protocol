// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, HostAmount, Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";

string constant SBTB = "stakeBalanceToBalances";
string constant SCTB = "stakeCustodyToBalances";
string constant SCTP = "stakeCustodyToPosition";

using Blocks for Block;
using Writers for Writer;

abstract contract StakeBalanceToBalances is CommandBase {
    uint internal immutable stakeBalanceToBalancesId = commandId(SBTB);
    uint private immutable outScale;

    constructor(string memory input, uint scaledRatio) {
        outScale = scaledRatio;
        emit Command(host, SBTB, input, stakeBalanceToBalancesId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to stake a balance position and append resulting balances
    /// to `out`. Implementations validate and unpack `rawInput` as needed.
    function stakeBalanceToBalances(
        bytes32 account,
        AssetAmount memory balance,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function stakeBalanceToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(stakeBalanceToBalancesId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Balance, outScale);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            AssetAmount memory balance = ref.toBalanceValue();
            stakeBalanceToBalances(account, balance, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}

abstract contract StakeCustodyToBalances is CommandBase {
    uint internal immutable stakeCustodyToBalancesId = commandId(SCTB);
    uint private immutable outScale;

    constructor(string memory input, uint scaledRatio) {
        outScale = scaledRatio;
        emit Command(host, SCTB, input, stakeCustodyToBalancesId, Channels.Custodies, Channels.Balances);
    }

    /// @dev Override to stake a custody position and append resulting balances
    /// to `out`. Implementations validate and unpack `rawInput` as needed.
    function stakeCustodyToBalances(
        bytes32 account,
        HostAmount memory custody,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function stakeCustodyToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(stakeCustodyToBalancesId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Custody, outScale);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            HostAmount memory custody = ref.toCustodyValue();
            stakeCustodyToBalances(account, custody, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}

abstract contract StakeCustodyToPosition is CommandBase {
    uint internal immutable stakeCustodyToPositionId = commandId(SCTP);

    constructor(string memory input) {
        emit Command(host, SCTP, input, stakeCustodyToPositionId, Channels.Custodies, Channels.Setup);
    }

    /// @dev Override to stake a custody position into a non-balance setup
    /// target described by `rawInput`.
    function stakeCustodyToPosition(bytes32 account, HostAmount memory custody, Block memory rawInput) internal virtual;

    function stakeCustodyToPosition(
        CommandContext calldata c
    ) external payable onlyCommand(stakeCustodyToPositionId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint i = 0;
        uint q = 0;
        while (i < c.state.length) {
            Block memory ref = Blocks.from(c.state, i);
            if (ref.key != Keys.Custody) break;
            HostAmount memory custody = ref.toCustodyValue();
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            stakeCustodyToPosition(account, custody, input);
            i = ref.cursor;
        }

        return done(0, i);
    }
}
