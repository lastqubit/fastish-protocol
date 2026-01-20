// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

error ZeroAmount();
error BadAmount(uint amount);
error Nondeductible(uint amount, uint disposable);

function ensureAmount(uint amount) pure returns (uint) {
    if (amount == 0) {
        revert ZeroAmount();
    }
    return amount;
}

function ensureAmount(uint amount, uint min, uint max) pure returns (uint) {
    if (amount < min || amount > max) {
        revert BadAmount(amount);
    }
    return amount;
}
// revert on not in range...
function toAmount(uint disposable, uint min, uint max) pure returns (uint) {
    uint amount = disposable > max ? max : disposable;
    return amount < min ? 0 : amount;
}

library Amount {
    function valid(
        uint amount,
        uint min,
        uint max
    ) internal pure returns (bool) {
        return amount >= min && amount <= max;
    }

    function ensure(uint amount) internal pure returns (uint) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        return amount;
    }

    function ensure(uint amount, uint eq) internal pure returns (uint) {
        if (amount != eq) {
            revert BadAmount(amount);
        }
        return amount;
    }

    function ensure(
        uint amount,
        uint min,
        uint max
    ) internal pure returns (uint) {
        if (amount < min || amount > max) {
            revert BadAmount(amount);
        }
        return amount;
    }

    function out(uint amount, uint min, uint max) internal pure returns (uint) {
        return max - ensure(amount, min, max);
    }

    function deduct(uint amount, uint disposable) internal pure returns (uint) {
        if (amount > disposable) {
            revert Nondeductible(amount, disposable);
        }
        return disposable - amount;
    }

    function find(
        uint disposable,
        uint min,
        uint max
    ) internal pure returns (uint) {
        uint amount = disposable > max ? max : disposable;
        return amount < min ? 0 : amount;
    }

    function resolve(
        uint disposable,
        uint min,
        uint max
    ) internal pure returns (uint) {
        return ensure(find(disposable, min, max));
    }
}
