// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, HostAmount } from "../blocks/Schema.sol";
import { Keys } from "../blocks/Keys.sol";
import { Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";

using Blocks for Block;
using Writers for Writer;

string constant ALFCTB = "addLiquidityFromCustodiesToBalances";
string constant ALFBTB = "addLiquidityFromBalancesToBalances";
string constant RLFCTB = "removeLiquidityFromCustodyToBalances";
string constant RLFBTB = "removeLiquidityFromBalanceToBalances";

abstract contract AddLiquidityFromCustodiesToBalances is CommandBase {
    uint internal immutable addLiquidityFromCustodiesToBalancesId = commandId(ALFCTB);
    uint private immutable outScale;
    bool private immutable useInput;

    constructor(string memory maybeInput, uint scaledRatio) {
        outScale = scaledRatio;
        useInput = bytes(maybeInput).length > 0;
        emit Command(host, ALFCTB, maybeInput, addLiquidityFromCustodiesToBalancesId, Channels.Custodies, Channels.Balances);
    }

    /// @dev Override to add liquidity from two custody inputs.
    /// `rawInput` carries any optional extra request block and should be
    /// ignored when `maybeInput` is empty. Implementations validate and unpack
    /// it as needed. Implementations may append up to
    /// three BALANCE blocks to `out`: two refunds plus the liquidity receipt.
    function addLiquidityFromCustodiesToBalances(
        bytes32 account,
        Block memory custodiesView,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function addLiquidityFromCustodiesToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(addLiquidityFromCustodiesToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Custody, outScale);

        while (i < end) {
            Block memory input;
            if (useInput) {
                input = Blocks.from(c.request, q);
                q = input.cursor;
            }
            Block memory custodies = Blocks.viewFrom(c.state, i, 2);
            i = custodies.cursor;
            addLiquidityFromCustodiesToBalances(c.account, custodies, input, writer);
        }

        return writer.finish();
    }
}

abstract contract RemoveLiquidityFromCustodyToBalances is CommandBase {
    uint internal immutable removeLiquidityFromCustodyToBalancesId = commandId(RLFCTB);
    uint private immutable outScale;
    bool private immutable useInput;

    constructor(string memory maybeInput, uint scaledRatio) {
        outScale = scaledRatio;
        useInput = bytes(maybeInput).length > 0;
        emit Command(host, RLFCTB, maybeInput, removeLiquidityFromCustodyToBalancesId, Channels.Custodies, Channels.Balances);
    }

    /// @dev Override to remove liquidity from a custody position.
    /// `rawInput` carries any optional extra request block and should be
    /// ignored when `maybeInput` is empty. Implementations validate and unpack
    /// it as needed. Implementations may append up to two BALANCE blocks to
    /// `out`.
    function removeLiquidityFromCustodyToBalances(
        bytes32 account,
        HostAmount memory custody,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function removeLiquidityFromCustodyToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(removeLiquidityFromCustodyToBalancesId, c.target) returns (bytes memory) {
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
            removeLiquidityFromCustodyToBalances(c.account, custody, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}

abstract contract AddLiquidityFromBalancesToBalances is CommandBase {
    uint internal immutable addLiquidityFromBalancesToBalancesId = commandId(ALFBTB);
    uint private immutable outScale;
    bool private immutable useInput;

    constructor(string memory maybeInput, uint scaledRatio) {
        outScale = scaledRatio;
        useInput = bytes(maybeInput).length > 0;
        emit Command(host, ALFBTB, maybeInput, addLiquidityFromBalancesToBalancesId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to add liquidity from two balance inputs.
    /// `rawInput` carries any optional extra request block and should be
    /// ignored when `maybeInput` is empty. Implementations validate and unpack
    /// it as needed. Implementations may append up to
    /// three BALANCE blocks to `out`: two refunds plus the liquidity receipt.
    function addLiquidityFromBalancesToBalances(
        bytes32 account,
        Block memory balancesView,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function addLiquidityFromBalancesToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(addLiquidityFromBalancesToBalancesId, c.target) returns (bytes memory) {
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Balance, outScale);

        while (i < end) {
            Block memory input;
            if (useInput) {
                input = Blocks.from(c.request, q);
                q = input.cursor;
            }
            Block memory balances = Blocks.viewFrom(c.state, i, 2);
            i = balances.cursor;
            addLiquidityFromBalancesToBalances(c.account, balances, input, writer);
        }

        return writer.finish();
    }
}

abstract contract RemoveLiquidityFromBalanceToBalances is CommandBase {
    uint internal immutable removeLiquidityFromBalanceToBalancesId = commandId(RLFBTB);
    uint private immutable outScale;
    bool private immutable useInput;

    constructor(string memory maybeInput, uint scaledRatio) {
        outScale = scaledRatio;
        useInput = bytes(maybeInput).length > 0;
        emit Command(host, RLFBTB, maybeInput, removeLiquidityFromBalanceToBalancesId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to remove liquidity from a balance position.
    /// `rawInput` carries any optional extra request block and should be
    /// ignored when `maybeInput` is empty. Implementations validate and unpack
    /// it as needed. Implementations may append up to two BALANCE blocks to
    /// `out`.
    function removeLiquidityFromBalanceToBalances(
        bytes32 account,
        AssetAmount memory balance,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function removeLiquidityFromBalanceToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(removeLiquidityFromBalanceToBalancesId, c.target) returns (bytes memory) {
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
            removeLiquidityFromBalanceToBalances(c.account, balance, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}
