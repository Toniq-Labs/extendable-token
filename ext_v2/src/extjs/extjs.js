/* global BigInt */
import { Actor, HttpAgent } from "@dfinity/agent";  
import { Principal } from "@dfinity/principal";
const bip39 = require('bip39')
import { LEDGER_CANISTER_ID, GOVERNANCE_CANISTER_ID, NNS_CANISTER_ID, CYCLES_MINTING_CANISTER_ID, getCyclesTopupSubAccount, rosettaApi, principalToAccountIdentifier, toHexString, from32bits, to32bits, isHex, getSubAccountArray, fromHexString, mnemonicToId } from "./utils.js";

import ledgerIDL from './candid/ledger.did.js';
import governanceIDL from './candid/governance.did.js';
import nnsIDL from './candid/nns.did.js';
import hzldIDL from './candid/hzld.did.js'; //hardcode to hzld...
import extIDL from './candid/ext.did.js';

const constructUser = (u) => {
  if (isHex(u) && u.length === 64) {
    return { 'address' : u };
  } else {
    return { 'principal' : Principal.fromText(u) };
  };
};
const tokenIdentifier = (principal, index) => {
  const padding = Buffer("\x0Atid");
  const array = new Uint8Array([
      ...padding,
      ...Principal.fromText(principal).toUint8Array(),
      ...to32bits(index),
  ]);
  return Principal.fromUint8Array(array).toText();
};
const decodeTokenId = (tid) => {
  var p = [...Principal.fromText(tid).toUint8Array()];
  var padding = p.splice(0, 4);
  if (toHexString(padding) !== toHexString(Buffer("\x0Atid"))) {
    return {
      index : 0,
      canister : tid,
      token : tokenIdentifier(tid, 0)
    };
  } else {
    return {
      index : from32bits(p.splice(-4)), 
      canister : Principal.fromUint8Array(p).toText(),
      token : tid
    };
  }
};



//Preload IDLS against a common name
const _preloadedIdls = {
  'governance' : governanceIDL,
  'ledger' : ledgerIDL,
  'hzld' : hzldIDL,
  'nns' : nnsIDL,
  'ext' : extIDL,
  'default' : extIDL,
};

class ExtConnection {
  //map known canisters to preloaded IDLs
  _mapIdls = {
    [LEDGER_CANISTER_ID] : _preloadedIdls['ledger'],
    [GOVERNANCE_CANISTER_ID] : _preloadedIdls['governance'],
    [NNS_CANISTER_ID] : _preloadedIdls['nns'],
    "qz7gu-giaaa-aaaaf-qaaka-cai" : _preloadedIdls['hzld'],
  };
  _metadata = {
    [LEDGER_CANISTER_ID] : {
      name : "ICP",
      symbol : "ICP",
      decimals : 8,
      type : 'fungible',
    },
    "qz7gu-giaaa-aaaaf-qaaka-cai" : {
      name : "HZLD",
      symbol : "HZLD",
      decimals : 0,
      type : 'fungible',
    },
  };
  _identity = false;//new AnonymousIdentity();
  _host = false;
  _agent = false;
  _canisters = {};
  
  constructor(host, identity) {
    if (identity) this._identity = identity;
    if (host) this._host = host;
    this._makeAgent();
  }
  idl(canister, idl) {
    //Map a canister to a preloaded idl
    this._mapIdls[canister] = idl;
    return this;
  };
  setIdentity(identity) {
    if (identity) this._identity = identity;
    else this._identity = false;
    this._makeAgent();
    return this;
  }
  setHost(host) {
    if (host) this._host = host;
    else this._host = false;
    this._makeAgent();
    return this;
  }
  canister(cid, idl) {
    if (!idl){
      if (this._mapIdls.hasOwnProperty(cid)) {
        idl = this._mapIdls[cid];
      } else {
        //Resort to default IDLS
        //todo: Look into loading IDLs on the fly
        idl = _preloadedIdls['default'];
      }
    } else if (typeof idl == 'string') {
      if (_preloadedIdls.hasOwnProperty(idl)) {
        idl = _preloadedIdls[idl];
      } else {
        throw new Error(idl + " is not a preloaded IDL");
      }
    }
    if (!this._canisters.hasOwnProperty(cid)){
      this._canisters[cid] = Actor.createActor(idl, {agent : this._agent, canisterId : cid});
    }
    return this._canisters[cid];
  }
  token(tid, idl) {
    if (!tid) tid = LEDGER_CANISTER_ID;//defaults to ledger
    var tokenObj = decodeTokenId(tid);
    if (!idl) {
      if (this._mapIdls.hasOwnProperty(tokenObj.canister)) idl = this._mapIdls[tokenObj.canister];
      else idl = _preloadedIdls['ext']; //ext is our token default...
    }
    var api = this.canister(tokenObj.canister, idl);
    return {
      call : api,
      fee : () => {
        return new Promise((resolve, reject) => {
          switch(tokenObj.canister) {
            case LEDGER_CANISTER_ID:
              resolve(10000);
            break;
            case "qz7gu-giaaa-aaaaf-qaaka-cai":
              resolve(1);
            break;
            default:
              //TODO compute fees
              resolve(0);
            break;
          }
        });
      },
      getMetadata : () => {
        return new Promise((resolve, reject) => {
          if (this._metadata.hasOwnProperty(tokenObj.canister)) {
            resolve(this._metadata[tokenObj.canister]);
          } else {
            switch(tokenObj.canister) {
              default:
                api.metadata(tokenObj.token).then(r => {
                  if (typeof r.ok != 'undefined') {
                    if (typeof r.ok.fungible != 'undefined') {
                      resolve({
                        name : r.ok.fungible.name,
                        symbol : r.ok.fungible.symbol,
                        decimals : r.ok.fungible.decimals,
                        metadata : r.ok.fungible.metadata,
                        type : 'fungible'
                      });
                    } else {
                      resolve({
                        metadata : r.ok.nonfungible.metadata,
                        type : 'nonfungible'
                      });
                    }
                  } else if (typeof r.err != 'undefined') reject(r.err)
                  else reject(r);
                }).catch(reject);
              break;
            }
          }
        });
      },
      getBearer : () => {
        return new Promise((resolve, reject) => {
          api.bearer(tokenObj.token).then(r => {
            if (typeof r.ok != 'undefined') resolve(r.ok)
            else if (typeof r.err != 'undefined') reject(r.err)
            else reject(r);
          }).catch(reject);    
        });
      },
      getBalance : (address, princpal) => {
        return new Promise((resolve, reject) => {
          var args;
          switch(tokenObj.canister) {
            case LEDGER_CANISTER_ID:
              rosettaApi.getAccountBalance(address).then(b => {       
                resolve(b)
              });
            break;
            case "qz7gu-giaaa-aaaaf-qaaka-cai":
              args = {
                "user" : Principal.fromText(princpal)
              };
              api.getBalanceInsecure(args).then(b => {
                var bal = b.length === 0 ? 0 : b[0];
                resolve(bal);
              }).catch(reject);
            break;
            default:
              args = {
                "user" : constructUser(address),
                'token' : tokenObj.token
              };
              api.balance(args).then(r => {
                if (typeof r.ok != 'undefined') resolve(r.ok)
                else if (typeof r.err != 'undefined') reject(r.err)
                else reject(r);
              }).catch(reject);            
            break;
          }
        });
      },
      getTransactions : (address, princpal) => {
        return new Promise((resolve, reject) => {
          switch(tokenObj.canister) {
            case LEDGER_CANISTER_ID:
              rosettaApi.getTransactionsByAccount(address).then(ts => {    
                if (!Array.isArray(ts)) resolve([]);
                var _ts = [];
                ts.map(_t => {
                  if (_t.type !== "TRANSACTION") return false;
                  if (_t.status !== "COMPLETED") return false;
                  _ts.push({
                    from : _t.account1Address,
                    to :  _t.account2Address,
                    amount : Number(_t.amount)/(10**8),
                    fee : Number(_t.fee)/(10**8),
                    hash : _t.hash,
                    timestamp : _t.timestamp,
                    memo : Number(_t.memo),
                  });
                  return true;
                });
                resolve(_ts);
              }).catch(reject);
            break;
            case "qz7gu-giaaa-aaaaf-qaaka-cai":
            default:
              resolve([]);         
            break;
          }
        });
      },
      /*
        from_principal = principal of account as text
        from_sa = subaccount (to produce hex address). null/0 default as number
        to_user = valid User (address or principal) as text
        amount = valid amount as BigInt
        fee = valid fee as BigInt
        memo = data to be sent as text/hex/number
        notify = if we need to notify TODO
      */
      transfer : (from_principal, from_sa, to_user, amount, fee, memo, notify) => {
        return new Promise((resolve, reject) => {
          var args;
          switch(tokenObj.canister) {
            case LEDGER_CANISTER_ID:
              args = {
                "from_subaccount" : [getSubAccountArray(from_sa ?? 0)], 
                "to" : to_user, //Should be an address
                "amount" : { "e8s" : amount },
                "fee" : { "e8s" : fee }, 
                "memo" : memo ? Number(BigInt(memo)) : 0, 
                "created_at_time" : []
              };
              api.send_dfx(args).then(bh => {
                resolve(true);
              }).catch(reject);
              //Notify here
            break;
            case "qz7gu-giaaa-aaaaf-qaaka-cai":
              args = {
                "to" : Principal.fromText(to_user), 
                "metadata" : [],
                "from" : Principal.fromText(from_principal),
                "amount" : amount
              };
              api.transfer(args).then(b => {
                if (typeof b.ok != 'undefined') {          
                  resolve(true);
                } else {
                  reject(JSON.stringify(b.err));
                }
              }).catch(reject);
            break;
            default:
              args = {
                'token' : tid,
                'from' : { 'address' : principalToAccountIdentifier(from_principal, from_sa ?? 0) },
                'subaccount' : [getSubAccountArray(from_sa ?? 0)],
                'to' : constructUser(to_user),
                'amount' : amount,
                'fee' : fee,
                'memo' : fromHexString(memo),
                'notify' : notify
              };
              api.transfer(args).then(b => {
                if (typeof b.ok != 'undefined') {
                  resolve(true);
                } else {
                  reject(JSON.stringify(b.err));
                }
              }).catch(reject);
            break;
          }
        });
      },
      mintCycles : (from_principal, from_sa, canister, amount, fee) => {
        return new Promise((resolve, reject) => {
          switch(tokenObj.canister) {
            case LEDGER_CANISTER_ID:
              var _to_sub = getCyclesTopupSubAccount(canister);
              var _to = principalToAccountIdentifier(CYCLES_MINTING_CANISTER_ID, _to_sub);
              var args = {
                "from_subaccount" : [getSubAccountArray(from_sa ?? 0)], 
                "to" : _to, 
                "fee" : { "e8s" : fee }, 
                "memo" : Number(BigInt("0x50555054")), 
                "created_at_time" : [], 
                "amount" : { "e8s" : amount }
              };
              api.send_dfx(args).then(block => {
                var args = {
                  "block_height" : block,
                  "max_fee": {e8s: fee},
                  "from_subaccount": [getSubAccountArray(from_sa ?? 0)],
                  "to_subaccount": [getSubAccountArray(_to_sub)],
                  "to_canister": Principal.fromText(CYCLES_MINTING_CANISTER_ID)
                };
                api.notify_dfx(args).then(resolve).catch(reject);
              }).catch(reject);
            break;
            case "5ymop-yyaaa-aaaah-qaa4q-cai":
              reject("WIP");
            break;
            default:
              reject("Cycle topup is not supported by this token");
            break;
          }
        });
      }
    };
  }
 
  _makeAgent() {
    var args = {};
    if (this._identity) args['identity'] = this._identity;
    if (this._host) args['host'] = this._host;
    this._agent = new HttpAgent(args);
  };
};

const extjs = {
  connect : (host, identity) => new ExtConnection(host ?? "https://boundary.ic0.app/", identity),
  decodeTokenId : decodeTokenId,
  encodeTokenId : tokenIdentifier,
  constructUser : constructUser,
  principalToAccountIdentifier : principalToAccountIdentifier,
  fromHexString : fromHexString,
  toHexString : toHexString,
  mnemonicToId : mnemonicToId,
  generateMnemonic : bip39.generateMnemonic,
};
export default extjs;