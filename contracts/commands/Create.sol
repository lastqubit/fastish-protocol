// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "./Base.sol";
import { Blocks, Block } from "../Blocks.sol";
using Blocks for Block;

string constant NAME = "create";

abstract contract Create is CommandBase {
    uint internal immutable createId = commandId(NAME);

    constructor(string memory input) {
        emit Command(host, NAME, input, createId, Channels.Setup, Channels.Setup);
    }

    /// @dev Override to create or initialize an object described by
    /// `rawInput`. Called once per input block in the request.
    function create(bytes32 account, Block memory rawInput) internal virtual;

    function create(CommandContext calldata c) external payable onlyCommand(createId, c.target) returns (bytes memory) {
        bytes32 account = encodeAccount(c.account);
        uint q = 0;
        while (q < c.request.length) {
            Block memory input = Blocks.from(c.request, q);
            create(account, input);
            q = input.cursor;
        }

        return done(0, q);
    }
}
