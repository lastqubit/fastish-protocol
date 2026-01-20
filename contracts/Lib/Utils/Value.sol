// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {Value} from "../Entity.sol";

error BadValue();

function useValue(Value memory total, uint amount) pure returns (uint) {
    if (amount > total.amount) {
        revert BadValue();
    }
    total.amount -= amount;
    return amount;
}
