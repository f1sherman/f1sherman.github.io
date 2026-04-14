document.addEventListener("DOMContentLoaded", async () => {
  const mermaidBlocks = Array.from(document.querySelectorAll("code.language-mermaid"));

  if (mermaidBlocks.length === 0) {
    return;
  }

  const { default: mermaid } = await import("https://cdn.jsdelivr.net/npm/mermaid@11.6.0/dist/mermaid.esm.min.mjs");

  mermaid.initialize({
    startOnLoad: false,
    securityLevel: "loose",
    theme: "neutral"
  });

  const renderTargets = [];

  for (const code of mermaidBlocks) {
    const source = code.textContent.trim();
    const pre = code.closest("pre");
    const highlight = code.closest(".highlight");
    const replacement = document.createElement("div");

    replacement.className = "mermaid";
    replacement.textContent = source;

    if (highlight) {
      highlight.replaceWith(replacement);
    } else if (pre) {
      pre.replaceWith(replacement);
    } else {
      code.replaceWith(replacement);
    }

    renderTargets.push(replacement);
  }

  await mermaid.run({
    nodes: renderTargets
  });
});
