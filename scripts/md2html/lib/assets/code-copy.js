// コードブロックのコピー・ボタンを扱う。document への委譲リスナ 1 本のみ
// 登録し、動的に増える .code-block にも対応する。
document.addEventListener("click", async (event) => {
  const button = event.target.closest(".code-copy");
  if (!button) {
    return;
  }

  if (!navigator.clipboard) {
    return;
  }

  const block = button.closest(".code-block");
  const pre = block ? block.querySelector("pre") : null;
  if (!pre) {
    return;
  }

  const text = (pre.textContent ?? "").replace(/\n$/, "");

  try {
    await navigator.clipboard.writeText(text);
  } catch {
    return;
  }

  button.textContent = "コピー済";
  button.classList.add("copied");
  setTimeout(() => {
    button.textContent = "コピー";
    button.classList.remove("copied");
  }, 1500);
});
