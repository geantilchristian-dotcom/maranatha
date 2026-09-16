(function(){
"use strict";
const KEY =
  "maranatha_library_v2";
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
async function refresh(){
  try {
    const response =
      await fetch(
        "/api/library/state",
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
    const result =
      await response.json();
    const value =
      Object.prototype.hasOwnProperty.call(
        result,
        "value"
      )
        ? result.value
        : [];
    localStorage.setItem(
      KEY,
      JSON.stringify(
        value
      )
    );
    notify();
    console.log(
      "[BIBLIOTHEQUE] MongoDB -> Fidèle"
    );
  }catch(error){
    console.warn(
      "[BIBLIOTHEQUE FIDELE]",
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
    const link =
      event.target.closest(
        'a[href*="bibli"],' +
        '[data-tab*="bibli"],' +
        '[data-action*="bibli"]'
      );
    if(link){
      refresh();
    }
  },
  true
);
})();