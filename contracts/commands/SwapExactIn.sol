// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES} from "./Base.sol";
import {BALANCE} from "../blocks/Schema.sol";
import {MapBalanceWithRequestRoute} from "../combinators/MapBalance.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "swapExactInAsset32";

// Swap exact-in command for balance blocks whose effective asset identifier is a single bytes32 word.
abstract contract SwapExactInAsset32 is CommandBase, MapBalanceWithRequestRoute {
    uint internal immutable swapExactInAsset32Id = toCommandId(NAME, address(this));

    constructor(string memory route) {
        emit Command(host, NAME, string.concat(BALANCE, ">", route, "->", BALANCE), swapExactInAsset32Id, BALANCES, BALANCES);
    }

    function swapExactInAsset32(bytes calldata data) external view virtual returns (bytes memory quote) {}

    function swapExactInAsset32(
        CommandContext calldata c
    ) external payable onlyCommand(swapExactInAsset32Id, c.target) returns (bytes memory) {
        return mapBalancesWithRequestRoutes(c.state, c.request, 0, 0, c.account);
    }
}
