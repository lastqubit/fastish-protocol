// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.33;

import {DebitFrom} from "../Lib/Commands/DebitFrom.sol";
import {CreditTo} from "../Lib/Commands/CreditTo.sol";
import {BalanceEvent} from "../Lib/Events/Account/Balance.sol";

abstract contract Endpoints is DebitFrom, CreditTo, BalanceEvent {}
