const fs = require('fs')
const path = require('path')
const luamin = require('luamin')

const ROOT = path.join(__dirname, '../')

const header = fs.readFileSync(path.join(ROOT, 'src/header.txt'), "utf-8")
const script = fs.readFileSync(path.join(ROOT, 'src/script.lua'), "utf-8")

const BUILD_DIR = path.join(ROOT, 'build')
if( fs.existsSync(BUILD_DIR) )
	fs.rmSync(BUILD_DIR, { recursive: true })
fs.mkdirSync(BUILD_DIR)

fs.readdirSync(path.join(ROOT, 'assets')).forEach(
	f => fs.cpSync(path.join(ROOT, 'assets', f), path.join(ROOT, 'build', f), { recursive: true })
)

const minified = luamin.minify(script)

fs.writeFileSync(path.join(ROOT, 'build', 'cow.lua'), header + minified)