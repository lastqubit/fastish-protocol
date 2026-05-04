// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

// Aggregator: re-exports command, control, and remote abstractions.
// Import this file to inherit from the full rootzero command surface without managing individual paths.

import { CommandBase, CommandContext, CommandPayable } from "./commands/Base.sol";
import { Keys } from "./blocks/Keys.sol";
import { Burn, BurnHook } from "./commands/Burn.sol";
import { CreditAccount, CreditAccountHook } from "./commands/Credit.sol";
import { DebitAccount, DebitAccountHook } from "./commands/Debit.sol";
import { Deposit, DepositHook, DepositPayable, DepositPayableHook } from "./commands/Deposit.sol";
import { PipePayable, PipePayableHook } from "./commands/Pipe.sol";
import { Provision, ProvisionHook, ProvisionPayable, ProvisionPayableHook } from "./commands/Provision.sol";
import { Transfer, TransferHook } from "./commands/Transfer.sol";
import { Withdraw, WithdrawHook } from "./commands/Withdraw.sol";
import { AllowAssets, AllowAssetsHook } from "./commands/control/AllowAssets.sol";
import { Destroy, DestroyHook } from "./commands/control/Destroy.sol";
import { ExecutePayable } from "./commands/control/Execute.sol";
import { Authorize } from "./commands/control/Authorize.sol";
import { DenyAssets, DenyAssetsHook } from "./commands/control/DenyAssets.sol";
import { Init, InitHook } from "./commands/control/Init.sol";
import { Allowance, AllowanceHook } from "./commands/control/Allowance.sol";
import { Unauthorize } from "./commands/control/Unauthorize.sol";
import { RemoteBase, encodeRemoteCall } from "./remote/Base.sol";
import { RemoteAllowance } from "./remote/Allowance.sol";
import { RemoteAssetPull, AssetPullHook } from "./remote/AssetPull.sol";
import { RemoteAllowAssets } from "./remote/AllowAssets.sol";
import { RemoteDenyAssets } from "./remote/DenyAssets.sol";
import { RemoteSettle } from "./remote/Settle.sol";




