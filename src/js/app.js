/**
 * app.js — Fetches JSON data files and renders sections into the DOM.
 *
 * Data files live in /data/:
 *   talks.json    — conference talks
 *   articles.json — writing / articles
 *   work.json     — selected work items
 */

(function () {
  'use strict';

  // ── Helpers ───────────────────────────────────────────────────────

  /**
   * Fetch a JSON file. Returns a promise that resolves to parsed JSON,
   * or rejects with a friendly error message on failure.
   */
  async function fetchJSON(path) {
    const res = await fetch(path);
    if (!res.ok) throw new Error(`Failed to load ${path} (${res.status})`);
    return res.json();
  }

  /** Create an element with optional className and innerHTML. */
  function el(tag, { className, html, text } = {}) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (html !== undefined) node.innerHTML = html;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  /** Escape user-supplied strings before inserting as innerHTML. */
  function esc(str) {
    if (!str) return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  // ── Render: Work ──────────────────────────────────────────────────

  function renderWork(items, container) {
    const list = el('div', { className: 'work-list' });

    for (const item of items) {
      const div = el('div', { className: 'work-item' });

      // Header row: title + meta (org / period)
      const header = el('div', { className: 'work-header' });
      const title = el('h3', { className: 'work-title', text: item.title });
      header.appendChild(title);

      const metaParts = [item.org, item.period].filter(Boolean);
      if (metaParts.length) {
        const meta = el('span', { className: 'work-meta', text: metaParts.join(' · ') });
        header.appendChild(meta);
      }
      div.appendChild(header);

      // Description
      if (item.description) {
        const desc = el('p', { className: 'work-description', text: item.description });
        div.appendChild(desc);
      }

      // Tags
      if (item.tags && item.tags.length) {
        const tagRow = el('div', { className: 'work-tags' });
        for (const t of item.tags) {
          tagRow.appendChild(el('span', { className: 'tag', text: t }));
        }
        div.appendChild(tagRow);
      }

      list.appendChild(div);
    }

    container.innerHTML = '';
    container.appendChild(list);
  }

  // ── Render: Talks ─────────────────────────────────────────────────

  function renderTalks(items, container) {
    const list = el('div', { className: 'talks-list' });

    for (const talk of items) {
      const div = el('div', { className: 'talk-item' });

      // Event / location / year line
      const eventParts = [];
      if (talk.year) eventParts.push(`<span class="talk-year">${esc(talk.year)}</span>`);
      if (talk.event) eventParts.push(esc(talk.event));
      if (talk.location) eventParts.push(esc(talk.location));

      const eventLine = el('p', { className: 'talk-event-line', html: eventParts.join(' · ') });
      div.appendChild(eventLine);

      // Title
      const title = el('h3', { className: 'talk-title', text: talk.title });
      div.appendChild(title);

      // Description
      if (talk.description) {
        const desc = el('p', { className: 'talk-description', text: talk.description });
        div.appendChild(desc);
      }

      // Links (recording / slides)
      const hasLinks = talk.recordingUrl || talk.slidesUrl;
      if (hasLinks) {
        const linkRow = el('div', { className: 'talk-links' });
        if (talk.recordingUrl) {
          const a = el('a', { className: 'talk-link', text: 'Watch recording →' });
          a.href = talk.recordingUrl;
          a.setAttribute('target', '_blank');
          a.setAttribute('rel', 'noopener noreferrer');
          linkRow.appendChild(a);
        }
        if (talk.slidesUrl) {
          const a = el('a', { className: 'talk-link', text: 'Slides →' });
          a.href = talk.slidesUrl;
          a.setAttribute('target', '_blank');
          a.setAttribute('rel', 'noopener noreferrer');
          linkRow.appendChild(a);
        }
        div.appendChild(linkRow);
      }

      list.appendChild(div);
    }

    container.innerHTML = '';
    container.appendChild(list);
  }

  // ── Render: Writing ───────────────────────────────────────────────

  function renderWriting(items, container) {
    const list = el('div', { className: 'writing-list' });

    for (const article of items) {
      const div = el('div', { className: 'writing-item' });

      const content = el('div', { className: 'writing-content' });

      const titleEl = el('h3', { className: 'writing-title' });
      if (article.url) {
        const a = el('a', { text: article.title });
        a.href = article.url;
        titleEl.appendChild(a);
      } else {
        titleEl.textContent = article.title;
      }
      content.appendChild(titleEl);

      if (article.subtitle) {
        content.appendChild(el('p', { className: 'writing-subtitle', text: article.subtitle }));
      }

      div.appendChild(content);

      if (article.date) {
        div.appendChild(el('span', { className: 'writing-date', text: article.date }));
      }

      list.appendChild(div);
    }

    container.innerHTML = '';
    container.appendChild(list);
  }

  // ── Error display ─────────────────────────────────────────────────

  function showError(container, message) {
    container.innerHTML = '';
    container.appendChild(el('p', { className: 'error-state', text: message }));
  }

  // ── Bootstrap ─────────────────────────────────────────────────────

  async function init() {
    const workContainer    = document.getElementById('work-items');
    const talksContainer   = document.getElementById('talks-items');
    const writingContainer = document.getElementById('writing-items');

    // Fetch all three data files concurrently
    const [workResult, talksResult, writingResult] = await Promise.allSettled([
      fetchJSON('data/work.json'),
      fetchJSON('data/talks.json'),
      fetchJSON('data/articles.json'),
    ]);

    if (workContainer) {
      if (workResult.status === 'fulfilled') {
        renderWork(workResult.value, workContainer);
      } else {
        console.error('Work data load error:', workResult.reason);
        showError(workContainer, 'Could not load work items.');
      }
    }

    if (talksContainer) {
      if (talksResult.status === 'fulfilled') {
        renderTalks(talksResult.value, talksContainer);
      } else {
        console.error('Talks data load error:', talksResult.reason);
        showError(talksContainer, 'Could not load talks.');
      }
    }

    if (writingContainer) {
      if (writingResult.status === 'fulfilled') {
        renderWriting(writingResult.value, writingContainer);
      } else {
        console.error('Writing data load error:', writingResult.reason);
        showError(writingContainer, 'Could not load writing.');
      }
    }
  }

  // Run after DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
