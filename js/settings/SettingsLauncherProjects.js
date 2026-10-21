.pragma library

// Machine-specific entries are intentionally omitted from the public defaults.
// Add personal projects in Settings → Launcher → Projects; one flat list is used.
var DEFAULT_PROJECTS = [];


function clone(value) {
    return JSON.parse(JSON.stringify(value));
}

function defaults() {
    return clone(DEFAULT_PROJECTS);
}

function singleLine(value, maxLength) {
    return String(value === undefined || value === null ? "" : value)
        .replace(/[\r\n\t]/g, " ")
        .trim()
        .slice(0, maxLength);
}

function normalize(source) {
    if (!(source instanceof Array)) return defaults();
    var result = [];
    var limit = Math.min(source.length, 200);
    for (var i = 0; i < limit; ++i) {
        var item = source[i] && typeof source[i] === "object" ? source[i] : {};
        result.push({
            icon: singleLine(item.icon, 32),
            name: singleLine(item.name, 128),
            path: singleLine(item.path, 4096),
            ide: singleLine(item.ide, 4096)
        });
    }
    return result;
}

function update(source, index, field, value) {
    var allowed = ["icon", "name", "path", "ide"];
    var result = normalize(source);
    var i = Number(index);
    if (!isFinite(i) || Math.floor(i) !== i || i < 0 || i >= result.length || allowed.indexOf(String(field)) < 0) return result;
    var item = clone(result[i]);
    var maxLength = field === "icon" ? 32 : (field === "name" ? 128 : 4096);
    item[field] = singleLine(value, maxLength);
    result[i] = item;
    return result;
}

function add(source) {
    var result = normalize(source);
    if (result.length < 200) {
        result.push({ icon: "", name: "Новый проект", path: "", ide: "goland" });
    }
    return result;
}

function remove(source, index) {
    var result = normalize(source);
    var i = Number(index);
    if (isFinite(i) && Math.floor(i) === i && i >= 0 && i < result.length) result.splice(i, 1);
    return result;
}

function move(source, index, delta) {
    var result = normalize(source);
    var i = Number(index);
    var to = i + Number(delta);
    if (!isFinite(i) || Math.floor(i) !== i || i < 0 || i >= result.length || to < 0 || to >= result.length) return result;
    var item = result.splice(i, 1)[0];
    result.splice(to, 0, item);
    return result;
}
