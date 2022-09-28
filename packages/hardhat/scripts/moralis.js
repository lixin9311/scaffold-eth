const { ethers } = require("hardhat");
const { utils } = require("ethers");
const watch = require("node-watch");
const { exec } = require("child_process");
const axios = require("axios").default;

var stop;

// var axios = new Axios();

const config = {
  PublisherEndpoint: "http://127.0.0.1:8080",
  APIToken: "xxxx",
};

axios.defaults.baseURL = "http://127.0.0.1:8080";

const run = () => {
  console.log("🛠  Compiling & Deploying...");
  const child = exec("yarn deploy", function (error, stdout, stderr) {
    console.log(stdout);
    if (error) console.error(error);
    if (stderr) console.log(stderr);
    stop();
    moralis();
  });
};


console.log("🔬 Watching Contracts...");
watch("./contracts", { recursive: true }, function (evt, name) {
  console.log("%s changed.", name);
  run();
});

const e = utils.parseEther("1");

async function moralis() {
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const delegatee = accounts[17];
  const admin = accounts[18];

  console.log("🧙‍♂️ simulating moralis cloud functions...");
  const somenft = await ethers.getContract("SomeNFT");
  const somecoin = await ethers.getContract("SomeCoin");
  const sometoken = await ethers.getContract("SomeToken");
  somenft.on("Transfer", (from, to, tokenId, event) => {
    if (from.toLocaleLowerCase() === delegatee.address.toLocaleLowerCase() || to.toLocaleLowerCase() === delegatee.address.toLocaleLowerCase()) {
      const now = new Date();
      const avaxNFTTransferEvent = {
        from_address: from.toLocaleLowerCase(),
        to_address: to.toLocaleLowerCase(),
        block_number: event.blockNumber,
        block_hash: event.blockHash,
        block_timestamp: { iso: now.toISOString() },
        log_index: event.logIndex,
        transaction_hash: event.transactionHash,
        transaction_index: event.transactionIndex,
        token_id: tokenId.toString(),
        token_address: event.address,
        amount: "1",
        transaction_type: "Single",
        confirmed: true,
        objectId: event.transactionHash,
        contract_type: "ERC721",
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
      };
      console.log(axios);
      axios.post(`/delegatee-nfttxn-mock`, avaxNFTTransferEvent, {
        headers: {
          "Authorization": config.APIToken,
        }
      }).catch((reason) => {
        console.error(reason);
      });
    }
    console.log(`SomeNFT Transfer from ${from}, to ${to}, tokenId ${tokenId}`);
  })


  sometoken.on("Transfer", (from, to, amount, event) => {
    if (from.toLocaleLowerCase() === delegatee.address.toLocaleLowerCase() || to.toLocaleLowerCase() === delegatee.address.toLocaleLowerCase()) {
      const now = new Date();
      const avaxTokenTransferEvent = {
        from_address: from.toLocaleLowerCase(),
        to_address: to.toLocaleLowerCase(),
        block_number: event.blockNumber,
        block_hash: event.blockHash,
        block_timestamp: { iso: now.toISOString() },
        log_index: event.logIndex,
        transaction_hash: event.transactionHash,
        transaction_index: event.transactionIndex,
        token_address: event.address,
        value: amount.toString(),
        confirmed: true,
        objectId: event.transactionHash,
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
      };
      axios.post(`/delegatee-tokentxn-mock`, avaxTokenTransferEvent, {
        headers: {
          "Authorization": config.APIToken,
        }
      }).catch((reason) => {
        console.error(reason);
      });
    }
    console.log(`SOT Transfer from ${from}, to ${to}, amount ${utils.formatEther(amount)}`);
  })


  somecoin.on("Transfer", (from, to, amount, event) => {
    if (from.toLocaleLowerCase() === delegatee.address.toLocaleLowerCase() || to.toLocaleLowerCase() === delegatee.address.toLocaleLowerCase()) {
      const now = new Date();
      const avaxTokenTransferEvent = {
        from_address: from.toLocaleLowerCase(),
        to_address: to.toLocaleLowerCase(),
        block_number: event.blockNumber,
        block_hash: event.blockHash,
        block_timestamp: { iso: now.toISOString() },
        log_index: event.logIndex,
        transaction_hash: event.transactionHash,
        transaction_index: event.transactionIndex,
        token_address: event.address,
        value: amount.toString(),
        confirmed: true,
        objectId: event.transactionHash,
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
      };
      axios.post(`/delegatee-tokentxn-mock`, avaxTokenTransferEvent, {
        headers: {
          "Authorization": config.APIToken,
        }
      }).catch((reason) => {
        console.error(reason);
      });
    }
    console.log(`SOC Transfer from ${from}, to ${to}, amount ${utils.formatEther(amount)}`);
  })

  stop = function () {
    console.log("contract updated, stopping old listeners...");
    somenft.removeAllListeners();
    sometoken.removeAllListeners();
    somecoin.removeAllListeners();
  }
}



moralis();
