import Web3 from "web3";
import District from "./contracts/District";
import DistrictFactory from "./contracts/DistrictFactory";
import ElectionController from "./contracts/ElectionController";
import Shared from "./contracts/Shared";
import VoteToken from "./contracts/VoteToken";
import VoteTokenFactory from "./contracts/VoteTokenFactory";


const options = {
  web3: {
    block: false,
    customProvider: new Web3(window.web3.currentProvider || "ws://localhost:8545"),
  },
  contracts: [District, DistrictFactory, ElectionController,
            Shared, VoteToken, VoteTokenFactory]/*,
  events: {
    SimpleStorage: ["StorageSet"],
  },*/
};

export default options;