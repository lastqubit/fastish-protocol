import { expect } from "chai";
import { deploy } from "./helpers/setup.js";
import {
  concat,
  encodeAssetBlock,
  encodeResponseBlock,
  pad32,
} from "./helpers/blocks.js";

describe("IsAllowedAsset", () => {
  it("returns one response block for one asset query", async () => {
    const query = await deploy("TestAllowedAssetQuery");
    const asset = await query.allowedAssetId();
    const meta = await query.allowedMeta();

    const result: string = await query["isAllowedAsset(bytes)"].staticCall(
      encodeAssetBlock(asset, meta),
    );

    expect(result).to.equal(encodeResponseBlock(pad32(1n)));
  });

  it("maps multiple asset blocks into matching allowed flags in order", async () => {
    const query = await deploy("TestAllowedAssetQuery");
    const asset = await query.allowedAssetId();
    const meta = await query.allowedMeta();
    const otherAsset = pad32(0xDEADn);
    const otherMeta = pad32(0xBEEFn);

    const request = concat(
      encodeAssetBlock(asset, meta),
      encodeAssetBlock(otherAsset, otherMeta),
    );

    const result: string = await query["isAllowedAsset(bytes)"].staticCall(request);

    expect(result).to.equal(concat(
      encodeResponseBlock(pad32(1n)),
      encodeResponseBlock(pad32(0n)),
    ));
  });
});
