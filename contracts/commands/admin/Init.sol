// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "../Base.sol";
import { Blocks, Block } from "../../Blocks.sol";

string constant NAME = "init";

abstract contract Init is CommandBase {
    uint internal immutable initId = commandId(NAME);

    constructor(string memory input) {
        emit Command(host, NAME, input, initId, Channels.Setup, Channels.Setup);
    }

    /// @dev Override to run host initialization logic using the decoded input.
    function init(Block memory rawInput) internal virtual;

    function init(
        CommandContext calldata c
    ) external payable onlyAdmin(c.account) onlyCommand(initId, c.target) returns (bytes memory) {
        Block memory input = Blocks.from(c.request, 0);
        init(input);
        return done(0, input.cursor);
    }
}
