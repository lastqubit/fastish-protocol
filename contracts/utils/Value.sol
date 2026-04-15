// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

/// @notice Mutable native-value budget drawn down as sub-calls consume ETH.
struct Budget {
    /// @dev Remaining unspent native value in wei.
    uint remaining;
}

/// @title Values
/// @notice Native-value (ETH) budget tracking for commands that accept `msg.value`.
library Values {
    /// @dev Thrown when a call attempts to spend more native value than remains in the budget.
    error InsufficientValue();

    /// @notice Create a budget from the current call's `msg.value`.
    /// @return Budget initialised with the full `msg.value`.
    function fromMsg() internal view returns (Budget memory) {
        return Budget({remaining: msg.value});
    }

    /// @notice Deduct `amount` from the budget and return it.
    /// Reverts if `amount` exceeds `budget.remaining`.
    /// @param budget Mutable budget to deduct from.
    /// @param amount Native value to spend in wei.
    /// @return The same `amount`, ready to forward to a callee.
    function use(Budget memory budget, uint amount) internal pure returns (uint) {
        if (amount > budget.remaining) revert InsufficientValue();
        budget.remaining -= amount;
        return amount;
    }

    /// @notice Deduct all remaining native value from the budget and return it.
    /// @param budget Mutable budget to drain.
    /// @return Remaining native value before the budget was emptied.
    function drain(Budget memory budget) internal pure returns (uint) {
        uint amount = budget.remaining;
        budget.remaining = 0;
        return amount;
    }
}
