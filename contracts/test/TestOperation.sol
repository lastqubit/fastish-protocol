// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import { Cursors } from "../Cursors.sol";
import { OperationBase } from "../core/Operation.sol";
import { AccessControl } from "../core/Access.sol";

contract TestOperation is OperationBase {
    constructor() AccessControl(address(0)) {}

    function testCheckCursorRatio(
        bytes calldata state,
        uint stateGroup,
        bytes calldata request,
        uint requestGroup
    ) external pure returns (bool) {
        (, , uint stateQuotient) = cursor(state, stateGroup);
        (, , uint requestQuotient) = cursor(request, requestGroup);
        if (stateQuotient != requestQuotient) revert Cursors.BadRatio();
        return true;
    }
}
