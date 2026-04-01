// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandContext, CommandBase, Channels } from "./Base.sol";
import { AssetAmount, Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";

string constant NAME = "reclaimToBalances";

using Blocks for Block;
using Writers for Writer;

abstract contract ReclaimToBalances is CommandBase {
    uint internal immutable reclaimToBalancesId = commandId(NAME);
    uint private immutable outScale;

    constructor(string memory input, uint scaledRatio) {
        outScale = scaledRatio;
        emit Command(host, NAME, input, reclaimToBalancesId, Channels.Setup, Channels.Balances);
    }

    /// @dev Override to reclaim balances described by `rawInput`.
    /// Implementations validate and unpack it as needed, and may append one or
    /// more BALANCE blocks to `out`.
    function reclaimToBalances(
        bytes32 account,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function reclaimToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(reclaimToBalancesId, c.target) returns (bytes memory) {
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalances(c.request, q, outScale);

        while (q < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            reclaimToBalances(c.account, input, writer);
        }

        return writer.finish();
    }
}
