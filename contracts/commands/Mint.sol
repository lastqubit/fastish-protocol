// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "./Base.sol";
import { Blocks, Cursor, Writers, Writer, Keys } from "../Blocks.sol";
using Blocks for Cursor;
using Writers for Writer;

string constant NAME = "mintToBalances";

abstract contract MintToBalances is CommandBase {
    uint internal immutable mintToBalancesId = commandId(NAME);
    uint private immutable outScale;

    constructor(string memory input, uint scaledRatio) {
        outScale = scaledRatio;
        emit Command(host, NAME, input, mintToBalancesId, Channels.Setup, Channels.Balances);
    }

    /// @dev Override to mint balances described by the current `input` stream
    /// position for `account`.
    /// Implementations should consume the request blocks they handle by
    /// advancing `input`, and may append BALANCE outputs to `out` within the
    /// capacity implied by this command's configured `scaledRatio`.
    function mintToBalances(
        bytes32 account,
        Cursor memory input,
        Writer memory out
    ) internal virtual;

    function mintToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(mintToBalancesId, c.target) returns (bytes memory) {
        (Cursor memory inputs, uint count) = Blocks.allFrom(c.request, 0);
        Writer memory writer = Writers.allocScaledBalances(count, outScale);

        while (inputs.i < inputs.end) {
            Cursor memory input = inputs.take();
            mintToBalances(c.account, input, writer);
        }

        return writer.finish();
    }
}
