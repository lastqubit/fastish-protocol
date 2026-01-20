// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {DebitFrom} from "./Commands/DebitFrom.sol";
import {CreditTo} from "./Commands/CreditTo.sol";
import {BalanceEvent} from "./Events/Account/Balance.sol";
import {toAmount} from "./Utils/Amount.sol";

abstract contract Balances is DebitFrom, CreditTo, BalanceEvent {
    mapping(uint account => mapping(uint id => uint amount)) internal balances;

    function creditTo(
        uint account,
        uint id,
        uint amount
    ) internal override returns (uint) {
        if (amount == 0 || account == 0) return 0;
        uint total = balances[account][id] += amount;
        emit Balance(account, initiateId, id, total, amount);
        return amount;
    }

    function debitFrom(
        uint account,
        uint id,
        uint amount
    ) internal returns (uint) {
        if (amount == 0 || account == 0) return 0;
        uint total = balances[account][id] -= amount;
        emit Balance(account, initiateId, id, total, amount);
        return amount;
    }

    // revert on 0 ??? Amount.resolve ??
    function debitFrom(
        uint account,
        uint id,
        uint min,
        uint max
    ) internal returns (uint) {
        return
            debitFrom(account, id, toAmount(balances[account][id], min, max));
    }

// Remove ??
    function debitFrom(
        uint account,
        uint id,
        uint min,
        uint max,
        uint fee
    ) internal override returns (uint) {
        uint amount = debitFrom(account, id, min, max);
        uint out = amount - 0; //fee; ///////////
        return out;
    }
}
