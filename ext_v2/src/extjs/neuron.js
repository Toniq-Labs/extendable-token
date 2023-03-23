/* global BigInt */
import { Principal } from "@dfinity/agent";  
import { GOVERNANCE_CANISTER_ID, LEDGER_CANISTER_ID, rosettaApi, amountToBigInt, principalToAccountIdentifier, toHexString, to32bits, getSubAccountArray } from "./utils.js";
import extjs from "./extjs.js";
import { sha256 as jsSha256 } from 'js-sha256';
import { blobFromUint8Array } from '@dfinity/agent/lib/esm/types';
//import {StoicIdentity} from "./identity.js";

const topics = [
  ["All topics", 0],
  ["Neuron Management", 1],
  ["Exchange Rate", 2],
  ["Network Economics", 3],
  ["Governance", 4],
  ["Node Admin", 5],
  ["Participant Management", 6],
  ["Subnet Management", 7],
  ["Network Canister Management", 8],
  ["KYC", 9],
  ["Node Proivuder Rewards", 10],
];
const sha256 = (data) => {
    const shaObj = jsSha256.create();
    shaObj.update(data);
    return blobFromUint8Array(new Uint8Array(shaObj.array()));
}
const getStakingAddress = (principal, nonce) => {
  if (typeof nonce == 'string') nonce = Buffer(nonce);
  if (nonce.length > 8) return false;
  const array = new Uint8Array([
      [0x0c],
      ...Buffer("neuron-stake"),
      ...Principal.fromText(principal).toBlob(),
      ...nonce
  ]);
  const hash = sha256(array);
  return principalToAccountIdentifier(GOVERNANCE_CANISTER_ID, Array.from(hash));
}

class ICNeuron {
  #api = false;
  #identity = false;
  neuronid = 0;
  id = 0;
  data = {};
  constructor(neuronid, neurondata, identity) {
    if (!neuronid) throw new Error("NeuronID is required");
    if (!identity) throw new Error("Identity is required");
    this.neuronid = neuronid;
    this.id = neuronid.toString();
    this.#identity = identity;
    this.data = neurondata;
    this.#api = extjs.connect("https://boundary.ic0.app/", this.#identity).canister(GOVERNANCE_CANISTER_ID);
  };
  async topup(from_sa, amount) {
    var args = {
      "from_subaccount" : [getSubAccountArray(from_sa ?? 0)], 
      "to" : this.data.address,
      "amount" : { "e8s" : amountToBigInt(amount, 8) },
      "fee" : { "e8s" : 10000n }, 
      "memo" : 0, 
      "created_at_time" : []
    }
    await extjs.connect("https://boundary.ic0.app/", this.#identity).canister(LEDGER_CANISTER_ID).send_dfx(args);
    var memo = await rosettaApi.getTransactionsByAccount(this.data.address).then(rs => Number(rs.pop().memo));
    args = {
      controller : [], 
      memo : memo
    };
    await extjs.connect("https://boundary.ic0.app/", this.#identity).canister(GOVERNANCE_CANISTER_ID).claim_or_refresh_neuron_from_account(args);
    return true;
  }
  async update() {
    this.data = await NeuronManager.getData(this.neuronid, this.#identity);
    return this.data;
  };
  async spawn() { //TODO TEST
    var commandArgs = {
      new_controller  : []
    };
    var cmdId = "Spawn";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async split(amount) { //TODO TEST
    var commandArgs = {
      amount_e8s   : BigInt(amount) * BigInt(10**8)
    };
    var cmdId = "Split";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async follow(topic, neuron) {
    var commandArgs = {
      topic : BigInt(topic),
      "followees" : [{id : BigInt(neuron)}]
    };
    var cmdId = "Follow";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async startDissolving() {
    var commandArgs = {
      operation  : [{"StartDissolving" : {}}]
    };
    var cmdId = "Configure";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async stopDissolving() {
    var commandArgs = {
      operation  : [{"StopDissolving" : {}}]
    };
    var cmdId = "Configure";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async increaseDissolveDelay(seconds) {
    var commandArgs = {
      operation  : [{"IncreaseDissolveDelay" : {
        "additional_dissolve_delay_seconds" : BigInt(seconds)
      }}]
    };
    var cmdId = "Configure";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async setDissolveTime(seconds) {//not really needed
    var commandArgs = {
      operation  : [{"SetDissolveTimestamp" : {
        dissolve_timestamp_seconds  : BigInt(seconds)
      }}]
    };
    var cmdId = "Configure";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
  async disburse() {
    var commandArgs = {
      to_account   : [],
      amount   : []
    };
    var cmdId = "Disburse";
    var cmdBody = {};
    cmdBody[cmdId] = commandArgs;
    var res = await this.#api.manage_neuron({
      id : [{id : this.neuronid}],
      command : [cmdBody]
    });
    if (res.command[0].hasOwnProperty('Error')) throw new Error("Error:" + JSON.stringify(res.command[0].Error.error_message));
    else return res.command[0][cmdId];
  };
};
const NeuronManager = {
  scan : async (id) => {
    var ns = await extjs.connect("https://boundary.ic0.app/", id).canister(GOVERNANCE_CANISTER_ID).list_neurons({
      include_neurons_readable_by_caller  : true,
      neuron_ids : []
    })
    var rns = []
    ns.full_neurons.map((n, i) => {
      var nid = n.id[0].id;
      var nn = ns.neuron_infos.find(e => {
        return (e[0] === nid);
      })[1];
      var ndata = {
        age : nn.age_seconds,
        created : nn.created_timestamp_seconds,
        dissolve_delay : nn.dissolve_delay_seconds,
        retreived : nn.retrieved_at_timestamp_seconds,
        state : nn.state,
        voting_power : nn.voting_power,
        stake : n.cached_neuron_stake_e8s,
        maturity : n.maturity_e8s_equivalent,
        fees : n.neuron_fees_e8s,
        operator : true,
        address : principalToAccountIdentifier(GOVERNANCE_CANISTER_ID, n.account),
      };
      rns.push(new ICNeuron(nid, ndata, id));
      return true;
    });
    return rns;
  },
  create : async (amount, id, sa) => {
    var index = Math.floor(Math.random()*4294967296);
    if (amount < 1) return false;
    var principal = id.getPrincipal();
    var nonce = Array(4).fill(0).concat(to32bits(index));
    var memo = BigInt("0x"+toHexString(nonce));
    var stakingTo = getStakingAddress(principal.toText(), nonce);
    var args = {
      "from_subaccount" : [getSubAccountArray(sa ?? 0)], 
      "to" : stakingTo,
      "amount" : { "e8s" : amountToBigInt(amount, 8) },
      "fee" : { "e8s" : 10000n }, 
      "memo" : Number(memo), 
      "created_at_time" : []
    }
    
    //Call
    await extjs.connect("https://boundary.ic0.app/", id).canister(LEDGER_CANISTER_ID).send_dfx(args);
    args = {
      controller : [principal], 
      memo : Number(memo)
    };

    //Call
    var nd = await extjs.connect("https://boundary.ic0.app/", id).canister(GOVERNANCE_CANISTER_ID).claim_or_refresh_neuron_from_account(args);
    if (nd.result[0].hasOwnProperty("Error")) {
      throw new Error("Error: " + JSON.stringify(nd.result[0].Error));
    }
    var neuronid = nd.result[0].NeuronId.id;
    return await NeuronManager.get(neuronid, id);
  },
  get : async (neuronid, id) => {
    var ndata = await NeuronManager.getData(neuronid, id);
    return new ICNeuron(neuronid, ndata, id);
  },
  getData : async (neuronid, id) => {
    var ns = await extjs.connect("https://boundary.ic0.app/", id).canister(GOVERNANCE_CANISTER_ID).list_neurons({
      neuron_ids : [neuronid],
      include_neurons_readable_by_caller  : false,
    });
    var ndata = {
      operator : false,
      age : ns.neuron_infos[0][1].age_seconds,
      created : ns.neuron_infos[0][1].created_timestamp_seconds,
      dissolve_delay : ns.neuron_infos[0][1].dissolve_delay_seconds,
      retreived : ns.neuron_infos[0][1].retrieved_at_timestamp_seconds,
      state : ns.neuron_infos[0][1].state,
      voting_power : ns.neuron_infos[0][1].voting_power
    };
    if (ns.full_neurons.length === 1) {
      ndata['stake'] = ns.full_neurons[0].cached_neuron_stake_e8s;
      ndata['maturity'] = ns.full_neurons[0].maturity_e8s_equivalent;
      ndata['fees'] = ns.full_neurons[0].neuron_fees_e8s;
      ndata['operator'] = true;
      ndata['address'] = principalToAccountIdentifier(GOVERNANCE_CANISTER_ID, ns.full_neurons[0].account);
    }
    return ndata;
  },
  topics : topics
};
export default NeuronManager;

