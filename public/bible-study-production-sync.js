(function(){
"use strict";
const KEY =
  "maranatha_bible_studies_v2";
function normalize(item){
  item =
    item &&
    typeof item === "object"
      ? item
      : {};
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
    active:
      item.active !== undefined
        ? item.active
        : item.actif !== false,
    actif:
      item.actif !== undefined
        ? item.actif
        : item.active !== false,
    title:
      item.title ||
      item.titre ||
      "",
    titre:
      item.titre ||
      item.title ||
      "",
    image:
      item.image ||
      item.imageUrl ||
      item.cover ||
      item.coverUrl ||
      "",
    pdf:
      item.pdf ||
      item.pdfUrl ||
      "",
  };
}
function notify(){
  try {
    window.dispatchEvent(
      new Event(
        "maranatha-bible-study-updated"
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
async function refresh(){
  try {
    const response =
      await fetch(
        "/api/etudes",
        {
          cache:
            "no-store",
        }
      );
    if(!response.ok){
      throw new Error(
        "HTTP " +
        response.status
      );
    }
    const list =
      await response.json();
    const normalized =
      (
        Array.isArray(list)
          ? list
          : []
      )
      .map(normalize);
    localStorage.setItem(
      KEY,
      JSON.stringify(
        normalized
      )
    );
    notify();
    console.log(
      "[ETUDES] MongoDB -> Fidèle :",
      normalized.length
    );
  }catch(error){
    console.warn(
      "[ETUDES FIDELE]",
      error
    );
  }
}
if(
  document.readyState ===
  "loading"
){
  document.addEventListener(
    "DOMContentLoaded",
    refresh,
    {
      once: true,
    }
  );
}else{
  refresh();
}
window.addEventListener(
  "focus",
  refresh
);
document.addEventListener(
  "click",
  function(event){
    const element =
      event.target.closest(
        'a[href*="etude"],' +
        'a[href*="study"],' +
        '[data-tab*="etude"],' +
        '[data-action*="etude"]'
      );
    if(element){
      refresh();
    }
  },
  true
);
})();