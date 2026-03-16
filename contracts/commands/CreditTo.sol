// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandBase, CommandContext, BALANCES, SETUP} from "./Base.sol";
import {BlockRef, RECIPIENT} from "../blocks/Schema.sol";
import {Blocks} from "../blocks/Readers.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "creditTo";

using Blocks for BlockRef;

abstract contract CreditTo is CommandBase {
    uint internal immutable creditToId = toCommandId(NAME, address(this));

    constructor() {
        emit Command(host, NAME, RECIPIENT, creditToId, BALANCES, SETUP);
    }

    function creditTo(bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual returns (uint);

    function creditTo(
        CommandContext calldata c
    ) external payable onlyCommand(creditToId, c.target) returns (bytes memory) {
        bytes32 to = Blocks.resolveRecipient(c.request, 0, c.account);
        uint i = 0;
        while (i < c.state.length) {
            BlockRef memory ref = Blocks.from(c.state, i);
            if (!ref.isBalance()) break;
            (bytes32 asset, bytes32 meta, uint amount) = ref.unpackBalance(c.state);
            creditTo(to, asset, meta, amount);         
            i = ref.end;
        }

        return done(0, i);
    }
}
