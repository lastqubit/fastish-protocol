// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { CommandBase, CommandContext, State } from "./Base.sol";
import { Cursors, Cur } from "../Cursors.sol";
using Cursors for Cur;

string constant NAME = "burn";

abstract contract Burn is CommandBase {
    uint internal immutable burnId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, "", burnId, State.Balances, State.Empty);
    }

    /// @dev Override to burn or consume the provided balance amount.
    /// Called once per BALANCE block in state.
    function burn(bytes32 account, bytes32 asset, bytes32 meta, uint amount) internal virtual returns (uint);

    function burn(CommandContext calldata c) external payable onlyCommand(burnId, c.target) returns (bytes memory) {
        (Cur memory state, ) = cursor(c.state, 1);

        while (state.i < state.bound) {
            (bytes32 asset, bytes32 meta, uint amount) = state.unpackBalance();
            burn(c.account, asset, meta, amount);
        }

        state.complete();
        return "";
    }
}





