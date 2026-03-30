// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";

string constant UBTB = "unstakeBalanceToBalances";

using Blocks for Block;
using Writers for Writer;

abstract contract UnstakeBalanceToBalances is CommandBase {
    uint internal immutable unstakeBalanceToBalancesId = commandId(UBTB);
    uint private immutable outScale;

    constructor(string memory input, uint scaledRatio) {
        outScale = scaledRatio;
        emit Command(host, UBTB, input, unstakeBalanceToBalancesId, Channels.Balances, Channels.Balances);
    }

    /// @dev Override to unstake or redeem a balance position.
    /// Implementations validate and unpack `rawInput` as needed, and may
    /// append one or more BALANCE blocks to `out`.
    function unstakeBalanceToBalances(
        bytes32 account,
        AssetAmount memory balance,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function unstakeBalanceToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(unstakeBalanceToBalancesId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint i = 0;
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalancesFrom(c.state, i, Keys.Balance, outScale);

        while (i < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            Block memory ref = Blocks.from(c.state, i);
            AssetAmount memory balance = ref.toBalanceValue();
            unstakeBalanceToBalances(account, balance, input, writer);
            i = ref.cursor;
        }

        return writer.finish();
    }
}
