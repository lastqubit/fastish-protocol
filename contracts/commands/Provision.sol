// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, CUSTODIES, SETUP} from "./Base.sol";
import {AMOUNT, AMOUNT_KEY, BlockRef, NODE, Writer} from "../blocks/Schema.sol";
import {Blocks} from "../blocks/Readers.sol";
import {Writers} from "../blocks/Writers.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "provision";
string constant REQUEST = string.concat(AMOUNT, ";", NODE);

using Blocks for BlockRef;
using Writers for Writer;

// @dev Sources assets externally and delivers them directly into host custody.
abstract contract Provision is CommandBase {
    uint internal immutable provisionId = toCommandId(NAME, address(this));

    constructor() {
        emit Command(host, NAME, REQUEST, provisionId, SETUP, CUSTODIES);
    }

    function provision(uint host, bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual;

    function provision(
        CommandContext calldata c
    ) external payable onlyCommand(provisionId, c.target) returns (bytes memory) {
        uint i = 0;
        (Writer memory writer, uint next) = Writers.allocCustodiesFrom(c.request, i, AMOUNT_KEY);
        uint host = Blocks.resolveNode(c.request, next, 0);

        while (i < next) {
            BlockRef memory ref = Blocks.amountFrom(c.request, i);
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackAmount(c.request);
            provision(host, c.account, asset, meta, amount);
            writer.appendCustody(host, asset, meta, amount);
            i = ref.end;
        }

        return writer.done();
    }
}
