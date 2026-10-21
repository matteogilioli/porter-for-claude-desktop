// The carry: scroll lifts the stopped session out of one account and sets it down in the other.
(() => {
  const carry = document.querySelector(".carry");
  if (!carry) return;
  const deck = carry.querySelector(".deck");
  const session = carry.querySelector(".session");
  const slotA = carry.querySelector(".slot-a");
  const slotB = carry.querySelector(".slot-b");
  const track = carry.querySelector(".path-track");
  const ink = carry.querySelector(".path-ink");
  const countB = carry.querySelector(".count-b");
  const barB = carry.querySelector(".b5");
  const barBn = carry.querySelector(".b5n");
  const still = matchMedia("(prefers-reduced-motion: reduce)");

  let a, b, c, length = 0;
  const clamp = (v, lo = 0, hi = 1) => Math.min(hi, Math.max(lo, v));
  const smooth = (e0, e1, x) => { const t = clamp((x - e0) / (e1 - e0)); return t * t * (3 - 2 * t); };
  const ease = t => 1 - Math.pow(1 - t, 3);
  // c is in path space (the session's centre); the card is placed by its top-left corner.
  const at = t => {
    const cx = c.x - session.offsetWidth / 2, cy = c.y - session.offsetHeight / 2;
    return {
      x: (1 - t) * (1 - t) * a.x + 2 * (1 - t) * t * cx + t * t * b.x,
      y: (1 - t) * (1 - t) * a.y + 2 * (1 - t) * t * cy + t * t * b.y,
    };
  };

  // Where the session sits in each account, relative to the deck.
  function measure() {
    // Each account keeps room for the session, so it sits inside the card, not over it.
    slotA.style.height = slotB.style.height = `${session.offsetHeight + 8}px`;
    const d = deck.getBoundingClientRect();
    const place = slot => {
      const r = slot.getBoundingClientRect();
      return { x: r.left - d.left + (r.width - session.offsetWidth) / 2, y: r.top - d.top + (r.height - session.offsetHeight) / 2 };
    };
    a = place(slotA);
    b = place(slotB);
    // The arc runs through open space, measured from where the cards actually sit, so it shows
    // whatever the text lengths: over the corner above the second card when the cards sit side
    // by side, down the free space beside it when they are stacked.
    const w = session.offsetWidth, h = session.offsetHeight;
    const cardA = slotA.closest(".account").getBoundingClientRect();
    const cardB = slotB.closest(".account").getBoundingClientRect();
    const topB = cardB.top - d.top, rightA = cardA.right - d.left;
    c = cardB.left - d.left > rightA - w * 0.5
      ? { x: (rightA + b.x + w) / 2, y: 2 * (topB - 36) - (a.y + b.y + h) / 2 }
      : { x: a.x + w * 0.25, y: b.y + h * 0.5 };
    const dPath = `M${a.x + w / 2} ${a.y + h / 2} Q${c.x} ${c.y} ${b.x + w / 2} ${b.y + h / 2}`;
    track.setAttribute("d", dPath);
    ink.setAttribute("d", dPath);
    length = ink.getTotalLength();
    ink.style.strokeDasharray = `${length}`;
  }

  function render(p) {
    const t = ease(smooth(0.18, 0.78, p));
    const lift = smooth(0.06, 0.2, p) * (1 - smooth(0.74, 0.86, p));
    const pos = at(t);
    session.style.setProperty("--x", `${pos.x}px`);
    session.style.setProperty("--y", `${pos.y}px`);
    session.style.setProperty("--lift", lift.toFixed(3));
    session.style.setProperty("--r", `${(-4 * Math.sin(t * Math.PI)).toFixed(2)}deg`);
    ink.style.strokeDashoffset = `${length * (1 - t)}`;
    ink.style.opacity = p > 0.86 ? `${1 - smooth(0.86, 0.98, p)}` : "1";
    const landed = p >= 0.8;
    carry.toggleAttribute("data-landed", landed);
    carry.toggleAttribute("data-lifted", p > 0.1 && !landed);
    carry.dataset.step = p < 0.2 ? "1" : landed ? "3" : "2";
    carry.toggleAttribute("data-scrolled", p > 0.03);
    countB.textContent = landed ? countB.dataset.after : countB.dataset.before;
    // Back at work: the session spends a little of the new account's 5 hours.
    const used = landed ? 18 : 12;
    barB.style.setProperty("--v", used);
    barBn.textContent = `${used}%`;
  }

  let frame = 0;
  function onScroll() {
    if (frame) return;
    frame = requestAnimationFrame(() => {
      frame = 0;
      // Measured every frame: a handful of rects, and never stale after fonts or layout settle.
      measure();
      if (still.matches) return render(1);
      const r = carry.getBoundingClientRect();
      const run = carry.offsetHeight - innerHeight;
      render(run > 0 ? clamp(-r.top / run) : 1);
    });
  }

  const setup = () => onScroll();
  addEventListener("scroll", onScroll, { passive: true });
  addEventListener("resize", setup);
  // Fonts, translations and the window can all change the cards' size after load.
  new ResizeObserver(setup).observe(deck);
  still.addEventListener("change", setup);
  document.fonts?.ready.then(setup);
  setup();
})();

// The panel's Personal account keeps working while you read.
(() => {
  const bar = document.querySelector(".usage i.live");
  const label = document.querySelector(".usage .live-n");
  if (!bar || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  let v = 12;
  const tick = () => {
    if (document.hidden) return;
    v = v >= 19 ? 12 : v + 1;
    bar.style.setProperty("--v", v);
    label.textContent = `${v}%`;
  };
  new IntersectionObserver(([e]) => {
    clearInterval(bar.timer);
    if (e.isIntersecting) bar.timer = setInterval(tick, 2600);
  }).observe(bar);
})();

// The menu bar's clock, as macOS shows it.
(() => {
  const clock = document.querySelector(".clock");
  if (!clock) return;
  const tick = () => { clock.textContent = new Date().toLocaleTimeString(document.documentElement.lang, { hour: "numeric", minute: "2-digit" }); };
  tick();
  setInterval(tick, 15000);
})();

// Copy buttons.
document.querySelectorAll(".copy").forEach(button => {
  const label = button.textContent;
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(document.getElementById(button.dataset.copy).textContent);
      button.textContent = button.dataset.done;
    } catch {
      getSelection().selectAllChildren(document.getElementById(button.dataset.copy));
    }
    setTimeout(() => { button.textContent = label; }, 1800);
  });
});

// Close the language menu on outside click or Escape.
(() => {
  const menu = document.querySelector(".langs");
  if (!menu) return;
  document.addEventListener("click", e => { if (!menu.contains(e.target)) menu.open = false; });
  document.addEventListener("keydown", e => { if (e.key === "Escape") menu.open = false; });
})();
