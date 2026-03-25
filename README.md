# fastish

`fastish` is the Solidity library used to build hosts and commands for the Fastish protocol.

It contains the reusable contracts, utilities, and encoding helpers that Fastish applications compose on top of. If you are building a Fastish host, a command contract, or a small protocol extension that needs to speak Fastish's id, asset, and block formats, this repo is the shared foundation.

## What You Build With It

- `Host` contracts that register with Fastish discovery and expose trusted command endpoints
- `Command` contracts that execute protocol actions such as transfer, deposit, withdraw, settlement, and admin flows
- Shared request/response block parsing and writing logic
- Shared id, asset, account, and event encoding used across the protocol

## Main Entry Points

Most consumers should start from the barrel files in `contracts/`:

- `contracts/Core.sol`: core host and validation building blocks
- `contracts/Commands.sol`: base command contract plus standard command mixins
- `contracts/Blocks.sol`: block schema, readers, and writers
- `contracts/Utils.sol`: ids, assets, accounts, layout, strings, and value helpers
- `contracts/Events.sol`: reusable event emitters and event contracts

## Start Here

If you are new to Fastish, read [`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md) first.

It walks through:

- the host and command mental model
- which built-in commands expect `request` vs `state`
- a minimal host example
- a built-in command example
- a custom command example
- simple TypeScript request encoding

## Typical Usage

### Build a Host

Extend `Host` when you want a Fastish host contract with admin command support and optional discovery registration.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "fastish/contracts/Core.sol";

contract ExampleHost is Host {
    constructor(address fastish)
        Host(fastish, 1, "example")
    {}
}
```

`fastish` is the trusted Fastish runtime. If it is a contract, the host also announces itself there during deployment. Use `address(0)` for a self-managed host that does not auto-register.

`Host` already layers in the standard admin command flows used by Fastish hosts:

- `Authorize`
- `Unauthorize`
- `Relocate`

### Build a Command

Extend `CommandBase` when you want a Fastish command mixin that runs inside the protocol's trusted call model. Commands are abstract contracts mixed into a host or composed as a standalone module.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {CommandBase, CommandContext} from "fastish/contracts/Commands.sol";

string constant NAME = "myCommand";
string constant ROUTE = "route(uint foo, uint bar)";

abstract contract ExampleCommand is CommandBase {
    uint internal immutable myCommandId = commandId(NAME);

    constructor() {
        emit Command(host, NAME, ROUTE, myCommandId, 0, 0);
    }

    function myCommand(
        CommandContext calldata c
    ) external payable onlyCommand(myCommandId, c.target) returns (bytes memory) {
        return "";
    }
}
```

`CommandBase` gives you the common Fastish command context:

- trusted caller enforcement
- admin checks
- expiry checks
- command-to-command or command-to-host calls through encoded Fastish node ids
- shared command events

## Repo Layout

- `contracts/core`: host, access control, balances, and validation primitives
- `contracts/commands`: standard command building blocks and admin commands
- `contracts/peer`: peer protocol surfaces for inter-host asset flows
- `contracts/blocks`: request/response block encoding and decoding
- `contracts/utils`: shared protocol encoding helpers
- `contracts/events`: protocol event contracts and emitters
- `contracts/interfaces`: discovery interfaces and shared external protocol surfaces

## Install And Compile

```bash
npm install @fastish/contracts
npm run compile
```

The stable import surface for consumers is:

- `fastish/contracts/Core.sol`
- `fastish/contracts/Commands.sol`
- `fastish/contracts/Blocks.sol`
- `fastish/contracts/Utils.sol`
- `fastish/contracts/Events.sol`

## When To Use This Repo

Use `fastish` if you want to:

- create a new Fastish host
- implement a new Fastish command
- reuse Fastish's block format and wire encoding
- share protocol-level Solidity code across multiple Fastish applications

If you are looking for a full end-user app or deployment repo, this library is the lower-level protocol package rather than the full product surface.
