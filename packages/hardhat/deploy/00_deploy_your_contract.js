// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");
const { utils } = require('ethers');
const { flatMap } = require("lodash");

const MINTER_ROLE = utils.keccak256(utils.toUtf8Bytes('MINTER_ROLE'));
const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const accounts = await ethers.getSigners();

  const root = accounts[0];
  const users = accounts.slice(1, 16);
  const delegatee = accounts[17];
  const admin = accounts[18];

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  const deployOptions = {
    from: deployer,
    log: true,
    // waitConfirmations: 5,
    overwrite: false,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    // deterministicDeployment: true,
  };

  await deploy("SomeNFT", deployOptions);

  // Getting a previously deployed contract
  const somenft = await ethers.getContract("SomeNFT", deployer);
  await somenft.deployed();
  console.log('1: SomeNFT logic deployed at', somenft.address);
  try {
    const somenftTx = await somenft.initialize();
    await somenftTx.wait();
    console.log('2: SomeNFT logic inited.');
  } catch (e) {
    if (e.message.includes('contract is already initialized')) {
      console.log('2: SomeNFT has already been inited.');
    } else {
      console.error(e);
      throw e;
    }
  }

  await deploy("SomeCoin", deployOptions);

  // Getting a previously deployed contract
  const somecoin = await ethers.getContract("SomeCoin", deployer);
  await somecoin.deployed();
  console.log('3: Some coin deployed at', somecoin.address);

  try {
    const somecoinTx = await somecoin['initialize()']();
    await somecoinTx.wait();
    console.log('4: Some Coin inited.');
  } catch (e) {
    if (e.message.includes('contract is already initialized')) {
      console.log('4: SOC has already been inited.');
    } else {
      console.error(e);
      throw e;
    }
  }

  await deploy("SomeToken", deployOptions);

  const sometoken = await ethers.getContract("SomeToken", deployer);
  await sometoken.deployed();
  console.log('5: SOT coin deployed at', sometoken.address);

  try {
    const sometokenTx = await sometoken['initialize()']();
    await sometokenTx.wait();
    console.log('6: Some Token inited.');
  } catch (e) {
    if (e.message.includes('contract is already initialized')) {
      console.log('6: SOT has already been inited.');
    } else {
      console.error(e);
      throw e;
    }
  }

  await deploy("Airdrop", {
    from: deployer,
    args: [somenft.address],
    log: true,
    // waitConfirmations: 5,
    overwrite: false,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    // deterministicDeployment: true,
  });

  const airdrop = await ethers.getContract("Airdrop", deployer);
  await airdrop.deployed();
  console.log('5: Airdrop deployed at', airdrop.address);

  // grant minter role
  await (await somenft.grantRole(MINTER_ROLE, admin.address)).wait();
  console.log("SomeNFT minter role granted to", admin.address);
  await (await somenft.grantRole(MINTER_ROLE, airdrop.address)).wait();
  console.log("SomeNFT minter role granted to", airdrop.address);
  await (await somecoin.grantRole(MINTER_ROLE, admin.address)).wait();
  console.log("SOC minter role granted to", admin.address);

  // authorize admin
  await (await somenft.connect(delegatee).setApprovalForAll(admin.address, true)).wait();
  await (await somecoin.connect(delegatee).approve(admin.address, utils.parseEther(`100000000000000`).toHexString())).wait();
  await (await sometoken.connect(delegatee).approve(admin.address, utils.parseEther(`100000000000000`).toHexString())).wait();

  await (await somecoin.mint(delegatee.address, utils.parseEther(`10000`).toHexString())).wait();

  console.log("authroize done");

  tokenIdx = 1000;
  // Issue some tokens & NFTs to predefined users

  airdropData = [];

  for (user of users) {
    try {
      console.log("check NFT owner...");
      const owner = await somenft.ownerOf(tokenIdx);
      console.log("NFTs has already been issues, skip.");
      break;
    } catch (e) { }
    await (await somecoin.mint(user.address, utils.parseEther(`10000`).toHexString())).wait();
    await (await sometoken.transfer(user.address, utils.parseEther(`10000`).toHexString())).wait();
    for (i = 0; i < 10; i++) {
      airdropData.push([user.address, tokenIdx]);
      tokenIdx += 1;
    }
  }

  if (airdropData.length > 0) {
    console.log("airdropping nfts to users...");
    await (await airdrop.batchMint(airdropData)).wait();
    for (record of airdropData) {
      console.log(`${record[0]}: \t ${record[1]}`);
    }
  }



  console.log("======== Summary ========");
  console.log("SomeNFT:\t", somenft.address.toLocaleLowerCase());
  console.log("SomeCoin:\t\t", somecoin.address.toLocaleLowerCase());
  console.log("SomeToken:\t\t", sometoken.address.toLocaleLowerCase());
  console.log("Delegatee:\t", delegatee.address.toLocaleLowerCase());
  console.log("Admin:\t\t", admin.address.toLocaleLowerCase());
  console.log("==========================");
  /*  await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // await yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
  // You don't want to verify on localhost
  // try {
  //   if (chainId !== localChainId) {
  //     await run("verify:verify", {
  //       address: YourContract.address,
  //       contract: "contracts/YourContract.sol:YourContract",
  //       constructorArguments: [],
  //     });
  //   }
  // } catch (error) {
  //   console.error(error);
  // }
};
module.exports.tags = ["SomeNFT", "SomeCoin", "SomeToken", "Airdrop"];

// SomeNFT:         0x5fbdb2315678afecb367f032d93f642f64180aa3
// SomeCoin:        0xdc11f7e700a4c898ae5caddb1082cffa76512add
// SomeToken:       0xdc64a140aa3e981100a9beca4e685f962f0cf6c9
// Delegatee:       0xbda5747bfd65f08deb54cb465eb87d40e51b197e
// Admin:           0xdd2fd4581271e230360230f9337d5c0430bf44c0