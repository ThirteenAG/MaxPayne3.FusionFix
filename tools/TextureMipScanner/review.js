'use strict';

function filterRows(rows, options, selected) {
    const term = (options.search || '').toLowerCase();
    const minimum = Number(options.minimum) || 0;
    const result = rows.filter(row => {
        if (row.score < minimum || (term && !row.search.includes(term))) return false;
        if (Number(options.size) > 0 && Math.min(row.width || 0, row.height || 0) < 128) return false;
        if (Number(options.size) > Math.max(row.width || 0, row.height || 0)) return false;
        switch (options.view) {
            case 'variants': return row.variants > 1;
            case 'candidates': return row.candidate;
            case 'exact': return row.eligible && row.max_error === 0;
            case 'selected': return selected.has(row.id);
            case 'ineligible': return row.status === 'ineligible';
            case 'error': return row.status === 'error';
            default: return true;
        }
    });
    result.sort((a, b) => {
        let difference = 0;
        if (options.sort === 'score') difference = b.score - a.score || (a.mae || 0)-(b.mae || 0);
        if (options.sort === 'copies') difference = b.copies - a.copies;
        if (options.sort === 'size') difference = (b.width || 0)*(b.height || 0) - (a.width || 0)*(a.height || 0) || b.score-a.score;
        return difference || a.name.localeCompare(b.name) || a.variant - b.variant;
    });
    return result;
}

function paginate(rows, page, size) {
    size = Math.max(1, Number(size) || 60);
    const pages = Math.max(1, Math.ceil(rows.length / size));
    page = Math.min(pages, Math.max(1, Number(page) || 1));
    const first = (page - 1) * size;
    return {rows: rows.slice(first, first + size), page, pages, first};
}

function exportNames(rows, selected) {
    const names = new Map();
    rows.filter(row => row.eligible && selected.has(row.id)).forEach(row => names.set(row.name.toLowerCase(), row.name));
    return [...names.values()].sort((a, b) => a.localeCompare(b));
}

function exportList(rows, selected) {
    const groups = new Map();
    for (const row of rows) {
        if (!row.eligible || !selected.has(row.id)) continue;
        const key = row.name.toLowerCase();
        if (!groups.has(key)) groups.set(key, {name: row.name, sources: new Set()});
        const group = groups.get(key); group.name = row.name;
        for (const source of row.sources || (row.path ? [row.path] : [])) {
            group.sources.add(String(source).replace(/[\r\n]+/g, ' '));
        }
    }
    const lines = ['# Reviewed DDS mip-skip names (all variants of each name are affected)', ''];
    for (const group of [...groups.values()].sort((a, b) => a.name.localeCompare(b.name))) {
        lines.push(group.name);
        for (const source of [...group.sources].sort()) lines.push('# Source: ' + source);
        lines.push('');
    }
    return lines.join('\n');
}

if (typeof module !== 'undefined') module.exports = {filterRows, paginate, exportNames, exportList};

if (typeof document !== 'undefined') {
    const data = JSON.parse(document.querySelector('#texture-data').textContent);
    const rows = data.rows;
    for (const row of rows) row.search = [row.name, `${row.width}x${row.height}`, ...row.sources, ...row.companions].join(' ').toLowerCase();
    const controls = {};
    for (const id of ['search', 'view', 'score', 'size', 'sort', 'select', 'clear', 'export', 'selection',
                      'previous', 'next', 'page', 'pages', 'page-size', 'range', 'grid', 'empty', 'summary']) {
        controls[id] = document.getElementById(id);
    }
    const selected = new Set();
    try {
        const previous = new Set(JSON.parse(localStorage.getItem('fusionfix-dds-selected-v2') || '[]'));
        rows.filter(row => row.eligible && previous.has(row.id)).forEach(row => selected.add(row.id));
    } catch (_) { /* File-origin storage can be unavailable; review still works. */ }
    const number = value => Number(value).toLocaleString();
    const summary = data.summary;
    controls.summary.textContent = `${number(summary.files)} DDS files → ${number(summary.unique_versions)} distinct texture versions ` +
        `across ${number(summary.unique_names)} names. ${number(summary.duplicates)} identical copies grouped. ` +
        `${number(summary.candidates)} close matches (≥${summary.threshold}% of pixels within ${summary.tolerance}/255 per RGBA channel); ${number(summary.errors)} unsupported or damaged versions.`;
    let current = {rows: [], page: 1, pages: 1, first: 0};

    function selectionChanged() {
        const names = exportNames(rows, selected);
        controls.selection.textContent = `${number(selected.size)} versions selected · ${number(names.length)} exported names`;
        controls.export.disabled = names.length === 0;
        try { localStorage.setItem('fusionfix-dds-selected-v2', JSON.stringify([...selected])); } catch (_) {}
    }

    function element(tag, text, className) {
        const node = document.createElement(tag);
        if (text !== undefined) node.textContent = text;
        if (className) node.className = className;
        return node;
    }

    function card(row) {
        const article = element('article');
        const heading = element('h2');
        const label = element('label');
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox'; checkbox.checked = selected.has(row.id); checkbox.disabled = !row.eligible;
        checkbox.onchange = () => {
            if (checkbox.checked) selected.add(row.id); else selected.delete(row.id);
            selectionChanged();
            if (controls.view.value === 'selected') render();
        };
        label.append(checkbox, element('span', row.name)); heading.append(label); article.append(heading);
        const status = row.status === 'ok' ? `${Number(row.score).toFixed(2)}% mip match${row.candidate ? ' · Close match' : ''}` :
            (row.status === 'ineligible' ? 'No usable lower mip' : 'Unsupported or damaged');
        article.append(element('div', `Version ${row.variant}/${row.variants} · ${number(row.copies)} source copies · ${status}`, 'badge'));
        article.append(element('p', row.width ? `${row.width} × ${row.height} · ${row.mips} mips · ${row.format}` : row.path));
        if (row.preview) {
            const labels = element('div', undefined, 'labels');
            ['Whole texture', 'Mip 0 detail', row.mips > 1 ? 'Mip 0 · nearest ×½' : 'No mip 1', row.mips > 1 ? 'Actual mip 1' : ''].forEach(text => labels.append(element('span', text)));
            const image = document.createElement('img');
            image.loading = 'lazy'; image.src = row.preview;
            image.alt = `${row.name}: original texture, mip 0 detail, nearest half-size mip 0, and actual mip 1`;
            article.append(labels, image);
        } else article.append(element('p', row.preview_error || row.error || 'Preview not generated (optional preview limit).', 'error'));
        const exactText = row.max_error === 0 ? '100.00' :
            (row.exact_match_pct >= 99.995 ? '>99.99' : Number(row.exact_match_pct || 0).toFixed(2));
        if (row.status === 'ok') article.append(element('p',
            `Exact pixels: ${exactText}% · Mean RGBA error: ${Number(row.mae || 0).toFixed(3)}/255 · ` +
            `95th percentile max-channel error: ${row.p95_error || 0} · Allowed error: ${row.tolerance}/255 per channel.`));
        const sources = element('details');
        sources.append(element('summary', `${number(row.copies)} source locations`));
        const list = element('ul');
        row.sources.slice(0, 100).forEach(source => list.append(element('li', source)));
        sources.append(list);
        if (row.sources.length > 100) sources.append(element('p', 'All source locations are recorded in sources.csv.'));
        article.append(sources);
        if (row.companions.length) {
            const related = element('details');
            related.append(element('summary', 'Related map names (review separately)'), element('p', row.companions.join(', ')));
            article.append(related);
        }
        return article;
    }

    function render(reset) {
        const filtered = filterRows(rows, {search: controls.search.value, minimum: controls.score.value, size: controls.size.value,
            view: controls.view.value, sort: controls.sort.value}, selected);
        current = paginate(filtered, reset ? 1 : controls.page.value, controls['page-size'].value);
        controls.page.value = current.page; controls.page.max = current.pages;
        controls.pages.textContent = `of ${number(current.pages)}`;
        controls.previous.disabled = current.page <= 1; controls.next.disabled = current.page >= current.pages;
        controls.range.textContent = `${filtered.length ? number(current.first + 1) : 0}–${number(current.first + current.rows.length)} of ${number(filtered.length)} versions`;
        controls.empty.hidden = filtered.length !== 0;
        const fragment = document.createDocumentFragment();
        current.rows.forEach(row => fragment.append(card(row)));
        controls.grid.replaceChildren(fragment);
        selectionChanged();
    }

    for (const id of ['search', 'score']) controls[id].oninput = () => render(true);
    for (const id of ['view', 'size', 'sort', 'page-size']) controls[id].onchange = () => render(true);
    controls.page.onchange = () => render();
    controls.previous.onclick = () => { controls.page.value = current.page - 1; render(); };
    controls.next.onclick = () => { controls.page.value = current.page + 1; render(); };
    controls.select.onclick = () => { current.rows.filter(row => row.eligible).forEach(row => selected.add(row.id)); render(); };
    controls.clear.onclick = () => { selected.clear(); render(); };
    controls.export.onclick = () => {
        const names = exportNames(rows, selected);
        if (!names.length) return;
        const blob = new Blob([exportList(rows, selected)], {type: 'text/plain'});
        const link = document.createElement('a'); link.href = URL.createObjectURL(blob);
        link.download = 'MaxPayne3.FusionFix.TextureMipSkip.txt'; link.click();
        setTimeout(() => URL.revokeObjectURL(link.href), 1000);
    };
    render(true);
}
