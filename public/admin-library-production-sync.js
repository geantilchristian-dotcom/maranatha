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
      "Bibliothèque HTTP " +
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
  const response =
    await nativeFetch(
      "/api/library/state",
      {
        cache:
          "no-store",
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
  const remote =
    Object.prototype.hasOwnProperty.call(
      result,
      "value"
    )
      ? result.value
      : [];
  const local =
    parse(
      localStorage.getItem(KEY)
    );
  const remoteEmpty =
    Array.isArray(remote)
      ? remote.length === 0
      : (
          remote == null ||
          (
            typeof remote === "object" &&
            Object.keys(remote).length === 0
          )
        );
  const localHasData =
    Array.isArray(local)
      ? local.length > 0
      : (
          local &&
          typeof local === "object" &&
          Object.keys(local).length > 0
        );
  /*
   * Première migration :
   * si MongoDB est vide mais le navigateur admin
   * contient déjà la vraie bibliothèque, on la conserve.
   */
  if(
    remoteEmpty &&
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
      "[BIBLIOTHEQUE] Anciennes données locales migrées vers MongoDB."
    );
    return;
  }
  cache(
    remote
  );
  console.log(
    "[BIBLIOTHEQUE] MongoDB -> Admin"
  );
}
/*
 * Ajoute automatiquement le mot de passe Admin
 * à l'upload Cloudinary de la Bibliothèque.
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