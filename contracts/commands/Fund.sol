// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES, CUSTODIES} from "./Base.sol";
import {BALANCE_KEY, BlockRef, NODE, Writer} from "../blocks/Schema.sol";
import {Blocks} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "fund";

using Blocks for BlockRef;
using Writers for Writer;

// @dev Converts BALANCE state into CUSTODY state for a destination host.
abstract contract Fund is CommandBase {
    uint internal immutable fundId = toCommandId(NAME, address(this));

    constructor() {
        emit Command(host, NAME, NODE, fundId, BALANCES, CUSTODIES);
    }

    function fund(uint host, bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual;

    function fund(CommandContext calldata c) external payable onlyCommand(fundId, c.target) returns (bytes memory) {
        uint host = Blocks.resolveNode(c.request, 0, 0);
        uint i = 0;
        (Writer memory writer, uint next) = Writers.allocCustodiesFrom(c.state, i, BALANCE_KEY);

        while (i < next) {
            BlockRef memory ref = Blocks.balanceFrom(c.state, i);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackBalance(c.state);
            fund(host, c.account, asset, meta, amount);
            writer.appendCustody(host, asset, meta, amount);
            i = ref.end;
        }

        return writer.done();
    }
}
