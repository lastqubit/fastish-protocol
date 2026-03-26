// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {BalanceEvent} from "../events/Balance.sol";

error InsufficientFunds();

abstract contract Balances is BalanceEvent {
    mapping(bytes32 account => mapping(bytes32 ref => uint amount)) internal balances;

    function debitFrom(bytes32 account, bytes32 ref, uint amount) internal returns (uint balance) {
        balance = balances[account][ref];
        if (balance < amount) revert InsufficientFunds();
        unchecked {
            balance -= amount;
        }
        balances[account][ref] = balance;
    }

    function creditTo(bytes32 account, bytes32 ref, uint amount) internal returns (uint balance) {
        balance = balances[account][ref] += amount;
    }
}
