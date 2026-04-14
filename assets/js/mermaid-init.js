document.addEventListener("DOMContentLoaded", async () => {
  const mermaidBlocks = Array.from(document.querySelectorAll("code.language-mermaid"));

  if (mermaidBlocks.length === 0) {
    return;
  }

  const restorations = [];

  try {
    const { default: mermaid } = await import("https://cdn.jsdelivr.net/npm/mermaid@11.6.0/dist/mermaid.esm.min.mjs");

    mermaid.initialize({
      startOnLoad: false,
      securityLevel: "loose",
      theme: "neutral"
    });

    const renderTargets = [];

    for (const code of mermaidBlocks) {
      const source = code.textContent.trim();
      const target = code.closest(".highlight") || code.closest("pre") || code;
      const parent = target.parentNode;
      const nextSibling = target.nextSibling;
      const replacement = document.createElement("div");

      replacement.className = "mermaid";
      replacement.textContent = source;

      target.replaceWith(replacement);

      renderTargets.push(replacement);
      restorations.push({
        nextSibling,
        original: target,
        parent,
        replacement
      });
    }

    await mermaid.run({
      nodes: renderTargets
    });
  } catch (error) {
    for (let index = restorations.length - 1; index >= 0; index -= 1) {
      const { nextSibling, original, parent, replacement } = restorations[index];

      if (!parent || !replacement.isConnected) {
        continue;
      }

      parent.insertBefore(original, nextSibling);
      replacement.remove();
    }

    console.warn("Mermaid rendering skipped:", error);
  }
});
