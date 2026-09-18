(function () {
  "use strict";

  const VERSION = "1.3.0-8";
  const EXPECTED_SIZE = 53884587;
  const PART_COUNT = 7;

  function partUrl(index) {
    return `/downloads/MARANATHA.apk.part-${String(index).padStart(2, "0")}?v=${VERSION}`;
  }

  async function download(options) {
    const onProgress =
      options && typeof options.onProgress === "function"
        ? options.onProgress
        : function () {};
    const parts = [];
    let received = 0;

    for (let index = 0; index < PART_COUNT; index += 1) {
      onProgress(index, PART_COUNT);
      const response = await fetch(partUrl(index), { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`APK_PART_${index}_HTTP_${response.status}`);
      }

      const bytes = await response.arrayBuffer();
      parts.push(bytes);
      received += bytes.byteLength;
      onProgress(index + 1, PART_COUNT);
    }

    if (received !== EXPECTED_SIZE) {
      throw new Error(`APK_SIZE_${received}`);
    }

    const blob = new Blob(parts, {
      type: "application/vnd.android.package-archive"
    });
    const objectUrl = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = objectUrl;
    link.download = "MARANATHA.apk";
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.setTimeout(function () {
      URL.revokeObjectURL(objectUrl);
    }, 60000);
  }

  window.MaranathaApk = Object.freeze({ download });
})();