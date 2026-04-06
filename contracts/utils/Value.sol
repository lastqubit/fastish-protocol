// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

library Values {
    error InsufficientValue();

    struct Budget {
        uint remaining;
    }

    function fromMsg() internal view returns (Budget memory) {
        return Budget({remaining: msg.value});
    }

    function use(Budget memory budget, uint amount) internal pure returns (uint) {
        if (amount > budget.remaining) revert InsufficientValue();
        budget.remaining -= amount;
        return amount;
    }
}


