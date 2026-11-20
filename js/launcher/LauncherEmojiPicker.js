.pragma library

// A compact, offline emoji catalog. Search aliases intentionally include both
// English and Russian terms so the picker works without network or runtime data.
var EMOJI_ENTRIES = [
    { emoji: "😀", name: "grinning face", category: "Лица", keywords: "smile happy улыбка радость счастливый" },
    { emoji: "😃", name: "grinning face with big eyes", category: "Лица", keywords: "smile happy улыбка радость" },
    { emoji: "😄", name: "grinning face with smiling eyes", category: "Лица", keywords: "smile happy улыбка смех" },
    { emoji: "😁", name: "beaming face", category: "Лица", keywords: "grin smile зубы улыбка" },
    { emoji: "😆", name: "squinting face", category: "Лица", keywords: "laugh funny смех смешно" },
    { emoji: "😅", name: "grinning face with sweat", category: "Лица", keywords: "nervous relief sweat пот неловко" },
    { emoji: "🤣", name: "rolling on the floor laughing", category: "Лица", keywords: "rofl lol laugh смех ржу" },
    { emoji: "😂", name: "face with tears of joy", category: "Лица", keywords: "joy laugh tears слезы радость смех" },
    { emoji: "🙂", name: "slightly smiling face", category: "Лица", keywords: "smile улыбка" },
    { emoji: "🙃", name: "upside down face", category: "Лица", keywords: "silly upside перевернутый" },
    { emoji: "😉", name: "winking face", category: "Лица", keywords: "wink подмигивание подмигнуть" },
    { emoji: "😊", name: "smiling face with smiling eyes", category: "Лица", keywords: "blush shy радость румянец" },
    { emoji: "😇", name: "smiling face with halo", category: "Лица", keywords: "angel innocent ангел нимб" },
    { emoji: "🥰", name: "smiling face with hearts", category: "Лица", keywords: "love affection влюбленность любовь" },
    { emoji: "😍", name: "smiling face with heart eyes", category: "Лица", keywords: "love crush влюблен любовь глаза сердце" },
    { emoji: "🤩", name: "star struck", category: "Лица", keywords: "excited wow звездный восторг вау" },
    { emoji: "😘", name: "face blowing a kiss", category: "Лица", keywords: "kiss love поцелуй любовь" },
    { emoji: "😋", name: "face savoring food", category: "Лица", keywords: "yum delicious вкусно еда" },
    { emoji: "😜", name: "winking face with tongue", category: "Лица", keywords: "crazy silly язык шутка" },
    { emoji: "🤪", name: "zany face", category: "Лица", keywords: "crazy goofy безумный чудак" },
    { emoji: "🤔", name: "thinking face", category: "Лица", keywords: "think hmm думает задумался" },
    { emoji: "🤨", name: "face with raised eyebrow", category: "Лица", keywords: "skeptical doubtful скепсис сомнение" },
    { emoji: "😐", name: "neutral face", category: "Лица", keywords: "neutral ровно нейтральный" },
    { emoji: "🙄", name: "face with rolling eyes", category: "Лица", keywords: "eyeroll раздражение закатить глаза" },
    { emoji: "😏", name: "smirking face", category: "Лица", keywords: "smirk хитрая улыбка ухмылка" },
    { emoji: "😔", name: "pensive face", category: "Лица", keywords: "sad задумчивый грусть" },
    { emoji: "😴", name: "sleeping face", category: "Лица", keywords: "sleep tired сон спать устал" },
    { emoji: "🥱", name: "yawning face", category: "Лица", keywords: "tired sleepy зевота устал" },
    { emoji: "😢", name: "crying face", category: "Лица", keywords: "sad tear плачет грусть слеза" },
    { emoji: "😭", name: "loudly crying face", category: "Лица", keywords: "cry sob плачет рыдает" },
    { emoji: "😤", name: "face with steam from nose", category: "Лица", keywords: "triumph angry злость пар" },
    { emoji: "😡", name: "enraged face", category: "Лица", keywords: "angry mad злой злость ярость" },
    { emoji: "🤯", name: "exploding head", category: "Лица", keywords: "mind blown shock взрыв мозга шок" },
    { emoji: "🥳", name: "partying face", category: "Лица", keywords: "party birthday праздник день рождения" },
    { emoji: "😎", name: "smiling face with sunglasses", category: "Лица", keywords: "cool круто очки солнцезащитные" },
    { emoji: "🤓", name: "nerd face", category: "Лица", keywords: "geek glasses ботаник очки" },
    { emoji: "🤫", name: "shushing face", category: "Лица", keywords: "quiet silence тихо молчание" },
    { emoji: "🤗", name: "hugging face", category: "Лица", keywords: "hug embrace объятия обнять" },
    { emoji: "💀", name: "skull", category: "Лица", keywords: "death skeleton череп смерть" },
    { emoji: "👻", name: "ghost", category: "Лица", keywords: "halloween призрак привидение" },
    { emoji: "🤖", name: "robot", category: "Лица", keywords: "machine робот машина" },
    { emoji: "👍", name: "thumbs up", category: "Жесты", keywords: "like approve хорошо лайк одобрение" },
    { emoji: "👎", name: "thumbs down", category: "Жесты", keywords: "dislike bad плохо дизлайк" },
    { emoji: "👏", name: "clapping hands", category: "Жесты", keywords: "applause хлопки аплодисменты" },
    { emoji: "🙌", name: "raising hands", category: "Жесты", keywords: "celebration hooray руки вверх ура" },
    { emoji: "🙏", name: "folded hands", category: "Жесты", keywords: "please thanks prayer спасибо пожалуйста" },
    { emoji: "🤝", name: "handshake", category: "Жесты", keywords: "deal agreement рукопожатие договор" },
    { emoji: "👌", name: "OK hand", category: "Жесты", keywords: "perfect хорошо ок" },
    { emoji: "✌️", name: "victory hand", category: "Жесты", keywords: "peace victory победа мир" },
    { emoji: "🤞", name: "crossed fingers", category: "Жесты", keywords: "luck hope удача надеюсь" },
    { emoji: "👋", name: "waving hand", category: "Жесты", keywords: "hello goodbye привет пока машет" },
    { emoji: "🫶", name: "heart hands", category: "Жесты", keywords: "love heart любовь сердце руки" },
    { emoji: "💪", name: "flexed biceps", category: "Жесты", keywords: "strong muscle сила бицепс" },
    { emoji: "❤️", name: "red heart", category: "Сердца", keywords: "love heart сердце любовь красный" },
    { emoji: "🧡", name: "orange heart", category: "Сердца", keywords: "love heart сердце оранжевый" },
    { emoji: "💛", name: "yellow heart", category: "Сердца", keywords: "love heart сердце желтый" },
    { emoji: "💚", name: "green heart", category: "Сердца", keywords: "love heart сердце зеленый" },
    { emoji: "💙", name: "blue heart", category: "Сердца", keywords: "love heart сердце синий" },
    { emoji: "💜", name: "purple heart", category: "Сердца", keywords: "love heart сердце фиолетовый" },
    { emoji: "🖤", name: "black heart", category: "Сердца", keywords: "love heart сердце черный" },
    { emoji: "🤍", name: "white heart", category: "Сердца", keywords: "love heart сердце белый" },
    { emoji: "💔", name: "broken heart", category: "Сердца", keywords: "sad heartbreak разбитое сердце расставание" },
    { emoji: "💕", name: "two hearts", category: "Сердца", keywords: "love любовь два сердца" },
    { emoji: "💖", name: "sparkling heart", category: "Сердца", keywords: "love sparkle сияющее сердце" },
    { emoji: "💗", name: "growing heart", category: "Сердца", keywords: "love growing растущее сердце" },
    { emoji: "🐶", name: "dog face", category: "Животные", keywords: "puppy pet собака щенок" },
    { emoji: "🐱", name: "cat face", category: "Животные", keywords: "kitten pet кот кошка" },
    { emoji: "🐭", name: "mouse face", category: "Животные", keywords: "mouse мышь мышонок" },
    { emoji: "🐰", name: "rabbit face", category: "Животные", keywords: "bunny rabbit заяц кролик" },
    { emoji: "🦊", name: "fox", category: "Животные", keywords: "animal лиса лис" },
    { emoji: "🐻", name: "bear", category: "Животные", keywords: "animal медведь" },
    { emoji: "🐼", name: "panda", category: "Животные", keywords: "bear панда" },
    { emoji: "🐨", name: "koala", category: "Животные", keywords: "animal коала" },
    { emoji: "🐯", name: "tiger face", category: "Животные", keywords: "cat тигр тигренок" },
    { emoji: "🦁", name: "lion", category: "Животные", keywords: "king зверь лев" },
    { emoji: "🐸", name: "frog", category: "Животные", keywords: "toad лягушка" },
    { emoji: "🐵", name: "monkey face", category: "Животные", keywords: "monkey обезьяна" },
    { emoji: "🐧", name: "penguin", category: "Животные", keywords: "bird пингвин птица" },
    { emoji: "🦉", name: "owl", category: "Животные", keywords: "bird сова филин" },
    { emoji: "🦋", name: "butterfly", category: "Животные", keywords: "insect бабочка" },
    { emoji: "🐝", name: "honeybee", category: "Животные", keywords: "bee пчела" },
    { emoji: "🐢", name: "turtle", category: "Животные", keywords: "tortoise черепаха" },
    { emoji: "🐬", name: "dolphin", category: "Животные", keywords: "sea дельфин море" },
    { emoji: "🐳", name: "spouting whale", category: "Животные", keywords: "whale кит море" },
    { emoji: "🐙", name: "octopus", category: "Животные", keywords: "sea осьминог" },
    { emoji: "🦄", name: "unicorn", category: "Животные", keywords: "magic unicorn единорог магия" },
    { emoji: "🍎", name: "red apple", category: "Еда", keywords: "fruit яблоко фрукт красный" },
    { emoji: "🍊", name: "tangerine", category: "Еда", keywords: "orange fruit мандарин апельсин" },
    { emoji: "🍋", name: "lemon", category: "Еда", keywords: "fruit лимон" },
    { emoji: "🍌", name: "banana", category: "Еда", keywords: "fruit банан" },
    { emoji: "🍉", name: "watermelon", category: "Еда", keywords: "fruit арбуз" },
    { emoji: "🍇", name: "grapes", category: "Еда", keywords: "fruit виноград" },
    { emoji: "🍓", name: "strawberry", category: "Еда", keywords: "berry клубника ягода" },
    { emoji: "🍒", name: "cherries", category: "Еда", keywords: "fruit вишня черешня" },
    { emoji: "🍑", name: "peach", category: "Еда", keywords: "fruit персик" },
    { emoji: "🍍", name: "pineapple", category: "Еда", keywords: "fruit ананас" },
    { emoji: "🥑", name: "avocado", category: "Еда", keywords: "fruit avocado авокадо" },
    { emoji: "🥕", name: "carrot", category: "Еда", keywords: "vegetable морковь овощ" },
    { emoji: "🌽", name: "ear of corn", category: "Еда", keywords: "vegetable кукуруза" },
    { emoji: "🍕", name: "pizza", category: "Еда", keywords: "food пицца" },
    { emoji: "🍔", name: "hamburger", category: "Еда", keywords: "burger food бургер гамбургер" },
    { emoji: "🍟", name: "french fries", category: "Еда", keywords: "potato food картошка фри" },
    { emoji: "🍿", name: "popcorn", category: "Еда", keywords: "movie snack попкорн кино" },
    { emoji: "🍩", name: "doughnut", category: "Еда", keywords: "donut sweet пончик" },
    { emoji: "🍪", name: "cookie", category: "Еда", keywords: "biscuit sweet печенье" },
    { emoji: "🎂", name: "birthday cake", category: "Еда", keywords: "party birthday торт день рождения" },
    { emoji: "☕", name: "hot beverage", category: "Еда", keywords: "coffee tea кофе чашка чай" },
    { emoji: "🌞", name: "sun with face", category: "Природа", keywords: "sun sunny солнце солнечно" },
    { emoji: "⭐", name: "star", category: "Природа", keywords: "night sky звезда звездочка" },
    { emoji: "🌟", name: "glowing star", category: "Природа", keywords: "sparkle star сияние звезда" },
    { emoji: "✨", name: "sparkles", category: "Природа", keywords: "magic shine блеск искры сияние" },
    { emoji: "⚡", name: "high voltage", category: "Природа", keywords: "lightning energy молния энергия" },
    { emoji: "🔥", name: "fire", category: "Природа", keywords: "hot flame огонь пламя жар" },
    { emoji: "💧", name: "droplet", category: "Природа", keywords: "water капля вода" },
    { emoji: "🌈", name: "rainbow", category: "Природа", keywords: "weather радуга" },
    { emoji: "☀️", name: "sun", category: "Природа", keywords: "weather sunny солнце погода" },
    { emoji: "🌧️", name: "cloud with rain", category: "Природа", keywords: "weather дождь облако" },
    { emoji: "❄️", name: "snowflake", category: "Природа", keywords: "winter cold снег снежинка холод" },
    { emoji: "🌊", name: "water wave", category: "Природа", keywords: "sea ocean вода волна море океан" },
    { emoji: "🌸", name: "cherry blossom", category: "Природа", keywords: "flower spring цветок сакура весна" },
    { emoji: "🌹", name: "rose", category: "Природа", keywords: "flower love роза цветок любовь" },
    { emoji: "🌻", name: "sunflower", category: "Природа", keywords: "flower sunflower подсолнух цветок" },
    { emoji: "🍀", name: "four leaf clover", category: "Природа", keywords: "luck plant клевер удача" },
    { emoji: "🌳", name: "deciduous tree", category: "Природа", keywords: "tree forest дерево лес" },
    { emoji: "🎉", name: "party popper", category: "Предметы", keywords: "celebration праздник конфетти" },
    { emoji: "🎊", name: "confetti ball", category: "Предметы", keywords: "celebration праздник шар конфетти" },
    { emoji: "🎈", name: "balloon", category: "Предметы", keywords: "party birthday шарик воздушный шар" },
    { emoji: "🎁", name: "wrapped gift", category: "Предметы", keywords: "present подарок" },
    { emoji: "🏆", name: "trophy", category: "Предметы", keywords: "award win кубок награда победа" },
    { emoji: "⚽", name: "soccer ball", category: "Предметы", keywords: "football спорт футбол мяч" },
    { emoji: "🎮", name: "video game", category: "Предметы", keywords: "gaming controller игра геймпад" },
    { emoji: "🎸", name: "guitar", category: "Предметы", keywords: "music instrument гитара музыка" },
    { emoji: "🎧", name: "headphone", category: "Предметы", keywords: "music audio наушники музыка" },
    { emoji: "🎤", name: "microphone", category: "Предметы", keywords: "music karaoke микрофон караоке" },
    { emoji: "💻", name: "laptop", category: "Предметы", keywords: "computer pc ноутбук компьютер" },
    { emoji: "🖥️", name: "desktop computer", category: "Предметы", keywords: "monitor pc компьютер монитор" },
    { emoji: "📱", name: "mobile phone", category: "Предметы", keywords: "smartphone телефон смартфон" },
    { emoji: "📷", name: "camera", category: "Предметы", keywords: "photo camera фотоаппарат камера фото" },
    { emoji: "💡", name: "light bulb", category: "Предметы", keywords: "idea lamp идея лампочка" },
    { emoji: "📚", name: "books", category: "Предметы", keywords: "read library книги читать библиотека" },
    { emoji: "✏️", name: "pencil", category: "Предметы", keywords: "write school карандаш писать школа" },
    { emoji: "🔑", name: "key", category: "Предметы", keywords: "lock ключ" },
    { emoji: "🔒", name: "locked", category: "Предметы", keywords: "security private замок закрыто" },
    { emoji: "🔔", name: "bell", category: "Предметы", keywords: "notification alarm колокольчик уведомление" },
    { emoji: "⏰", name: "alarm clock", category: "Предметы", keywords: "time clock будильник часы время" },
    { emoji: "✅", name: "check mark button", category: "Символы", keywords: "done success yes готово успех галочка" },
    { emoji: "❌", name: "cross mark", category: "Символы", keywords: "no error fail крест ошибка нет" },
    { emoji: "⚠️", name: "warning", category: "Символы", keywords: "alert caution внимание предупреждение" },
    { emoji: "❗", name: "exclamation mark", category: "Символы", keywords: "important alert восклицание важно" },
    { emoji: "❓", name: "question mark", category: "Символы", keywords: "ask help вопрос знак вопроса" },
    { emoji: "💯", name: "hundred points", category: "Символы", keywords: "perfect score сто баллов идеально" },
    { emoji: "♻️", name: "recycling symbol", category: "Символы", keywords: "environment recycle переработка экология" },
    { emoji: "🚀", name: "rocket", category: "Символы", keywords: "space launch ракета космос запуск" }
];

function parseQuery(value) {
    var query = String(value === undefined || value === null ? "" : value).trim();
    var match = /^(?:emoji|emojis|эмодзи|смайлы)(?:\s+|$)/i.exec(query);
    if (!match)
        return { active: false, query: "", scope: "all" };

    var remainder = query.slice(match[0].length).trim();
    var firstSpace = remainder.search(/\s/);
    var firstToken = (firstSpace >= 0 ? remainder.slice(0, firstSpace) : remainder).toLowerCase();
    var scopeAliases = {
        favorites: "favorites", favorite: "favorites", fav: "favorites", starred: "favorites",
        "избранное": "favorites", "избранные": "favorites",
        recent: "recent", recents: "recent", recently: "recent", history: "recent", used: "recent",
        "недавние": "recent", "последние": "recent", "история": "recent"
    };
    var scope = scopeAliases[firstToken] || "all";
    if (scope !== "all")
        remainder = firstSpace >= 0 ? remainder.slice(firstSpace).trim() : "";
    return { active: true, query: remainder, scope: scope };
}

function emptyStateMessage(scope) {
    var value = String(scope || "all");
    if (value === "favorites")
        return "В избранном пока нет эмодзи. Найдите символ и нажмите звезду справа.";
    if (value === "recent")
        return "Недавних эмодзи пока нет. Скопируйте любой символ — он появится здесь.";
    return "Эмодзи не найдены. Попробуйте другое слово.";
}

var MAX_RECENT_EMOJIS = 12;
var MAX_USAGE_COUNT = 1000000;

function emptyData() {
    return { version: 1, favorites: [], usage: [] };
}

function findCatalogEntry(emoji) {
    var value = String(emoji === undefined || emoji === null ? "" : emoji);
    for (var i = 0; i < EMOJI_ENTRIES.length; ++i) {
        if (EMOJI_ENTRIES[i].emoji === value)
            return EMOJI_ENTRIES[i];
    }
    return null;
}

function normalizeData(value) {
    if (!value || typeof value !== "object")
        return emptyData();

    var favorites = [];
    var favoriteSeen = {};
    var favoriteSource = Array.isArray(value.favorites) ? value.favorites : [];
    for (var i = 0; i < favoriteSource.length; ++i) {
        var favorite = String(favoriteSource[i] === undefined || favoriteSource[i] === null ? "" : favoriteSource[i]);
        var favoriteKey = "$" + favorite;
        if (!findCatalogEntry(favorite) || favoriteSeen[favoriteKey])
            continue;
        favoriteSeen[favoriteKey] = true;
        favorites.push(favorite);
    }

    var usageByEmoji = {};
    var usageSource = Array.isArray(value.usage) ? value.usage : [];
    for (var j = 0; j < usageSource.length; ++j) {
        var item = usageSource[j];
        if (!item || typeof item !== "object")
            continue;
        var emoji = String(item.emoji === undefined || item.emoji === null ? "" : item.emoji);
        if (!findCatalogEntry(emoji))
            continue;
        var count = Math.max(0, Math.min(MAX_USAGE_COUNT, Math.floor(Number(item.count) || 0)));
        var lastUsed = Math.max(0, Math.floor(Number(item.lastUsed) || 0));
        if (count < 1)
            continue;
        var key = "$" + emoji;
        var previous = usageByEmoji[key];
        if (!previous) {
            usageByEmoji[key] = { emoji: emoji, count: count, lastUsed: lastUsed };
        } else {
            previous.count = Math.min(MAX_USAGE_COUNT, previous.count + count);
            previous.lastUsed = Math.max(previous.lastUsed, lastUsed);
        }
    }

    var usage = [];
    for (var usageKey in usageByEmoji) {
        if (Object.prototype.hasOwnProperty.call(usageByEmoji, usageKey))
            usage.push(usageByEmoji[usageKey]);
    }
    usage.sort(function(a, b) {
        if (b.lastUsed !== a.lastUsed) return b.lastUsed - a.lastUsed;
        if (b.count !== a.count) return b.count - a.count;
        return a.emoji.localeCompare(b.emoji);
    });

    return { version: 1, favorites: favorites, usage: usage };
}

function parseData(contents) {
    var parsed = null;
    try {
        parsed = JSON.parse(String(contents === undefined || contents === null ? "" : contents));
    } catch (error) {
        return emptyData();
    }
    return normalizeData(parsed);
}

function toggleFavorite(data, emoji) {
    var normalized = normalizeData(data);
    var value = String(emoji === undefined || emoji === null ? "" : emoji);
    if (!findCatalogEntry(value))
        return normalized;

    var favorites = normalized.favorites.slice();
    var index = favorites.indexOf(value);
    if (index >= 0)
        favorites.splice(index, 1);
    else
        favorites.push(value);
    return { version: 1, favorites: favorites, usage: normalized.usage };
}

function recordUsage(data, emoji, timestamp) {
    var normalized = normalizeData(data);
    var value = String(emoji === undefined || emoji === null ? "" : emoji);
    if (!findCatalogEntry(value))
        return normalized;

    var usedAt = Math.max(1, Math.floor(Number(timestamp) || Date.now()));
    var usage = normalized.usage.slice();
    var found = false;
    for (var i = 0; i < usage.length; ++i) {
        if (usage[i].emoji !== value)
            continue;
        usage[i] = {
            emoji: value,
            count: Math.min(MAX_USAGE_COUNT, usage[i].count + 1),
            lastUsed: usedAt
        };
        found = true;
        break;
    }
    if (!found)
        usage.push({ emoji: value, count: 1, lastUsed: usedAt });

    usage.sort(function(a, b) {
        if (b.lastUsed !== a.lastUsed) return b.lastUsed - a.lastUsed;
        if (b.count !== a.count) return b.count - a.count;
        return a.emoji.localeCompare(b.emoji);
    });
    return { version: 1, favorites: normalized.favorites, usage: usage };
}

function applyMutations(data, mutations) {
    var result = normalizeData(data);
    var changes = Array.isArray(mutations) ? mutations : [];
    for (var i = 0; i < changes.length; ++i) {
        var mutation = changes[i] || {};
        var type = String(mutation.type || "");
        var emoji = String(mutation.emoji === undefined || mutation.emoji === null ? "" : mutation.emoji);
        if (type === "toggleFavorite")
            result = toggleFavorite(result, emoji);
        else if (type === "recordUsage")
            result = recordUsage(result, emoji, mutation.timestamp);
    }
    return result;
}

function serializeData(data) {
    return JSON.stringify(normalizeData(data));
}

function buildResults(query, scoreFunction, maxResults, storedData, scope) {
    var normalized = String(query === undefined || query === null ? "" : query).toLowerCase().trim();
    var limit = Math.max(1, Math.min(200, Math.floor(Number(maxResults) || 80)));
    var data = normalizeData(storedData);
    var selectedScope = String(scope || "all");
    if (selectedScope !== "favorites" && selectedScope !== "recent")
        selectedScope = "all";
    var favoriteOrder = {};
    var usageByEmoji = {};
    var recentOrder = {};
    var results = [];

    for (var f = 0; f < data.favorites.length; ++f)
        favoriteOrder["$" + data.favorites[f]] = f;
    for (var u = 0; u < data.usage.length; ++u)
        usageByEmoji["$" + data.usage[u].emoji] = data.usage[u];

    // The most recently copied non-favourites get a compact quick-access area.
    var recentCount = 0;
    for (var r = 0; r < data.usage.length && recentCount < MAX_RECENT_EMOJIS; ++r) {
        var recentEmoji = data.usage[r].emoji;
        if (favoriteOrder["$" + recentEmoji] !== undefined)
            continue;
        recentOrder["$" + recentEmoji] = recentCount++;
    }

    for (var i = 0; i < EMOJI_ENTRIES.length; ++i) {
        var entry = EMOJI_ENTRIES[i];
        var key = "$" + entry.emoji;
        var isFavorite = favoriteOrder[key] !== undefined;
        var usage = usageByEmoji[key] || { count: 0, lastUsed: 0 };
        var isRecent = recentOrder[key] !== undefined;
        if (selectedScope === "favorites" && !isFavorite)
            continue;
        if (selectedScope === "recent" && !isRecent)
            continue;
        var searchable = entry.name + " " + entry.keywords + " " + entry.category;
        var score = normalized === "" ? 0 : (typeof scoreFunction === "function"
            ? Number(scoreFunction(searchable, normalized))
            : (searchable.toLowerCase().indexOf(normalized) >= 0 ? 1 : -1));
        if (!Number.isFinite(score) || score < 0)
            continue;
        results.push({
            kind: "emoji",
            emoji: entry.emoji,
            name: entry.name,
            category: entry.category,
            keywords: entry.keywords,
            score: score,
            order: i,
            isFavorite: isFavorite,
            favoriteOrder: isFavorite ? favoriteOrder[key] : -1,
            usageCount: usage.count,
            lastUsed: usage.lastUsed,
            isRecent: isRecent,
            recentOrder: isRecent ? recentOrder[key] : -1
        });
    }

    if (normalized !== "") {
        results.sort(function(a, b) {
            if (b.score !== a.score) return b.score - a.score;
            if (a.isFavorite !== b.isFavorite) return a.isFavorite ? -1 : 1;
            if (b.usageCount !== a.usageCount) return b.usageCount - a.usageCount;
            if (b.lastUsed !== a.lastUsed) return b.lastUsed - a.lastUsed;
            return a.order - b.order;
        });
    } else {
        results.sort(function(a, b) {
            var aGroup = a.isFavorite ? 0 : (a.isRecent ? 1 : 2);
            var bGroup = b.isFavorite ? 0 : (b.isRecent ? 1 : 2);
            if (aGroup !== bGroup) return aGroup - bGroup;
            if (aGroup === 0 && a.favoriteOrder !== b.favoriteOrder)
                return b.favoriteOrder - a.favoriteOrder;
            if (aGroup === 1 && a.recentOrder !== b.recentOrder)
                return a.recentOrder - b.recentOrder;
            return a.order - b.order;
        });
    }
    return results.slice(0, limit);
}
