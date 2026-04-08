// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {BalanceEvent} from "../events/Balance.sol";

error InsufficientFunds();

abstract contract Balances is BalanceEvent {
    mapping(bytes32 account => mapping(bytes32 assetKey => uint amount)) internal balances;

    function debitFrom(bytes32 account, bytes32 assetKey, uint amount) internal returns (uint balance) {
        balance = balances[account][assetKey];
        if (balance < amount) revert InsufficientFunds();
        unchecked {
            balance -= amount;
        }
        balances[account][assetKey] = balance;
    }

    function creditTo(bytes32 account, bytes32 assetKey, uint amount) internal returns (uint balance) {
        balance = balances[account][assetKey] += amount;
    }
}



