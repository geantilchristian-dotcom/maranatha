(function () {
  "use strict";

  const VERSION = "1.3.1-9";
  const EXPECTED_SIZE = 54553497;
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

    function notify(partIndex) {
      onProgress(partIndex, PART_COUNT, {
        received,
        totalBytes: EXPECTED_SIZE,
        percent: Math.min(100, Math.round((received / EXPECTED_SIZE) * 100)),
      });
    }

    for (let index = 0; index < PART_COUNT; index += 1) {
      notify(index);
      const response = await fetch(partUrl(index), { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`APK_PART_${index}_HTTP_${response.status}`);
      }

      if (!response.body || typeof response.body.getReader !== "function") {
        const bytes = await response.arrayBuffer();
        parts.push(bytes);
        received += bytes.byteLength;
        notify(index + 1);
        continue;
      }

      const reader = response.body.getReader();
      const chunks = [];
      let partSize = 0;
      while (true) {
        const item = await reader.read();
        if (item.done) break;
        chunks.push(item.value);
        partSize += item.value.byteLength;
        received += item.value.byteLength;
        notify(index);
      }
      const part = new Uint8Array(partSize);
      let offset = 0;
      chunks.forEach(function (chunk) {
        part.set(chunk, offset);
        offset += chunk.byteLength;
      });
      parts.push(part.buffer);
      notify(index + 1);
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