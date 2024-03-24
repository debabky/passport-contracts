import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { Registration } from "@ethers-v6";

describe("Registration", () => {
  const reverter = new Reverter();

  let registration: Registration;

  before("setup", async () => {
    const Registration = await ethers.getContractFactory("Registration");

    registration = await Registration.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);
});
