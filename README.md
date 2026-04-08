# rootzero

`rootzero` is the Solidity library for building hosts and commands for the rootzero protocol.

It contains the reusable contracts, utilities, cursor parsers, and encoding helpers that rootzero applications compose on top of. If you are building a host, a command contract, or protocol tooling that needs to speak the protocol's id, asset, account, and block formats, this repo is the shared foundation.

## Main Entry Points

Most consumers should start from the package root entrypoints:

- `@rootzero/contracts/Core.sol`: core host, access control, balances, and validator building blocks
- `@rootzero/contracts/Commands.sol`: base command contract plus standard command mixins
- `@rootzero/contracts/Cursors.sol`: cursor readers, schemas, keys, memory refs, and writers
- `@rootzero/contracts/Utils.sol`: ids, assets, accounts, channels, layout, strings, and value helpers
- `@rootzero/contracts/Events.sol`: reusable event emitters and event contracts

## Start Here

If you are new to rootzero, read [`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md) first.

It walks through:

- the host and command mental model
- which built-in commands expect `request` vs `state`
- a minimal host example
- a built-in command example
- a custom command example
- simple TypeScript request encoding

## Typical Usage

### Build a Host

Extend `Host` when you want a rootzero host contract with admin command support and optional discovery registration.

```solidity
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {Host} from "@rootzero/contracts/Core.sol";

contract ExampleHost is Host {
    constructor(address rootzero)
        Host(rootzero, 1, "example")
    {}
}
```

`rootzero` is the trusted runtime. If it is a contract, the host also announces itself there during deployment. Use `address(0)` for a self-managed host that does not auto-register.

### Build a Command

Extend `CommandBase` when you want a rootzero command mixin that runs inside the protocol's trusted call model. Commands are abstract contracts mixed into a host.

```solidity
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.33;

import {CommandBase, CommandContext, Channels} from "@rootzero/contracts/Commands.sol";
import {Cursors, Cursor, Schemas} from "@rootzero/contracts/Cursors.sol";

using Cursors for Cursor;

string constant NAME = "myCommand";
string constant INPUT = Schemas.Amount;

abstract contract ExampleCommand is CommandBase {
    uint internal immutable myCommandId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, INPUT, myCommandId, Channels.Setup, Channels.Balances);
    }

    function myCommand(
        CommandContext calldata c
    ) external payable onlyCommand(myCommandId, c.target) returns (bytes memory) {
        Cursor memory input = Cursors.openBlock(c.request, 0);
        (bytes32 asset, bytes32 meta, uint amount) = input.unpackAmount();
        return Cursors.toBalanceBlock(asset, meta, amount);
    }
}
```

## Repo Layout

- `contracts/core`: host, access control, balances, operation, and validation primitives
- `contracts/commands`: standard command building blocks and admin commands
- `contracts/peer`: peer protocol surfaces for inter-host asset flows
- `contracts/blocks`: request/response schema, cursor parsing, memory refs, and writers
- `contracts/utils`: shared protocol encoding helpers
- `contracts/events`: protocol event contracts and emitters
- `contracts/interfaces`: discovery interfaces and shared external protocol surfaces
- `examples`: small host and command examples
- `docs`: introductory documentation

## Install And Compile

```bash
npm install @rootzero/contracts
npm run compile
```

## When To Use This Repo

Use `rootzero` if you want to:

- create a new rootzero host
- implement a new rootzero command
- reuse the protocol's block format and wire encoding
- share protocol-level Solidity code across multiple rootzero applications

If you are looking for a full end-user app or deployment repo, this library is the lower-level protocol package rather than the full product surface.
