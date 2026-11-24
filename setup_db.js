// Recreates airport.db from schema.sql and insert_data.sql.
const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

const DB_FILE = process.env.DB_FILE || path.join(__dirname, 'airport.db');

if (fs.existsSync(DB_FILE)) fs.unlinkSync(DB_FILE);

const db = new Database(DB_FILE);
db.exec(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8'));
db.exec(fs.readFileSync(path.join(__dirname, 'insert_data.sql'), 'utf8'));
db.close();

console.log(`Database created: ${DB_FILE}`);
