import { expect } from "chai";
import { deploy } from "./helpers/setup.js";
import {
  concat,
  encodeAssetBlock,
  encodeResponseBlock,
  pad32,
} from "./helpers/blocks.js";

describe("AssetPosition", () => {
  it("returns one response block for one asset query", async () => {
    const query = await deploy("TestAssetPositionQuery");
    const asset = await query.firstAsset();
    const meta = await query.firstMeta();

    const result: string = await query.getAssetPosition.staticCall(
      encodeAssetBlock(asset, meta),
    );

    expect(result).to.equal(encodeResponseBlock(pad32(11n)));
  });

  it("maps multiple asset blocks into matching response blocks in order", async () => {
    const query = await deploy("TestAssetPositionQuery");
    const firstAsset = await query.firstAsset();
    const firstMeta = await query.firstMeta();
    const secondAsset = await query.secondAsset();
    const secondMeta = await query.secondMeta();

    const request = concat(
      encodeAssetBlock(firstAsset, firstMeta),
      encodeAssetBlock(secondAsset, secondMeta),
    );

    const result: string = await query.getAssetPosition.staticCall(request);

    expect(result).to.equal(concat(
      encodeResponseBlock(pad32(11n)),
      encodeResponseBlock(pad32(22n)),
    ));
  });
});
