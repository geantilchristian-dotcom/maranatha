(function(){
"use strict";
const KEY =
  "maranatha_library_v2";
let internalWrite =
  false;
let queue =
  Promise.resolve();
const nativeSetItem =
  Storage.prototype.setItem;
const nativeFetch =
  window.fetch.bind(
    window
  );
function authHeadersSafe(){
  try {
    if(
      typeof window.authHeaders ===
      "function"
    ){
      return (
        window.authHeaders() ||
        {}
      );
    }
  }catch(_error){}
  return {};
}
function authenticated(){
  return Boolean(
    authHeadersSafe()[
      "x-admin-password"
    ]
  );
}
function parse(raw){
  try {
    return JSON.parse(
      raw || "[]"
    );
  }catch(_error){
    return [];
  }
}
function notify(){
  try {
    window.dispatchEvent(
      new Event(
        "maranatha-library-updated"
      )
    );
  }catch(_error){}
  try {
    window.dispatchEvent(
      new StorageEvent(
        "storage",
        {
          key: KEY,
          newValue:
            localStorage.getItem(KEY),
        }
      )
    );
  }catch(_error){}
}
function cache(value){
  internalWrite =
    true;
  try {
    nativeSetItem.call(
      localStorage,
      KEY,
      JSON.stringify(value)
    );
  }finally{
    internalWrite =
      false;
  }
  notify();
}
async function saveRemote(
  value
){
  if(
    !authenticated()
  ){
    throw new Error(
      "Session administrateur absente."
    );
  }
  const response =
    await nativeFetch(
      "/api/library/state",
      {
        method:
          "PUT",
        headers: {
          ...authHeadersSafe(),
          "Content-Type":
            "application/json",
        },
        body:
          JSON.stringify({
            value,
          }),
      }
    );
  if(!response.ok){
    let message =
      "BibliothÃ¨que HTTP " +
      response.status;
    try {
      const result =
        await response.json();
      message =
        result.error ||
        message;
    }catch(_error){}
    throw new Error(
      message
    );
  }
  console.log(
    "[BIBLIOTHEQUE] Admin -> MongoDB"
  );
}
async function loadRemote(){

const emptyLibrary = () => ({
recent: [],
live: [],
audio: [],
video: [],
book: [],
});

const normalizeLibrary = (value) => {

const clean = emptyLibrary();

if(
!value ||
Array.isArray(value) ||
typeof value !== "object"
){
return clean;
}

Object.keys(clean).forEach(
(key) => {
clean[key] =
Array.isArray(value[key])
? value[key]
: [];
}
);

return clean;
};

const hasRealData = (value) => {

return [
"recent",
"live",
"audio",
"video",
"book",
].some(
(key) =>
Array.isArray(value[key]) &&
value[key].length > 0
);

};

const response =
await nativeFetch(
"/api/library/state",
{
cache: "no-store",
}
);

if(!response.ok){
throw new Error(
"Bibliothèque HTTP " +
response.status
);
}

const result =
await response.json();

const remoteRaw =
Object.prototype.hasOwnProperty.call(
result,
"value"
)
? result.value
: null;

const remote =
normalizeLibrary(
remoteRaw
);

const local =
normalizeLibrary(
parse(
localStorage.getItem(KEY)
)
);

const remoteHasData =
hasRealData(remote);

const localHasData =
hasRealData(local);

/*
 * Si MongoDB est vide mais que le navigateur
 * contient de vraies données, on conserve le local.
 */
if(
!remoteHasData &&
localHasData &&
authenticated()
){

await saveRemote(
local
);

cache(
local
);

console.log(
"[BIBLIOTHEQUE] Données locales conservées et envoyées vers MongoDB."
);

return;
}

/*
 * Si MongoDB contient de vraies données,
 * MongoDB devient la source de référence.
 */
if(remoteHasData){

cache(
remote
);

console.log(
"[BIBLIOTHEQUE] MongoDB -> Admin"
);

return;
}

/*
 * Les deux côtés sont réellement vides.
 * On utilise malgré tout le nouveau format normalisé.
 */
cache(
remote
);

console.log(
"[BIBLIOTHEQUE] Bibliothèque vide normalisée."
);

/*
 * Convertit également l'ancien [] MongoDB
 * vers la nouvelle structure, si l'admin est connecté.
 */
if(
authenticated() &&
Array.isArray(remoteRaw)
){

await saveRemote(
remote
);

console.log(
"[BIBLIOTHEQUE] Ancien format MongoDB [] corrigé."
);

}

}
/*
 * Ajoute automatiquement le mot de passe Admin
 * Ã  l'upload Cloudinary de la BibliothÃ¨que.
 */
window.fetch =
  function(
    input,
    options
  ){
    const url =
      typeof input ===
      "string"
        ? input
        : (
            input &&
            input.url
          ) ||
          "";
    if(
      url.includes(
        "/api/library/upload"
      )
    ){
      const next =
        {
          ...(options || {}),
        };
      const h =
        new Headers(
          next.headers ||
          {}
        );
      const auth =
        authHeadersSafe();
      if(
        auth[
          "x-admin-password"
        ]
      ){
        h.set(
          "x-admin-password",
          auth[
            "x-admin-password"
          ]
        );
      }
      next.headers =
        h;
      return nativeFetch(
        input,
        next
      );
    }
    return nativeFetch(
      input,
      options
    );
  };
Storage.prototype.setItem =
  function(
    key,
    value
  ){
    const result =
      nativeSetItem.call(
        this,
        key,
        value
      );
    if(
      this === localStorage &&
      key === KEY &&
      !internalWrite
    ){
      const parsed =
        parse(value);
      queue =
        queue
          .then(
            () =>
              saveRemote(
                parsed
              )
          )
          .catch(
            error => {
              console.error(
                "[BIBLIOTHEQUE SYNC]",
                error
              );
            }
          );
    }
    return result;
  };
loadRemote().catch(
  function(error){
    console.warn(
      "[BIBLIOTHEQUE LOAD]",
      error
    );
  }
);
let tries = 0;
const timer =
  setInterval(
    function(){
      tries++;
      if(
        authenticated()
      ){
        clearInterval(
          timer
        );
        loadRemote().catch(
          function(error){
            console.warn(
              "[BIBLIOTHEQUE AUTH LOAD]",
              error
            );
          }
        );
        return;
      }
      if(
        tries > 240
      ){
        clearInterval(
          timer
        );
      }
    },
    500
  );
})();
