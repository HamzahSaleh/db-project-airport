#!/bin/bash
# rebuilds airport.db and runs the queries + transaction (needs sqlite3)

DB="airport.db"

echo "Recreating database..."

rm -f "$DB"

sqlite3 "$DB" < schema.sql
sqlite3 "$DB" < insert_data.sql

echo
echo "Running queries..."

sqlite3 -header -column "$DB" < queries.sql

echo
echo "Running transaction..."

sqlite3 -bail -header -column "$DB" < transaction.sql
status=$?

if [ "$status" -eq 0 ]; then
    echo "Transaction completed successfully."
else
    echo "Transaction failed."
    echo "Uncommitted changes were rolled back."
fi

echo
echo "Done."
