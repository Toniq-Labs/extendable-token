#!/usr/bin/env node


const isLocal = true; // mint locally or on ic
var minterSeed = "your minter seed";

var canisterIdIC = "rrkah-fqaaa-aaaaa-aaaaq-cai";
var canisterIdLocal = "rrkah-fqaaa-aaaaa-aaaaq-cai";

var basePath = "/home/user/projects/collection/"
var assetPathBase = basePath+ "data/assets/";
var thumbsPathBase = basePath +"data/thumbnail/";

require = require('esm-wallaby')(module);
var fetch = require('node-fetch');
var fs = require('fs');
const sharp = require('sharp');
const glob = require("glob");
const extjs = require("./extjs/extjs");
const utils = require("./extjs/utils");
global.fetch = fetch;

const bip39 = require('bip39')
const mime = require('mime');

const Ed25519KeyIdentity = require("@dfinity/identity").Ed25519KeyIdentity;
const HttpAgent = require("@dfinity/agent").HttpAgent;
const Actor = require("@dfinity/agent").Actor;
const Principal = require("@dfinity/principal").Principal;
const V2IDL = require("./v2.did.js").default;
const NFTFACTORY = "bn2nh-jaaaa-aaaam-qapja-cai";
const NFTFACTORY_IDL = ({ IDL }) => {
  const Factory = IDL.Service({
    'createCanister' : IDL.Func([IDL.Text, IDL.Text], [IDL.Principal], []),
  });
  return Factory;
};


const mnemonicToId = (mnemonic) => {
  var seed = bip39.mnemonicToSeedSync(mnemonic);
  seed = Array.from(seed);
  seed = seed.splice(0, 32);
  seed = new Uint8Array(seed);
  return Ed25519KeyIdentity.generate(seed);
}

var id = mnemonicToId(minterSeed);



var API;
if (isLocal)
{
  var agent = new HttpAgent({
    host : "http://localhost:8000",
    identity : id
  });
  agent.fetchRootKey();

  API = Actor.createActor(V2IDL, {
    agent : agent,
    canisterId : canisterIdLocal // your canister id on local network
  });
}
else
{
  API = Actor.createActor(V2IDL, {
    agent : new HttpAgent({
      host : "https://boundary.ic0.app/",
      identity : id
    }),
    canisterId : canisterIdIC
  });
  
}




const CHUNKSIZE = 1900000;

//Internal -> true for thumbnails, goes directly on collection canister. If false, goes to asset canister.
// api -> canister actor
// ah -> asset handle (usually filename without extension)
// filename -> full file name (with extension)
// filepath -> full file path (including filename)

const uploadAsset = async (internal, api, ah, filename, filepath) =>{
  var data = fs.readFileSync(filepath);
  var type = mime.getType(filepath); 
  var pl = [...data];
  await api.ext_assetAdd(ah, type, filename, (internal ? {direct:[]} : {canister:{canister:"",id:0}}), pl.length);
  var numberOfChunks = Math.ceil(pl.length/CHUNKSIZE);
  var c = 0;
  var first = true;
  var total = Math.ceil(pl.length/CHUNKSIZE);
  while (pl.length > CHUNKSIZE) {
    c++;
    await api.ext_assetStream(ah, pl.splice(0, CHUNKSIZE), first);
    if (first) first = false;
  };
  await api.ext_assetStream(ah, pl, first);  
  return true;
}
const removeFilenameExtension = (filename) => {
  return filename.split('.').slice(0, -1).join('.');
};

function shuffle(a) {
  for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

(async () => {

  //loop through all assets, and call upload asset
  var collLen = 1;
  var alreadyMinted = 0;
  var i = -1 + alreadyMinted;
  var toMint = [];
  while (++i < collLen)
  {
    var filename = "" + i + ".png";
    var ahAsset = removeFilenameExtension(filename);
    var ahThumb = ahAsset+"_thumbnail";
    var asset = assetPathBase+filename;
    var thumb = thumbsPathBase + removeFilenameExtension(filename) + ".jpg";

    // await uploadAsset(true, API, ahThumb, filename, thumb)  // upload thumbnail
    
    // await uploadAsset(false, API, ahAsset, filename, asset); // upload image


    // add asset handlers to toMint array
    toMint.push([
      "mintingAddress",
      {
        nonfungible : {
          name : ""+i+"_front",
          asset : ahAsset,
          thumbnail : ahThumb,
          metadata : []
        }
      }
      
    ])

  }

  // mint in the end
  await API.ext_mint(toMint);

})();