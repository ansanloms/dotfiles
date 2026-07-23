// mermaid の browser 向けレンダリングと、パン・ズーム UI (.mermaid-zoom) の
// DOM 構築を行う。mermaid.run + dataset 退避方式は使わず、pre.mermaid の
// テキストを保持したまま render() で都度描画し直す。これにより
// prefers-color-scheme の変更にも追従できる (テーマを切り替えて再描画する)。

/** ズーム操作 (ホイール / ボタン / ドラッグ) を 1 つの .mermaid-zoom へ仕込む。 */
const setupZoom = (container) => {
  const viewport = container.querySelector(".mz-viewport");
  const svg = viewport ? viewport.querySelector("svg") : null;
  if (!viewport || !svg) {
    return;
  }

  let width = 0;
  let height = 0;
  const viewBox = svg.getAttribute("viewBox");
  if (viewBox) {
    const parts = viewBox.trim().split(/\s+/).map(Number);
    if (parts.length === 4 && parts[2] > 0 && parts[3] > 0) {
      width = parts[2];
      height = parts[3];
    }
  }
  if (!width || !height) {
    const rect = svg.getBoundingClientRect();
    width = rect.width;
    height = rect.height;
  }
  if (!width || !height) {
    width = 400;
    height = 300;
  }

  svg.removeAttribute("style");
  svg.setAttribute("width", String(width));
  svg.setAttribute("height", String(height));
  viewport.style.width = `${width}px`;
  viewport.style.height = `${height}px`;

  let scale = 1;
  let tx = 0;
  let ty = 0;
  let minS = 0.1;
  let maxS = 10;

  const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

  const apply = () => {
    viewport.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`;
  };

  // コンテナ実寸に contain フィットして中央配置する (基準状態でもある)。
  const reset = () => {
    const cw = container.clientWidth;
    const ch = container.clientHeight;
    const fit = cw > 0 && ch > 0 ? Math.min(cw / width, ch / height) : 1;
    minS = Math.min(fit, 1) * 0.4;
    maxS = Math.max(fit, 1) * 6;
    scale = fit;
    tx = (cw - width * scale) / 2;
    ty = (ch - height * scale) / 2;
    apply();
  };

  // (px, py) を固定点として倍率を factor 倍する。
  const zoomAt = (px, py, factor) => {
    const next = clamp(scale * factor, minS, maxS);
    const ratio = next / scale;
    tx = px - (px - tx) * ratio;
    ty = py - (py - ty) * ratio;
    scale = next;
    apply();
  };

  container.addEventListener("wheel", (event) => {
    if (!event.ctrlKey && !event.metaKey) {
      return;
    }
    event.preventDefault();

    const rect = container.getBoundingClientRect();
    const px = event.clientX - rect.left;
    const py = event.clientY - rect.top;
    const factor = event.deltaY < 0 ? 1.12 : 1 / 1.12;
    zoomAt(px, py, factor);
  }, { passive: false });

  let dragging = false;
  let originX = 0;
  let originY = 0;

  container.addEventListener("pointerdown", (event) => {
    if (event.target.closest(".mz-btn")) {
      return;
    }
    dragging = true;
    originX = event.clientX - tx;
    originY = event.clientY - ty;
    container.classList.add("dragging");
    container.setPointerCapture(event.pointerId);
  });

  container.addEventListener("pointermove", (event) => {
    if (!dragging) {
      return;
    }
    tx = event.clientX - originX;
    ty = event.clientY - originY;
    apply();
  });

  const endDrag = () => {
    dragging = false;
    container.classList.remove("dragging");
  };
  container.addEventListener("pointerup", endDrag);
  container.addEventListener("pointercancel", endDrag);

  container.addEventListener("dblclick", (event) => {
    event.preventDefault();
    reset();
  });

  const controls = container.querySelector(".mz-controls");
  if (controls) {
    controls.addEventListener("click", (event) => {
      const button = event.target.closest(".mz-btn");
      if (!button) {
        return;
      }
      const action = button.dataset.a;
      if (action === "in") {
        zoomAt(container.clientWidth / 2, container.clientHeight / 2, 1.25);
      } else if (action === "out") {
        zoomAt(container.clientWidth / 2, container.clientHeight / 2, 1 / 1.25);
      } else if (action === "reset") {
        reset();
      }
    });
  }

  requestAnimationFrame(reset);
};

/** pre.mermaid を mermaid で render し、パン・ズーム対応の DOM へ差し替える。 */
export const initMermaidZoom = async (mermaid) => {
  const targets = Array.from(document.querySelectorAll("pre.mermaid")).map(
    (node) => ({ node, text: node.textContent ?? "" }),
  );
  if (targets.length === 0) {
    return;
  }

  const media = matchMedia("(prefers-color-scheme: dark)");
  let rev = 0;

  const renderAll = async () => {
    const dark = media.matches;
    mermaid.initialize({
      startOnLoad: false,
      fontFamily: "inherit",
      theme: dark ? "dark" : "default",
    });

    rev += 1;

    for (let i = 0; i < targets.length; i++) {
      const target = targets[i];

      let svg;
      try {
        ({ svg } = await mermaid.render(`mmd-${rev}-${i}`, target.text));
      } catch {
        continue;
      }

      const container = document.createElement("div");
      container.className = "mermaid-zoom";
      container.tabIndex = 0;
      container.innerHTML = `<div class="mz-viewport">${svg}</div>
<div class="mz-controls">
  <button class="mz-btn" type="button" data-a="in" title="拡大">+</button>
  <button class="mz-btn" type="button" data-a="out" title="縮小">−</button>
  <button class="mz-btn" type="button" data-a="reset" title="リセット">↺</button>
</div>
<span class="mz-hint">ドラッグで移動 · Ctrl/⌘+ホイールで拡大 · ダブルクリックでリセット</span>`;

      target.node.replaceWith(container);
      target.node = container;
      setupZoom(container);
    }
  };

  await renderAll();
  media.addEventListener("change", renderAll);
};
