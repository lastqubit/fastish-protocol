// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

// Example 4: Batch Processing
//
// Requests can contain multiple blocks of the same type.
// This example shows how to iterate over all AMOUNT blocks in a request
// and produce a matching BALANCE block for each one.
//
// Use Writers when you need to build the response incrementally rather than
// returning a single pre-encoded block.

import {CommandBase, CommandContext, Channels} from "../contracts/Commands.sol";
import {Cursors, Cursor, Writers, Writer, Keys, Schemas} from "../contracts/Cursors.sol";

using Cursors for Cursor;
using Writers for Writer;

string constant NAME = "myCommand";

abstract contract MyCommand is CommandBase {
    uint internal immutable myCommandId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, Schemas.Amount, myCommandId, Channels.Setup, Channels.Balances);
    }

    function myCommand(
        CommandContext calldata c
    ) external payable onlyCommand(myCommandId, c.target) returns (bytes memory) {
        // Bound a cursor to the contiguous AMOUNT prefix and count how many
        // output BALANCE blocks we need to allocate.
        (Cursor memory inputs, uint count) = Cursors.openKeyed(c.request, 0, Keys.Amount);
        Writer memory writer = Writers.allocBalances(count);

        // Walk every AMOUNT block in the request.
        while (inputs.i < inputs.end) {
            // Unpack asset, meta, and amount from the next AMOUNT block.
            (bytes32 asset, bytes32 meta, uint amount) = inputs.unpackAmount();

            // Apply your app logic here (e.g. debit the account), then append a BALANCE block.
            writer.appendBalance(asset, meta, amount);
        }

        // Finalize and return the encoded BALANCE blocks.
        return writer.done();
    }
}



