// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandContext, CommandBase, BALANCES} from "./Base.sol";
import {MINIMUM} from "../blocks/Schema.sol";
import {MapBalanceWithRequestRoute} from "../combinators/MapBalance.sol";
import {toCommandId} from "../utils/Ids.sol";

bytes32 constant NAME = "swapExactIn";

abstract contract SwapExactIn is CommandBase, MapBalanceWithRequestRoute {
    uint internal immutable swapExactInId = toCommandId(NAME, address(this));

    constructor(string memory route) {
        emit Command(host, NAME, string.concat(route, ">", MINIMUM), swapExactInId, BALANCES, BALANCES);
    }

    function swapExactIn(
        CommandContext calldata c
    ) external payable onlyCommand(swapExactInId, c.target) returns (bytes memory) {
        return mapBalancesWithRequestRoutes(c.state, c.request, 0, 0, c.account);
    }
}
