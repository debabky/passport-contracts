import { ethers } from "hardhat";
import { Deployer } from "@solarity/hardhat-migrate";
import { Registration__factory } from "@ethers-v6";

export = async (deployer: Deployer) => {
  const registration = await deployer.deploy(Registration__factory);

  await registration.__Registration_init(
    80,
    ethers.hexlify(ethers.randomBytes(20)),
    ethers.hexlify(ethers.randomBytes(32)),
  );
};
