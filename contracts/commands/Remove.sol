// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "./Base.sol";
import { Blocks, Block } from "../Blocks.sol";
using Blocks for Block;

string constant NAME = "remove";

abstract contract Remove is CommandBase {
    uint internal immutable removeId = commandId(NAME);

    constructor(string memory input) {
        emit Command(host, NAME, input, removeId, Channels.Setup, Channels.Setup);
    }

    /// @dev Override to remove or dismantle an object described by `rawInput`.
    /// Called once per input block in the request.
    function remove(bytes32 account, Block memory rawInput) internal virtual;

    function remove(CommandContext calldata c) external payable onlyCommand(removeId, c.target) returns (bytes memory) {
        uint q = 0;
        while (q < c.request.length) {
            Block memory input = Blocks.from(c.request, q);
            remove(c.account, input);
            q = input.cursor;
        }

        return done(0, q);
    }
}
