// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, Channels } from "../Base.sol";
import { Cursors, Cursor, Keys, Schemas } from "../../Cursors.sol";
using Cursors for Cursor;

string constant NAME = "relocate";

abstract contract Relocate is CommandBase {
    uint internal immutable relocateId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Funding, relocateId, Channels.Setup, Channels.Setup);
    }

    function relocate(
        CommandContext calldata c
    ) external payable onlyAdmin(c.account) onlyCommand(relocateId, c.target) returns (bytes memory) {
        (Cursor memory input, ) = Cursors.openTyped(c.request, 0, Keys.Funding);

        while (input.i < input.end) {
            (uint host, uint amount) = input.unpackFunding();
            callTo(host, amount, "");
        }

        return done(input);
    }
}


