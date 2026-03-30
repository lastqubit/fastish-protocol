// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "./Base.sol";
import { Blocks, Block, Writers, Writer, Keys } from "../Blocks.sol";
using Writers for Writer;

string constant NAME = "mintToBalances";

abstract contract MintToBalances is CommandBase {
    uint internal immutable mintToBalancesId = commandId(NAME);
    uint private immutable outScale;

    constructor(string memory input, uint scaledRatio) {
        outScale = scaledRatio;
        emit Command(host, NAME, input, mintToBalancesId, Channels.Setup, Channels.Balances);
    }

    /// @dev Override to mint balances described by `rawInput` for `account`.
    /// Implementations may append one or more BALANCE blocks to `out`.
    function mintToBalances(
        bytes32 account,
        Block memory rawInput,
        Writer memory out
    ) internal virtual;

    function mintToBalances(
        CommandContext calldata c
    ) external payable onlyCommand(mintToBalancesId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint q = 0;
        (Writer memory writer, uint end) = Writers.allocScaledBalances(c.request, q, outScale);

        while (q < end) {
            Block memory input = Blocks.from(c.request, q);
            q = input.cursor;
            mintToBalances(account, input, writer);
        }

        return writer.finish();
    }
}
