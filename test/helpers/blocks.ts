import { ethers } from "ethers";

// Block key derivation: bytes4(keccak256(schema))
export function blockKey(schema: string): string {
  return ethers.dataSlice(ethers.id(schema), 0, 4);
}

// Known block keys
export const Keys = {
  AMOUNT: blockKey("amount(bytes32 asset, bytes32 meta, uint amount)"),
  BALANCE: blockKey("balance(bytes32 asset, bytes32 meta, uint amount)"),
  CUSTODY: blockKey("custody(uint host, bytes32 asset, bytes32 meta, uint amount)"),
  RECIPIENT: blockKey("recipient(bytes32 account)"),
  NODE: blockKey("node(uint id)"),
  FUNDING: blockKey("funding(uint host, uint amount)"),
  ASSET: blockKey("asset(bytes32 asset, bytes32 meta)"),
  ALLOCATION: blockKey("allocation(uint host, bytes32 asset, bytes32 meta, uint amount)"),
  QUANTITY: blockKey("quantity(uint amount)"),
  STEP: blockKey("step(uint target, uint value, bytes request)"),
  TX: blockKey("tx(bytes32 from, bytes32 to, bytes32 asset, bytes32 meta, uint amount)"),
  MINIMUM: blockKey("minimum(bytes32 asset, bytes32 meta, uint amount)"),
  MAXIMUM: blockKey("maximum(bytes32 asset, bytes32 meta, uint amount)"),
  AUTH: blockKey("auth(uint cid, uint deadline, bytes proof)"),
  BOUNTY: blockKey("bounty(uint amount, bytes32 relayer)"),
  ROUTE: blockKey("route(bytes data)"),
} as const;

// Pad a bigint or hex string to 32 bytes
export function pad32(value: bigint | string): string {
  if (typeof value === "bigint") {
    return ethers.zeroPadValue(ethers.toBeHex(value), 32);
  }
  return ethers.zeroPadValue(value, 32);
}

// Encode a 4-byte big-endian uint32
function encodeUint32(value: number): string {
  return ethers.toBeHex(value, 4);
}

// Build a block header + payload
function block(key: string, payload: string): string {
  const payloadBytes = ethers.getBytes(payload);
  const selfLen = payloadBytes.length;
  const totalLen = selfLen; // no children
  return ethers.concat([key, encodeUint32(selfLen), encodeUint32(totalLen), payload]);
}

// Build a block with children
function blockWithChildren(key: string, payload: string, children: string): string {
  const payloadBytes = ethers.getBytes(payload);
  const childrenBytes = ethers.getBytes(children);
  const selfLen = payloadBytes.length;
  const totalLen = selfLen + childrenBytes.length;
  return ethers.concat([key, encodeUint32(selfLen), encodeUint32(totalLen), payload, children]);
}

export function encodeAmountBlock(asset: string, meta: string, amount: bigint): string {
  return block(Keys.AMOUNT, ethers.concat([pad32(asset), pad32(meta), pad32(amount)]));
}

export function encodeAmountBlockWithNode(asset: string, meta: string, amount: bigint, nodeId: bigint): string {
  return blockWithChildren(Keys.AMOUNT, ethers.concat([pad32(asset), pad32(meta), pad32(amount)]), encodeNodeBlock(nodeId));
}

export function encodeAmountBlockWithRecipient(asset: string, meta: string, amount: bigint, recipient: string): string {
  return blockWithChildren(Keys.AMOUNT, ethers.concat([pad32(asset), pad32(meta), pad32(amount)]), encodeRecipientBlock(recipient));
}

export function encodeBalanceBlock(asset: string, meta: string, amount: bigint): string {
  return block(Keys.BALANCE, ethers.concat([pad32(asset), pad32(meta), pad32(amount)]));
}

export function encodeCustodyBlock(host: bigint, asset: string, meta: string, amount: bigint): string {
  return block(Keys.CUSTODY, ethers.concat([pad32(host), pad32(asset), pad32(meta), pad32(amount)]));
}

export function encodeRecipientBlock(account: string): string {
  return block(Keys.RECIPIENT, pad32(account));
}

export function encodeNodeBlock(id: bigint): string {
  return block(Keys.NODE, pad32(id));
}

export function encodeFundingBlock(host: bigint, amount: bigint): string {
  return block(Keys.FUNDING, ethers.concat([pad32(host), pad32(amount)]));
}

export function encodeAssetBlock(asset: string, meta: string): string {
  return block(Keys.ASSET, ethers.concat([pad32(asset), pad32(meta)]));
}

export function encodeQuantityBlock(amount: bigint): string {
  return block(Keys.QUANTITY, pad32(amount));
}

export function encodeAllocationBlock(host: bigint, asset: string, meta: string, amount: bigint): string {
  return block(Keys.ALLOCATION, ethers.concat([pad32(host), pad32(asset), pad32(meta), pad32(amount)]));
}

export function encodeTxBlock(from: string, to: string, asset: string, meta: string, amount: bigint): string {
  return block(Keys.TX, ethers.concat([pad32(from), pad32(to), pad32(asset), pad32(meta), pad32(amount)]));
}

export function encodeStepBlock(target: bigint, value: bigint, request: string): string {
  return block(Keys.STEP, ethers.concat([pad32(target), pad32(value), request]));
}

export function encodeRouteBlock(data: string): string {
  return block(Keys.ROUTE, data);
}

export function encodeRouteBlockWithAmount(data: string, asset: string, meta: string, amount: bigint): string {
  return blockWithChildren(Keys.ROUTE, data, encodeAmountBlock(asset, meta, amount));
}

export function encodeRouteBlockWithMinimum(data: string, asset: string, meta: string, amount: bigint): string {
  return blockWithChildren(Keys.ROUTE, data, encodeMinimumBlock(asset, meta, amount));
}

export function encodeAuthBlock(cid: bigint, deadline: bigint, proof: string): string {
  return block(Keys.AUTH, ethers.concat([pad32(cid), pad32(deadline), proof]));
}

export function encodeMinimumBlock(asset: string, meta: string, amount: bigint): string {
  return block(Keys.MINIMUM, ethers.concat([pad32(asset), pad32(meta), pad32(amount)]));
}

export function encodeMaximumBlock(asset: string, meta: string, amount: bigint): string {
  return block(Keys.MAXIMUM, ethers.concat([pad32(asset), pad32(meta), pad32(amount)]));
}

export function concat(...parts: string[]): string {
  return ethers.concat(parts);
}

// Command args suffix appended when computing command selectors
const COMMAND_ARGS = "((uint256,bytes32,bytes,bytes))";

export function commandSelector(name: string): string {
  return ethers.dataSlice(ethers.id(name + COMMAND_ARGS), 0, 4);
}
