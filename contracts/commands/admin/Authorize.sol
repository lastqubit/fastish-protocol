// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "../Base.sol";
import { Cursors, Cursor, Keys, Schemas } from "../../Cursors.sol";
using Cursors for Cursor;

string constant NAME = "authorize";

abstract contract Authorize is CommandBase {
    uint internal immutable authorizeId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Node, authorizeId, Channels.Setup, Channels.Setup);
    }

    function authorize(
        CommandContext calldata c
    ) external payable onlyAdmin(c.account) onlyCommand(authorizeId, c.target) returns (bytes memory) {
        Cursor memory input = Cursors.openStream(c.request, 0);
        while (input.i < input.end) {
            if (!input.isAt(Keys.Node)) break;
            uint node = input.unpackNode();
            access(node, true);
        }
        return done(input);
    }
}



