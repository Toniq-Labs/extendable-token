import { Ed25519KeyIdentity } from "@dfinity/identity";
import { AuthClient } from "@dfinity/auth-client";
import OpenLogin from "@toruslabs/openlogin";
import { 
  mnemonicToId, 
  validatePrincipal, 
  encrypt, 
  decrypt, 
  fromHexString, 
  bip39 } from "./utils.js";
  
var identities = {};
var openlogin = false;
const oauths = ['google', 'twitter', 'facebook', 'github'];
const loadOpenLogin = async () => {
  if (!openlogin) {
    openlogin = new OpenLogin({
      clientId: "BHGs7-pkZO-KlT_BE6uMGsER2N1PC4-ERfU_c7BKN1szvtUaYFBwZMC2cwk53yIOLhdpaOFz4C55v_NounQBOfU",
      network: "mainnet",
      uxMode : 'popup',
    });
  }
  await openlogin.init();
  return openlogin;
}
const processId = (id, type) => {
  var p = id.getPrincipal().toString();
  identities[p] = id;
  return {
    principal : p,
    type : type
  }
}
const isLoaded = (p) => {
  return (identities.hasOwnProperty(p));
};
const ICIdentity = {
  getIdentity : (principal) => {
    if (!identities.hasOwnProperty(principal)) return false;
    return identities[principal];
  },
  setup : (type, optdata) => {
    return new Promise(async (resolve, reject) => {
      var id;
      switch(type){
        case "ii":
          var auth = await AuthClient.create();
          auth.login({
            identityProvider: "https://identity.ic0.app/",
            onSuccess: async () => {
              id = await auth.getIdentity()
              return resolve(processId(id, type));
            },
            onError : reject
          });
          return;
        case "private":
          localStorage.setItem('_m', optdata.mnemonic);
          id = mnemonicToId(optdata.mnemonic);
          encrypt(optdata.mnemonic, id.getPrincipal().toString(), optdata.password).then(_em => {
            var ems = localStorage.getItem('_em');
            if (!ems) {
              ems = {};
              ems[id.getPrincipal().toString()] = _em;
            } else {
              ems = JSON.parse(ems);
              ems[id.getPrincipal().toString()] = _em;
            }
            localStorage.setItem('_em', JSON.stringify(ems));
            return resolve(processId(id, type));        
          });
          return;
        case "watch":
          return resolve({
            principal : optdata.principal,
            type : type
          });   
        default: break;
      }
        
      if (oauths.indexOf(type) >= 0) {
        const openlogin = await loadOpenLogin();
        if (openlogin.privKey) {
          await openlogin.logout();
        }
        await openlogin.login({
          loginProvider: type,
        });
        id = Ed25519KeyIdentity.generate(new Uint8Array(fromHexString(openlogin.privKey)));
        return resolve(processId(id, type));
      }
      
      return reject("Cannot setup, invalid type: " + type);
    });
  },
  load : (_id) => {
    return new Promise(async (resolve, reject) => {
      var id;
      switch(_id.type){
        case "ii":
          var auth = await AuthClient.create();
          id = await auth.getIdentity();
          if (id.getPrincipal().toString() === '2vxsx-fae') return reject("Not logged in");
          if (id.getPrincipal().toString() !== _id.principal) return reject("Logged in using the incorrect user: " + id.getPrincipal().toString() + " but expecting " + _id.principal);
          return resolve(processId(id, _id.type)); 
        case "private":
          if (!isLoaded(_id.principal)) { 
            var t = localStorage.getItem('_m');
            if (!t){
              return reject("No seed");
            } else {
              var mnemonic = t;
              id = mnemonicToId(mnemonic);
              return resolve(processId(id, _id.type));
            }
          } else {
            return resolve({
              principal : _id.principal,
              type : _id.type
            });
          }
        case "watch":
          return resolve({
            principal : _id.principal,
            type : _id.type
          });   
        default: break;
      }
      if (oauths.indexOf(_id.type) >= 0) {
        const openlogin = await loadOpenLogin();
        if (!openlogin.privKey || openlogin.privKey.length === 0) {
          return reject("Not logged in");
        } else {
          id = Ed25519KeyIdentity.generate(new Uint8Array(fromHexString(openlogin.privKey)));
          if (id.getPrincipal().toString() !== _id.principal) {
            await openlogin.logout();
            return reject("Logged in using the incorrect user " + id.getPrincipal().toString() + " expecting " + _id.principal);
          } else {
            return resolve(processId(id, _id.type)); 
          }
        }
      }
      return reject();
    });
  },
  unlock : (_id, optdata) => {
    return new Promise(async (resolve, reject) => {
      ICIdentity.load(_id).then(resolve).catch(async e => {
        var id;
        switch(_id.type) {
          case "ii":
            var auth = await AuthClient.create();
            auth.login({
              identityProvider: "https://identity.ic0.app/",
              onSuccess: async () => {
                id = await auth.getIdentity()
                if (id.getPrincipal().toString() === '2vxsx-fae') return reject("Not logged in");
                if (id.getPrincipal().toString() !== _id.principal) return reject("Logged in using the incorrect user: " + id.getPrincipal().toString() + " but expecting " + _id.principal);
                return resolve(processId(id, _id.type));
              },
              onError : reject
            });
            return;
          case "private":
            var t = localStorage.getItem('_em');
            if (!t) return reject("No encrypted seed to decrypt");
            var ems = JSON.parse(t);
            var em;
            if (ems.hasOwnProperty("iv") === true) {
              //old format
              //convert to new?
              em = JSON.stringify(ems);
              var nems = {};
              nems[_id.principal] = em;
              localStorage.setItem('_em', JSON.stringify(nems));
            } else {
              if (ems.hasOwnProperty(_id.principal) === false) return reject("No encrypted seed to decrypt");
              em = ems[_id.principal];
            }
            decrypt(em, _id.principal, optdata.password).then(mnemonic => {
              localStorage.setItem('_m', mnemonic);
              id = mnemonicToId(mnemonic);
              return resolve(processId(id, _id.type));
            }).catch(reject);
            return;
          default: break;
        }
        
        if (oauths.indexOf(_id.type) >= 0) {
          try {
            const openlogin = await loadOpenLogin();
            if (!openlogin.privKey) {
              await openlogin.login({
                loginProvider: _id.type,
              });
            }
            id = Ed25519KeyIdentity.generate(new Uint8Array(fromHexString(openlogin.privKey)));
            if (id.getPrincipal().toString() !== _id.principal) {
              await openlogin.logout();
              return reject("Logged in using the incorrect user " + id.getPrincipal().toString() + " expecting " + _id.principal);
            } else {
              return resolve(processId(id, _id.type)); 
            }
          } catch (e) {
            return reject("Something happened");
          }
        }
        //reject("Invalid login type");
      });
    });
  },
  lock : (_id) => {
    return new Promise(async (resolve, reject) => {
      switch(_id.type){
        case "ii":
            var auth = await AuthClient.create();
            auth.logout();
          break;
        case "private":
            localStorage.removeItem("_m");
          break;
        default: break;
      }
      if (oauths.indexOf(_id.type) >= 0) {
        try {
          const openlogin = await loadOpenLogin();
          await openlogin.logout();
        } catch (e) {
          console.log(e);
        }
      }
      return resolve(true);
    });
  },
  clear : (_id) => {
    return new Promise(async (resolve, reject) => {
      switch(_id.type){
        case "ii":
            var auth = await AuthClient.create();
            auth.logout();
          break;
        case "private":
            localStorage.removeItem("_m");
            localStorage.removeItem("_em");
          break;
        default: break;
      }
      if (oauths.indexOf(_id.type) >= 0) {
        try {
          const openlogin = await loadOpenLogin();
          await openlogin.logout();
        } catch (e) {
          console.log(e);
        }
      }
      return resolve(true);
    });
  },
  change : (_id, type, optdata) => {
    return new Promise(async (resolve, reject) => {
      switch(_id.type){
        case "ii":
            var auth = await AuthClient.create();
            auth.logout();
          break;
        case "private":
            localStorage.removeItem("_m");
          break;
        default: break;
      }
      if (oauths.indexOf(_id.type) >= 0) {
        try {
          const openlogin = await loadOpenLogin();
          await openlogin.logout();
        } catch (e) {
          console.log(e);
        }
      }
      //setup new
      ICIdentity.setup(type, optdata).then(resolve).catch(reject);
    });
  },
  validatePrincipal : validatePrincipal,
  validateMnemonic : bip39.validateMnemonic,
  generateMnemonic : bip39.generateMnemonic,
  validatePassword : (p) => {
    var re = /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z]{8,}$/;
    return re.test(p);
  }
}
export default ICIdentity;
