// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

// Aggregator: re-exports command, admin, and peer abstractions.
// Import this file to inherit from the full rootzero command surface without managing individual paths.

import { CommandBase, CommandContext, CommandPayable, encodeCommandCall } from "./commands/Base.sol";
import { State } from "./utils/State.sol";
import { Burn } from "./commands/Burn.sol";
import { Create } from "./commands/Create.sol";
import { CreditAccount } from "./commands/Credit.sol";
import { DebitAccount } from "./commands/Debit.sol";
import { Deposit, DepositPayable } from "./commands/Deposit.sol";
import { Remove } from "./commands/Remove.sol";
import { PipePayable } from "./commands/Pipe.sol";
import { Provision, ProvisionPayable, ProvisionFromBalance } from "./commands/Provision.sol";
import { Settle } from "./commands/Settle.sol";
import { StakeCustodyToPosition } from "./commands/Stake.sol";
import { Supply } from "./commands/Supply.sol";
import { Transfer } from "./commands/Transfer.sol";
import { Withdraw } from "./commands/Withdraw.sol";
import { AllowAssets, AllowAssetsHook } from "./commands/admin/AllowAssets.sol";
import { Destroy } from "./commands/admin/Destroy.sol";
import { Authorize } from "./commands/admin/Authorize.sol";
import { DenyAssets, DenyAssetsHook } from "./commands/admin/DenyAssets.sol";
import { Init } from "./commands/admin/Init.sol";
import { RelocatePayable } from "./commands/admin/Relocate.sol";
import { Allocate } from "./commands/admin/Allocate.sol";
import { Unauthorize } from "./commands/admin/Unauthorize.sol";
import { PeerBase, encodePeerCall } from "./peer/Base.sol";
import { PeerAssetPull } from "./peer/AssetPull.sol";
import { PeerAllowAssets } from "./peer/AllowAssets.sol";
import { PeerDenyAssets } from "./peer/DenyAssets.sol";
import { PeerPull } from "./peer/Pull.sol";
import { PeerPush } from "./peer/Push.sol";
import { PeerSettle } from "./peer/Settle.sol";




