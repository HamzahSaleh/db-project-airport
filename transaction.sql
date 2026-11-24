-- transaction demo
-- flight 3 (AA2301 BNA->DFW) gets cancelled -> add replacement flight next day,
-- move the bookings, cancel flight 3. all or nothing so nobody's stuck on a cancelled flight
-- ends w/ ROLLBACK so sample data doesnt change (use COMMIT to keep it)
-- -bail = quit on error before commit, sqlite rolls it back

PRAGMA foreign_keys = ON;

.print 'before:'
SELECT FlightID, FlightNumber, DepartureDateTime, Status, BookedSeats
FROM FlightBookingSummary WHERE FlightNumber = 'AA2301';

BEGIN TRANSACTION;

-- replacement flight (id 25), same route next day
INSERT INTO Flight (FlightID, AirlineID, DepartureAirportID, ArrivalAirportID,
    FlightNumber, DepartureDateTime, ArrivalDateTime, SeatCapacity, Status)
VALUES (25, 3, 1, 7, 'AA2301', '2026-11-04 14:00:00', '2026-11-04 16:15:00', 160, 'Scheduled');

-- move the passengers over
UPDATE Booking SET FlightID = 25 WHERE FlightID = 3;

-- cancel the original
UPDATE Flight SET Status = 'Cancelled' WHERE FlightID = 3;

.print ''
.print 'during (not committed yet):'
SELECT FlightID, FlightNumber, DepartureDateTime, Status, BookedSeats
FROM FlightBookingSummary WHERE FlightNumber = 'AA2301';

ROLLBACK;

.print ''
.print 'after rollback (back to normal):'
SELECT FlightID, FlightNumber, DepartureDateTime, Status, BookedSeats
FROM FlightBookingSummary WHERE FlightNumber = 'AA2301';
