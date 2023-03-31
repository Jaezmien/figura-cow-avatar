const fs = require('fs');
const path = require('path');
const luamin = require('luamin');

const ROOT = path.join(__dirname, '../');
const BUILD_DIR = path.join(ROOT, 'build');

function mkdir(p) {
	if (!fs.existsSync(p)) fs.mkdirSync(p);
}

if (fs.existsSync(BUILD_DIR)) fs.rmSync(BUILD_DIR, { recursive: true });

fs.mkdirSync(BUILD_DIR);
mkdir(path.join(BUILD_DIR, 'libs'));

fs.readdirSync(path.join(ROOT, 'assets')).forEach((f) =>
	fs.cpSync(path.join(ROOT, 'assets', f), path.join(BUILD_DIR, f), { recursive: true })
);

function minify_script(p, header) {
	const minified = luamin.minify(fs.readFileSync(path.join(ROOT, 'src/', p), 'utf-8'));
	fs.writeFileSync(path.join(BUILD_DIR, p), header + minified);
}

minify_script(
	'libs/GNanim.lua',
	`-- GNanim.lua
-- By: GNamimates, slightly modified for rc13 support\n`
);

minify_script(
	'libs/TimerAPI.lua',
	`-- TimerAPI.lua
-- By: KitCat962 + GNamimates\n`
);

minify_script(
	'cow.lua',
	`-- Figura - Cow Model v1.4.2
-- Requires: rc12+
-- Authors:
-- + Jaezmien Naejara
-- + winterClover - Based the model on their Customized Pony Models v2
-- + Rels / Atsuya#7987 - Added armor support
-- Want the un-minified version? Check it out at https://github.com/Jaezmien/figura-cow-avatar\n\n`
);
