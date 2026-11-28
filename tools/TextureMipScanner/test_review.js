const assert = require('assert');
const {filterRows, paginate, exportNames, exportList} = require('./review.js');

const rows = Array.from({length: 437}, (_, index) => ({
    id: `v${index}`, name: `texture_${String(index).padStart(3, '0')}`,
    search: `texture_${String(index).padStart(3, '0')} level/example.wtd`,
    variant: 1, variants: 1, copies: 1, score: index % 100,
    candidate: index % 100 >= 60, eligible: true, status: 'ok',
}));
const selected = new Set(['v0', 'v200', 'v436']);
const all = filterRows(rows, {view: 'all', minimum: 0, sort: 'name'}, selected);
assert.strictEqual(all.length, 437); // No old 200-card cap or candidate cutoff.
assert.strictEqual(paginate(all, 8, 60).rows.length, 17);
assert.strictEqual(paginate(all, 9999, 60).page, 8);
assert.strictEqual(filterRows(rows, {view: 'selected'}, selected).length, 3);
assert(filterRows(rows, {view: 'candidates'}, selected).every(row => row.candidate));
assert.strictEqual(filterRows(rows, {search: 'EXAMPLE.WTD', view: 'all'}, selected).length, 437);
assert.strictEqual(filterRows(rows, {search: 'missing', view: 'all'}, selected).length, 0);
assert.strictEqual(filterRows(rows, {view: 'variants'}, selected).length, 0);
assert.strictEqual(filterRows([{...rows[0], variants: 2}, {...rows[1], variants: 2}, rows[2]],
    {view: 'variants'}, selected).length, 2);
assert.strictEqual(filterRows([{...rows[0], width: 1024, height: 1024}, {...rows[1], width: 256, height: 256}],
    {size: 1024}, selected).length, 1);
const sizes = [[128,128], [128,256], [64,1024], [127,128], [256,64]].map(([width,height], i) => ({...rows[i],width,height}));
assert.strictEqual(filterRows(sizes, {size:128}, selected).length, 2);
assert.strictEqual(filterRows(sizes, {size:0}, selected).length, 5);
assert.strictEqual(filterRows(sizes, {size:1024}, selected).length, 0);
assert.strictEqual(filterRows([{...rows[0], max_error: 0}, {...rows[1], max_error: 1, exact_match_pct: 100}],
    {view: 'exact'}, selected).length, 1);
assert.deepStrictEqual(exportNames([
    {id: 'a', name: 'wall_dm', eligible: true},
    {id: 'b', name: 'wall_dm', eligible: true},
    {id: 'c', name: 'WALL_DM', eligible: true},
    {id: 'bad', name: 'broken', eligible: false},
], new Set(['a', 'b', 'c', 'bad'])), ['WALL_DM']);
console.log('All-version filtering, pagination and name-based export passed.');
const sourced = exportList([
    {id:'a',name:'wall_dm',eligible:true,sources:['archive.rpf/a.wtd/wall_dm.dds']},
    {id:'b',name:'wall_dm',eligible:true,sources:['archive.rpf/a.wtd/wall_dm.dds','archive.rpf/b.wdr/wall_dm.dds']},
    {id:'c',name:'wall_dm',eligible:true,sources:['unselected.wtd/wall_dm.dds']},
], new Set(['a','b']));
assert(sourced.includes('wall_dm\n# Source: archive.rpf/a.wtd/wall_dm.dds\n# Source: archive.rpf/b.wdr/wall_dm.dds\n'));
assert(!sourced.includes('unselected'));
assert.strictEqual(sourced.split('\n').filter(line=>line==='wall_dm').length, 1);
assert.strictEqual(sourced.split('\n').filter(line=>line==='# Source: archive.rpf/a.wtd/wall_dm.dds').length, 1);

// Exercise the real browser initialization and event handlers with a small DOM
// stand-in: this catches render-time failures that pure filtering tests miss.
const fs = require('fs'), vm = require('vm'), path = require('path');
class Node {
    constructor(tag = 'div') { this.tag = tag; this.children = []; this.value = ''; }
    append(...nodes) { this.children.push(...nodes); }
    replaceChildren(fragment) { this.children = fragment.children; }
    click() { if (this.onclick) this.onclick(); }
}
const ids = ['search', 'view', 'score', 'size', 'sort', 'select', 'clear', 'export', 'selection',
    'previous', 'next', 'page', 'pages', 'page-size', 'range', 'grid', 'empty', 'summary'];
const controls = Object.fromEntries(ids.map(id => [id, new Node()]));
Object.assign(controls.view, {value: 'all'}); Object.assign(controls.score, {value: '0'});
Object.assign(controls.sort, {value: 'name'}); Object.assign(controls.page, {value: '1'});
Object.assign(controls.size, {value:'128'});
Object.assign(controls['page-size'], {value: '60'});
const browserRows = rows.map(row => ({...row, sources: [`level/${row.name}.wtd/${row.name}.dds`],
    companions: [], width: 128, height: 128, mips: 2, format: 'DXT1', preview: '', mip1_score: 0, axis: 'x'}));
let exported = '';
const context = {
    document: {
        querySelector: () => ({textContent: JSON.stringify({summary: {files: 1000, unique_versions: 437,
            unique_names: 437, duplicates: 563, candidates: 160, threshold: 60, errors: 0}, rows: browserRows})}),
        getElementById: id => controls[id], createElement: tag => new Node(tag),
        createDocumentFragment: () => new Node('fragment'),
    },
    localStorage: {getItem: () => null, setItem: () => {}},
    Blob: class {constructor(parts) { exported = parts.join(''); }},
    URL: {createObjectURL: () => 'blob:test', revokeObjectURL: () => {}}, setTimeout: fn => fn(),
};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, 'review.js'), 'utf8'), context);
assert.strictEqual(controls.grid.children.length, 60);
assert(controls.range.textContent.endsWith('of 437 versions'));
controls.search.value = '128x128'; controls.search.oninput();
assert(controls.range.textContent.endsWith('of 437 versions'));
controls.search.value = ''; controls.search.oninput();
controls.page.value = 8; controls.page.onchange();
assert.strictEqual(controls.grid.children.length, 17);
controls.select.onclick(); controls.export.onclick();
assert(exported.includes('texture_436\n'));
assert.strictEqual(exported.split('\n').filter(line=>line&& !line.startsWith('#')).length, 17);
assert(exported.includes('texture_436\n# Source: level/texture_436.wtd/texture_436.dds'));
controls.search.value = 'missing'; controls.search.oninput();
assert.strictEqual(controls.grid.children.length, 0);
assert.strictEqual(controls.empty.hidden, false);
console.log('Report initialization, real page handlers and export passed.');
