import { defineConfig } from "hardhat/config";
import hardhatMocha from "@nomicfoundation/hardhat-mocha";

export default defineConfig({
  plugins: [hardhatMocha],
  solidity: {
    version: "0.8.33",
  },
  test: {
    mocha: {
      require: ["./test/helpers/matchers.ts"],
    },
  },
});
