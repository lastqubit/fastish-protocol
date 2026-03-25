# Uniswap Wrapper

This guide shows how to wire Fastish Protocol swap and liquidity commands to Uniswap V3. Fastish provides the command dispatch layer; your host implements the hooks that call Uniswap.

## How it works

```text
Fastish runtime
  -> calls command (for example swapExactCustodyToBalance)
     -> command iterates state blocks and calls your hook once per block
        -> your hook decodes route params, calls Uniswap, and returns result
```

Your host implements only the inner hook logic, not the request loop or block encoding.

---

## Imports

```solidity
import {Host} from "../contracts/Core.sol";
import {
    SwapExactBalanceToBalance,
    SwapExactCustodyToBalance,
    AddLiquidityFromBalancesToBalances,
    AddLiquidityFromCustodiesToBalances,
    RemoveLiquidityFromBalanceToBalances,
    RemoveLiquidityFromCustodyToBalances
} from "../contracts/Commands.sol";
import {Data, DataRef, DataPairRef, AssetAmount, HostAmount, Writers, Writer} from "../contracts/Blocks.sol";
import {Assets} from "../contracts/Utils.sol";

using Data for DataRef;
using Writers for Writer;
```

---

## Uniswap V3 interfaces

Declare only what you need.

```solidity
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        returns (uint amountOut);
}

interface IERC20Minimal {
    function approve(address spender, uint amount) external returns (bool);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(MintParams calldata params)
        external
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    function positions(uint tokenId) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint feeGrowthInside0LastX128,
        uint feeGrowthInside1LastX128,
        uint tokensOwed0,
        uint tokensOwed1
    );

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        returns (uint amount0, uint amount1);

    function collect(CollectParams calldata params)
        external
        returns (uint amount0, uint amount1);
}
```

---

## Swap commands

### `SwapExactBalanceToBalance`

Triggered when the incoming pipeline state contains `balance(...)` blocks. Called once per balance.

**Hook signature** (from [contracts/commands/Swap.sol](../contracts/commands/Swap.sol)):

```solidity
function swapExactBalanceToBalance(
    bytes32 account,
    AssetAmount memory balance,
    DataRef memory rawRoute
) internal virtual returns (AssetAmount memory out);
```

| Parameter        | Type      | Description                                                                         |
| ---------------- | --------- | ----------------------------------------------------------------------------------- |
| `account`        | `bytes32` | The Fastish account ID making the swap                                              |
| `balance.asset`  | `bytes32` | Fastish asset ID of the input token                                                 |
| `balance.meta`   | `bytes32` | Optional metadata                                                                   |
| `balance.amount` | `uint`    | Input token amount                                                                  |
| `rawRoute`       | `DataRef` | Route block from the request; call `rawRoute.innerMinimum()` to get slippage params |

**Route extraction:**

```solidity
(bytes32 assetOut, bytes32 meta, uint minOut) = rawRoute.innerMinimum();
```

One reasonable convention for a general wrapper is:
- `assetOut` = output asset
- `meta` = fee tier encoded into `bytes32`
- `minOut` = output floor

---

### `SwapExactCustodyToBalance`

Same as above but the input is a `custody(...)` block rather than a balance.

**Hook signature** (from [contracts/commands/Swap.sol](../contracts/commands/Swap.sol)):

```solidity
function swapExactCustodyToBalance(
    bytes32 account,
    HostAmount memory custody,
    DataRef memory rawRoute
) internal virtual returns (AssetAmount memory out);
```

| Parameter        | Type      | Description                                |
| ---------------- | --------- | ------------------------------------------ |
| `account`        | `bytes32` | The Fastish account ID                     |
| `custody.host`   | `uint`    | Fastish host ID that holds the escrowed asset |
| `custody.asset`  | `bytes32` | Fastish asset ID of the input token        |
| `custody.meta`   | `bytes32` | Optional metadata                          |
| `custody.amount` | `uint`    | Escrowed amount to swap                    |
| `rawRoute`       | `DataRef` | Route block for output asset, fee, minimum |

---

## Liquidity commands

Liquidity hooks receive a `Writer memory out` parameter and call `out.appendBalance(...)` directly for each output block. The command calls `writer.finish()` after your hook returns.

The `scaledRatio` constructor argument controls how many output blocks are pre-allocated per input block, scaled by `10_000`.

- `10_000` = 1 output per input
- `20_000` = 2 outputs per input
- `30_000` = 3 outputs per input

### `AddLiquidityFromCustodiesToBalances`

Triggered when the state contains pairs of `custody(...)` blocks. Called once per pair.

**Hook signature** (from [contracts/commands/Liquidity.sol](../contracts/commands/Liquidity.sol)):

```solidity
function addLiquidityFromCustodiesToBalances(
    bytes32 account,
    DataPairRef memory rawCustodies,
    DataRef memory rawRoute,
    Writer memory out
) internal virtual;
```

| Parameter        | Type      | Description                                                                  |
| ---------------- | --------- | ---------------------------------------------------------------------------- |
| `account`        | `bytes32` | The Fastish account ID                                                       |
| `rawCustodies.a` | `DataRef` | First custody block                                                          |
| `rawCustodies.b` | `DataRef` | Second custody block                                                         |
| `rawRoute`       | `DataRef` | Route block; general wrappers typically decode fee, tick range, and minimums |
| `out`            | `Writer`  | Output writer; call `out.appendBalance(...)` up to 3 times                   |

**Extracting custody values:**

```solidity
AssetAmount memory c0 = rawCustodies.a.expectCustody(host);
AssetAmount memory c1 = rawCustodies.b.expectCustody(host);
```

**Output:** Append up to three balance blocks: token0 refund, token1 refund, and the LP NFT receipt.

```solidity
out.appendBalance(lpTokenAsset, bytes32(tokenId), 1);
out.appendNonZeroBalance(c0.asset, 0, refund0);
out.appendNonZeroBalance(c1.asset, 0, refund1);
```

---

### `AddLiquidityFromBalancesToBalances`

Same as the custody variant, but inputs are `balance(...)` blocks.

```solidity
function addLiquidityFromBalancesToBalances(
    bytes32 account,
    DataPairRef memory rawBalances,
    DataRef memory rawRoute,
    Writer memory out
) internal virtual;
```

---

### `RemoveLiquidityFromCustodyToBalances`

Triggered when the state contains a single `custody(...)` block holding an LP position NFT. Called once per custody.

**Hook signature** (from [contracts/commands/Liquidity.sol](../contracts/commands/Liquidity.sol)):

```solidity
function removeLiquidityFromCustodyToBalances(
    bytes32 account,
    HostAmount memory custody,
    DataRef memory rawRoute,
    Writer memory out
) internal virtual;
```

| Parameter        | Type      | Description                                                         |
| ---------------- | --------- | ------------------------------------------------------------------- |
| `custody.asset`  | `bytes32` | Fastish asset ID representing the position-manager ERC-721 collection |
| `custody.meta`   | `bytes32` | ERC-721 `tokenId`                                                    |
| `custody.amount` | `uint`    | Ownership count, normally `1`                                        |
| `rawRoute`       | `DataRef` | Route block for liquidity to burn and minimum token outputs          |
| `out`            | `Writer`  | Append up to 2 balance blocks (token0 and token1 received)           |

---

### `RemoveLiquidityFromBalanceToBalances`

Same as the custody variant, but the LP position is represented as a `balance(...)` block.

---

## Key helper reference

| Call                                     | Returns                                      | Source                                         |
| ---------------------------------------- | -------------------------------------------- | ---------------------------------------------- |
| `rawRoute.innerMinimum()`                | `(bytes32 asset, bytes32 meta, uint amount)` | [Data.sol](../contracts/blocks/Data.sol)       |
| `rawRoute.innerQuantity()`               | `uint amount`                                | [Data.sol](../contracts/blocks/Data.sol)       |
| `ref.expectMinimum(asset, meta)`         | `uint amount`                                | [Data.sol](../contracts/blocks/Data.sol)       |
| `rawCustodies.a.expectCustody(host)`     | `AssetAmount`                                | [Data.sol](../contracts/blocks/Data.sol)       |
| `rawCustodies.b.expectCustody(host)`     | `AssetAmount`                                | [Data.sol](../contracts/blocks/Data.sol)       |
| `rawBalances.a.toBalanceValue()`         | `AssetAmount`                                | [Data.sol](../contracts/blocks/Data.sol)       |
| `rawBalances.b.toBalanceValue()`         | `AssetAmount`                                | [Data.sol](../contracts/blocks/Data.sol)       |
| `out.appendBalance(AssetAmount)`         | -                                            | [Writers.sol](../contracts/blocks/Writers.sol) |
| `out.appendBalance(asset, meta, amount)` | -                                            | [Writers.sol](../contracts/blocks/Writers.sol) |
| `out.appendNonZeroBalance(...)`          | -                                            | [Writers.sol](../contracts/blocks/Writers.sol) |
| `Assets.toERC20Address(asset)`           | `address`                                    | [Utils.sol](../contracts/Utils.sol)            |
| `Assets.toErc721Asset(issuer)`           | `bytes32`                                    | [Utils.sol](../contracts/Utils.sol)            |

---

## Complete host example

This version is a general wrapper, not a single-pool strategy wrapper. It stores only the router and position manager. The specific fee tier, tick range, and minimums are decoded per call from `rawRoute`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Host} from "../contracts/Core.sol";
import {
    SwapExactCustodyToBalance,
    AddLiquidityFromCustodiesToBalances,
    RemoveLiquidityFromCustodyToBalances
} from "../contracts/Commands.sol";
import {Data, DataRef, DataPairRef, AssetAmount, HostAmount, Writers, Writer} from "../contracts/Blocks.sol";
import {Assets} from "../contracts/Utils.sol";

using Data for DataRef;
using Writers for Writer;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        returns (uint amountOut);
}

interface IERC20Minimal {
    function approve(address spender, uint amount) external returns (bool);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(MintParams calldata params)
        external
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    function positions(uint tokenId) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint feeGrowthInside0LastX128,
        uint feeGrowthInside1LastX128,
        uint tokensOwed0,
        uint tokensOwed1
    );

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        returns (uint amount0, uint amount1);

    function collect(CollectParams calldata params)
        external
        returns (uint amount0, uint amount1);
}

struct SwapRoute {
    bytes32 assetOut;
    uint24 fee;
    uint minOut;
}

struct MintConfig {
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint amount0Min;
    uint amount1Min;
    uint liquidityMin;
}

struct BurnConfig {
    uint liquidity;
    uint amount0Min;
    uint amount1Min;
}

abstract contract UniswapHost is
    Host,
    SwapExactCustodyToBalance(""),
    AddLiquidityFromCustodiesToBalances("", 30_000),
    RemoveLiquidityFromCustodyToBalances("", 20_000)
{
    ISwapRouter immutable router;
    INonfungiblePositionManager immutable positionManager;
    bytes32 immutable lpTokenAsset;

    constructor(
        address fastish,
        address _router,
        address _positionManager
    ) Host(fastish, 1, "uniswap-v3") {
        router = ISwapRouter(_router);
        positionManager = INonfungiblePositionManager(_positionManager);
        lpTokenAsset = Assets.toErc721Asset(_positionManager);
    }

    // These decode helpers are app-specific. A general wrapper keeps them separate
    // instead of hard-coding one fee tier or one tick range for every call.
    function decodeSwapRoute(DataRef memory rawRoute) internal pure virtual returns (SwapRoute memory);

    function decodeMintConfig(
        DataRef memory rawRoute,
        bytes32 token0Asset,
        bytes32 token1Asset
    ) internal pure virtual returns (MintConfig memory);

    function decodeBurnConfig(
        DataRef memory rawRoute,
        bytes32 token0Asset,
        bytes32 token1Asset
    ) internal pure virtual returns (BurnConfig memory);

    function swapExactCustodyToBalance(
        bytes32,
        HostAmount memory custody,
        DataRef memory rawRoute
    ) internal override returns (AssetAmount memory out) {
        SwapRoute memory route = decodeSwapRoute(rawRoute);

        address tokenIn = Assets.toERC20Address(custody.asset);
        address tokenOut = Assets.toERC20Address(route.assetOut);

        IERC20Minimal(tokenIn).approve(address(router), custody.amount);

        uint amountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: route.fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: custody.amount,
                amountOutMinimum: route.minOut,
                sqrtPriceLimitX96: 0
            })
        );

        return AssetAmount(route.assetOut, 0, amountOut);
    }

    function addLiquidityFromCustodiesToBalances(
        bytes32,
        DataPairRef memory rawCustodies,
        DataRef memory rawRoute,
        Writer memory out
    ) internal override {
        AssetAmount memory c0 = rawCustodies.a.expectCustody(host);
        AssetAmount memory c1 = rawCustodies.b.expectCustody(host);
        MintConfig memory cfg = decodeMintConfig(rawRoute, c0.asset, c1.asset);

        address token0 = Assets.toERC20Address(c0.asset);
        address token1 = Assets.toERC20Address(c1.asset);

        IERC20Minimal(token0).approve(address(positionManager), c0.amount);
        IERC20Minimal(token1).approve(address(positionManager), c1.amount);

        (uint tokenId, uint128 liquidity, uint used0, uint used1) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: cfg.fee,
                tickLower: cfg.tickLower,
                tickUpper: cfg.tickUpper,
                amount0Desired: c0.amount,
                amount1Desired: c1.amount,
                amount0Min: cfg.amount0Min,
                amount1Min: cfg.amount1Min,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        require(liquidity >= cfg.liquidityMin, "insufficient liquidity");

        out.appendBalance(lpTokenAsset, bytes32(tokenId), 1);
        out.appendNonZeroBalance(c0.asset, 0, c0.amount - used0);
        out.appendNonZeroBalance(c1.asset, 0, c1.amount - used1);
    }

    function removeLiquidityFromCustodyToBalances(
        bytes32,
        HostAmount memory custody,
        DataRef memory rawRoute,
        Writer memory out
    ) internal override {
        uint tokenId = uint(custody.meta);
        (, , address token0, address token1, , , , uint128 liveLiquidity, , , , ) = positionManager.positions(tokenId);

        bytes32 token0Asset = Assets.toErc20Asset(token0);
        bytes32 token1Asset = Assets.toErc20Asset(token1);
        BurnConfig memory cfg = decodeBurnConfig(rawRoute, token0Asset, token1Asset);

        require(cfg.liquidity <= liveLiquidity, "insufficient liquidity");

        positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: uint128(cfg.liquidity),
                amount0Min: cfg.amount0Min,
                amount1Min: cfg.amount1Min,
                deadline: block.timestamp
            })
        );

        (uint amount0, uint amount1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        out.appendBalance(token0Asset, 0, amount0);
        out.appendBalance(token1Asset, 0, amount1);
    }
}
```

---

## Constructor reference

| Command                                | Constructor signature                   | Notes                                          |
| -------------------------------------- | --------------------------------------- | ---------------------------------------------- |
| `SwapExactBalanceToBalance`            | `(string maybeRoute)`                   | Pass `""` for no extra route fields            |
| `SwapExactCustodyToBalance`            | `(string maybeRoute)`                   | Pass `""` for no extra route fields            |
| `AddLiquidityFromBalancesToBalances`   | `(string maybeRoute, uint scaledRatio)` | `30_000` if emitting up to 3 balances per pair |
| `AddLiquidityFromCustodiesToBalances`  | `(string maybeRoute, uint scaledRatio)` | `30_000` if emitting up to 3 balances per pair |
| `RemoveLiquidityFromBalanceToBalances` | `(string maybeRoute, uint scaledRatio)` | `20_000` for 2 output balances per input       |
| `RemoveLiquidityFromCustodyToBalances` | `(string maybeRoute, uint scaledRatio)` | `20_000` for 2 output balances per input       |

`scaledRatio` is divided by `10_000` to get the output-to-input block ratio used to pre-allocate the writer buffer.
