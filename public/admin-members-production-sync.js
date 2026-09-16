(function(){
"use strict";
const KEY =
  "maranatha_membership_requests_v2";
let internalWrite =
  false;
let syncQueue =
  Promise.resolve();
const nativeSetItem =
  Storage.prototype.setItem;
function headers(){
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
    headers()[
      "x-admin-password"
    ]
  );
}
function parse(value){
  try {
    const data =
      JSON.parse(
        value || "[]"
      );
    return Array.isArray(data)
      ? data
      : [];
  }catch(_error){
    return [];
  }
}
function idOf(item){
  return String(
    (
      item &&
      (
        item._id ||
        item.id ||
        item.memberId
      )
    ) ||
    ""
  );
}
function normalize(item){
  item =
    item &&
    typeof item === "object"
      ? item
      : {};
  const status =
    item.statut ||
    item.status ||
    "";
  return {
    ...item,
    id:
      item.id ||
      item._id ||
      "",
    _id:
      item._id ||
      item.id ||
      "",
    statut:
      status,
    status:
      status,
    submittedAt:
      item.submittedAt ||
      item.createdAt ||
      "",
  };
}
function notify(){
  try {
    window.dispatchEvent(
      new Event(
        "maranatha-members-updated"
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
function cache(list){
  internalWrite =
    true;
  try {
    nativeSetItem.call(
      localStorage,
      KEY,
      JSON.stringify(
        list.map(normalize)
      )
    );
  }finally{
    internalWrite =
      false;
  }
  notify();
}
async function refresh(){
  if(
    !authenticated()
  ){
    return false;
  }
  const response =
    await fetch(
      "/api/membres",
      {
        cache:
          "no-store",
        headers:
          headers(),
      }
    );
  if(!response.ok){
    throw new Error(
      "Membres HTTP " +
      response.status
    );
  }
  const list =
    await response.json();
  cache(
    Array.isArray(list)
      ? list
      : []
  );
  console.log(
    "[MEMBRES] MongoDB -> Admin :",
    Array.isArray(list)
      ? list.length
      : 0
  );
  return true;
}
function changed(
  before,
  after,
  key
){
  return (
    JSON.stringify(
      before &&
      before[key]
    ) !==
    JSON.stringify(
      after &&
      after[key]
    )
  );
}
async function syncDifference(
  beforeList,
  afterList
){
  if(
    !authenticated()
  ){
    return;
  }
  const before =
    new Map();
  beforeList.forEach(
    item => {
      const id =
        idOf(item);
      if(id){
        before.set(
          id,
          item
        );
      }
    }
  );
  const after =
    new Map();
  afterList.forEach(
    item => {
      const id =
        idOf(item);
      if(id){
        after.set(
          id,
          item
        );
      }
    }
  );
  /*
   * Suppressions
   */
  for(
    const [id]
    of before
  ){
    if(
      after.has(id)
    ){
      continue;
    }
    const response =
      await fetch(
        "/api/membres/" +
        encodeURIComponent(id),
        {
          method:
            "DELETE",
          headers:
            headers(),
        }
      );
    if(!response.ok){
      throw new Error(
        "Suppression membre HTTP " +
        response.status
      );
    }
  }
  /*
   * Modifications
   */
  for(
    const [id,current]
    of after
  ){
    const previous =
      before.get(id);
    if(!previous){
      continue;
    }
    const previousStatus =
      previous.statut ||
      previous.status ||
      "";
    const currentStatus =
      current.statut ||
      current.status ||
      "";
    if(
      previousStatus !==
      currentStatus
    ){
      const response =
        await fetch(
          "/api/membres/" +
          encodeURIComponent(id) +
          "/statut",
          {
            method:
              "PATCH",
            headers: {
              ...headers(),
              "Content-Type":
                "application/json",
            },
            body:
              JSON.stringify({
                statut:
                  currentStatus,
              }),
          }
        );
      if(!response.ok){
        throw new Error(
          "Statut membre HTTP " +
          response.status
        );
      }
    }
    const allowed = [
      "nom",
      "postNom",
      "prenom",
      "age",
      "sexe",
      "pays",
      "adresse",
      "bio",
      "email",
      "indicatif",
    ];
    const update = {};
    allowed.forEach(
      key => {
        if(
          changed(
            previous,
            current,
            key
          )
        ){
          update[key] =
            current[key];
        }
      }
    );
    if(
      Object.keys(update).length
    ){
      const response =
        await fetch(
          "/api/membres/" +
          encodeURIComponent(id),
          {
            method:
              "PATCH",
            headers: {
              ...headers(),
              "Content-Type":
                "application/json",
            },
            body:
              JSON.stringify(
                update
              ),
          }
        );
      if(!response.ok){
        throw new Error(
          "Modification membre HTTP " +
          response.status
        );
      }
    }
  }
  await refresh();
}
Storage.prototype.setItem =
  function(
    key,
    value
  ){
    const oldValue =
      (
        this ===
        localStorage
      )
        ? this.getItem(key)
        : null;
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
      const before =
        parse(oldValue);
      const after =
        parse(value);
      syncQueue =
        syncQueue
          .then(
            () =>
              syncDifference(
                before,
                after
              )
          )
          .catch(
            error => {
              console.error(
                "[MEMBRES SYNC]",
                error
              );
            }
          );
    }
    return result;
  };
let attempts = 0;
const timer =
  setInterval(
    async function(){
      attempts++;
      if(
        authenticated()
      ){
        clearInterval(
          timer
        );
        try {
          await refresh();
        }catch(error){
          console.error(
            "[MEMBRES LOAD]",
            error
          );
        }
        return;
      }
      if(
        attempts > 240
      ){
        clearInterval(
          timer
        );
      }
    },
    500
  );
document.addEventListener(
  "click",
  function(){
    if(
      authenticated()
    ){
      setTimeout(
        function(){
          refresh().catch(
            function(){}
          );
        },
        100
      );
    }
  },
  true
);
})();