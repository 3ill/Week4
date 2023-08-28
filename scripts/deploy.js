const { ethers } = require('hardhat');

const main = async () => {
  const Crowdfunding = await ethers.getContractFactory('Crowdfunding');
  const crowdfunding = await Crowdfunding.deploy();

  await crowdfunding.waitForDeployment();

  console.log(`Contract delpoyed at ${await crowdfunding.getAddress()}`);
};

main().catch((error) => {
  process.exitCode = 1;
  console.error(error, 'An Error occurred');
});
