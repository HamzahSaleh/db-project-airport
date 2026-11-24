# Airport Flight System – Final Project

## Project Overview
A menu-driven command-line application for managing airline flights and passenger bookings.

- **What it does:** stores airlines, airports, flights, passengers, and bookings, and lets the user search flights, book and cancel seats, update flight status, and view an occupancy and revenue report.
- **Intended users:** airport or airline staff (gate agents, booking clerks) who manage flights and reservations.
- **Major functionality:** flight search, passenger itineraries (related data across 6 tables), adding passengers, booking flights inside a transaction, cancelling bookings, updating flight status, and a flight occupancy report built on a view.

## DBMS
**SQLite 3**, a local file-based relational database. There is no server, account, or hosted service.

## Repository Contents
| File | Purpose |
|---|---|
| `erd.png` | Final ER diagram (matches `schema.sql`) |
| `schema.sql` | Creates the 5 tables, constraints, 2 indexes, and the `FlightBookingSummary` view |
| `insert_data.sql` | Sample data: 8 airlines, 14 airports, 30 passengers, 24 flights, 55 bookings (all fictional) |
| `queries.sql` | 9 required queries (filter/sort, inner join, left join, multi-table join, aggregate, GROUP BY/HAVING, subquery, set operation, view) |
| `transaction.sql` | Transaction example: replaces a cancelled flight and moves its bookings (ends in `ROLLBACK`) |
| `run_queries.sh` | Rebuilds the database and runs `queries.sql` and `transaction.sql` |
| `app.js` | Application: menu, prompts, input validation, error messages |
| `db.js` | Application: database connection and all SQL (parameterized) |
| `setup_db.js` | Recreates `airport.db` from `schema.sql` + `insert_data.sql` |
| `package.json`, `package-lock.json` | Node.js dependency information |
| `.env.example` | Configuration template (the only setting is optional) |

## Database Setup
**Required software:** Node.js 18 or newer (tested on 20.8.0, npm included). The `sqlite3` command-line tool is also needed, but only to run `queries.sql` and `transaction.sql` ([download](https://sqlite.org/download.html), or install with a package manager).

SQL files must run in this order: **1. `schema.sql` → 2. `insert_data.sql` → 3. `queries.sql` / `transaction.sql`**

**Option A: with Node (no sqlite3 tool needed)**
```
npm install
npm run setup        # deletes and recreates airport.db from schema.sql, then insert_data.sql
```

**Option B: with the sqlite3 tool**
```
sqlite3 airport.db < schema.sql
sqlite3 airport.db < insert_data.sql
```

**Run the queries and transaction:**
```
sqlite3 -header -column airport.db < queries.sql
sqlite3 -bail -header -column airport.db < transaction.sql
```
Or run `bash run_queries.sh`, which rebuilds the database and runs both files (on Windows, use Git Bash).

SQLite-specific notes:
- `schema.sql` drops and recreates everything, so it is safe to re-run.
- Foreign keys are off by default in SQLite. The SQL files and the app turn them on with `PRAGMA foreign_keys = ON`.
- `queries.sql` and `transaction.sql` use the sqlite3 shell's `.print` command for labels, so run them with the `sqlite3` tool.
- `transaction.sql` ends with `ROLLBACK` so the sample data stays unchanged. Change it to `COMMIT` to keep the changes.

## Application Setup
- **Language:** JavaScript (Node.js)
- **Package:** `better-sqlite3`, the SQLite driver (listed in `package.json`)

```
npm install          # 1. install better-sqlite3
npm run setup        # 2. create airport.db with sample data
npm start            # 3. start the menu application
```

**Database connection / configuration:** SQLite is a local file, so there are **no usernames, passwords, hosts, or API keys**, and no secrets are stored in this repository. By default the app connects to `airport.db` in the project folder. The only setting is the optional `DB_FILE` (shown in `.env.example`). Set it as an environment variable to use a different database file:
- PowerShell: `$env:DB_FILE="C:\path\my.db"; npm run setup; npm start`
- bash: `DB_FILE=/path/my.db npm run setup && DB_FILE=/path/my.db npm start`

Running `npm run setup` again resets the database to the original sample data.

## Major Application Operations
| # | Menu option | Category | SQL used |
|---|---|---|---|
| 1 | Search flights | Search / browse | SELECT with WHERE + ORDER BY |
| 2 | View passenger itinerary | Related data | 6-table JOIN (Passenger, Booking, Flight, Airline, Airport ×2) |
| 3 | Add passenger | Add data | INSERT |
| 4 | Book a flight | Add data (transaction) | Checks flight status and free seats, then INSERTs into Booking |
| 5 | Cancel a booking | Delete | DELETE |
| 6 | Update flight status | Modify | UPDATE |
| 7 | Flight occupancy report | Summary / report | `FlightBookingSummary` view (JOIN + COUNT/SUM + GROUP BY) |
| 0 | Exit | | Closes the database connection |

Sample values to try: airport code `BNA`, email `maya.chen@example.com`, flight ID `18`.

**Showing that changes are saved:** add a passenger (3), book them on flight 18 (4), and exit (0). Start the app again and look them up with option 2, or run option 7. The new booking is still there. You can also check from outside the app:
`sqlite3 airport.db "SELECT * FROM Booking ORDER BY BookingID DESC LIMIT 1;"`

**Validation and safety:**
- All user input is passed to SQL through `?` placeholders (prepared statements). User input is never concatenated into SQL.
- The app rejects bad input (invalid menu choices, empty fields, non-numeric IDs or fares, bad email or date formats, airport codes that are not 3 letters).
- Database errors become clear messages instead of crashes. Examples: duplicate email or passport, seat already taken, passenger already on the flight, missing records, CHECK violations.
- Booking runs in a transaction. If any step fails (flight cancelled or departed, flight full, seat taken), nothing is saved.

## Known Limitations
- Single-user command-line app with no login or user roles.
- Times are stored as text in UTC (`YYYY-MM-DD HH:MM:SS`). Time zones are not converted.
- Seat numbers are free text and are not checked against a seat map. Only uniqueness per flight is enforced.
- No menu options for editing airlines, airports, or flights other than flight status. That data comes from `insert_data.sql`.
- Otherwise, there are no known problems.
