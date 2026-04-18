import { expect } from "chai";
import { ethers } from "ethers";
import { deploy, getProvider, getSigner } from "./helpers/setup.js";
import {
  concat,
  encodeBalanceBlock,
  encodeQueryBlock,
  encodeUserAccount,
  pad32,
} from "./helpers/blocks.js";

describe("BalancesQuery", () => {
  it("returns a balance block for one ERC-20 query tuple", async () => {
    const query = await deploy("TestBalancesQuery");
    const account = await getSigner(1);
    const accountId = encodeUserAccount(await account.getAddress());
    const tokenAsset = await query.tokenAsset();
    const meta = ethers.ZeroHash;

    await query.mint(await account.getAddress(), 123n);

    const request = encodeQueryBlock(concat(accountId, pad32(tokenAsset), pad32(meta)));
    const result: string = await query.getBalances.staticCall(request);

    expect(result).to.equal(encodeBalanceBlock(tokenAsset, meta, 123n));
  });

  it("maps multiple query blocks into matching balance blocks in order", async () => {
    const query = await deploy("TestBalancesQuery");
    const provider = await getProvider();
    const account = await getSigner(1);
    const accountAddr = await account.getAddress();
    const accountId = encodeUserAccount(accountAddr);
    const tokenAsset = await query.tokenAsset();
    const valueAsset = await query.valueAssetId();
    const meta = ethers.ZeroHash;

    await query.mint(accountAddr, 456n);
    const nativeBalance = await provider.getBalance(accountAddr);

    const request = concat(
      encodeQueryBlock(concat(accountId, pad32(tokenAsset), pad32(meta))),
      encodeQueryBlock(concat(accountId, pad32(valueAsset), pad32(meta))),
    );

    const result: string = await query.getBalances.staticCall(request);

    expect(result).to.equal(concat(
      encodeBalanceBlock(tokenAsset, meta, 456n),
      encodeBalanceBlock(valueAsset, meta, nativeBalance),
    ));
  });
});
