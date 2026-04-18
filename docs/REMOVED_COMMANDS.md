# Removed Command Families

These built-in abstract command families were removed in favor of writing
custom concrete commands directly on top of the shared protocol primitives.

- `borrow`
- `swap`
- `mint`
- `reclaim`
- `redeem`
- `repay`
- `stake`
- `unstake`
- `liquidate`
- `add liquidity`
- `remove liquidity`

The old generic bases encoded combinations like source state, output shape, and
loop behavior. That logic is now expected to live in concrete commands instead.
