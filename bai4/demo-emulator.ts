import {describe, it} from 'vitest';
import * as fc from "fast-check";
import {Emulator, generateEmulatorAccount, Lucid} from "@lucid-evolution/lucid";

describe("Property test: Pay to address with random amounts", () => {
  it("should successfully send random amounts", async () => {
    await fc.assert(fc.asyncProperty(fc.bigInt(1_000_000n, 55_000_000n), async (amount) => {
      // Tạo test account với generateEmulatorAccount helper
      const testAccount = generateEmulatorAccount({
        lovelace: 70_000_000n, // 70 ADA
      });

      // Khởi tạo Emulator với test account
      const emulator = new Emulator([testAccount]);

      // Tạo Lucid instance với emulator và Custom network
      const lucid = await Lucid(emulator, "Custom");
      lucid.selectWallet.fromSeed(testAccount.seedPhrase);

      const recipient = "addr_test1qzd98mcy46084asxzv0dahn5759pmy6hxt2583ek8c2ynka69jeepn77ngfvwrwptye5p8q4rgaqh4xenfhhxfu8w89sxwszc6";

      // Tạo và hoàn thành transaction
      const tx = await lucid
      .newTx()
      .pay.ToAddress(recipient, {lovelace: amount})
      .complete();

      // Ký và submit transaction
      const signedTx = await tx.sign.withWallet().complete();
      const txHash = await signedTx.submit();

      // Simulate block progression
      await emulator.awaitBlock(1);

      console.log("Transaction hash:", txHash);
      return true;
    }), {numRuns: 79});
  }, 60000); // timeout 60 seconds cho test
});