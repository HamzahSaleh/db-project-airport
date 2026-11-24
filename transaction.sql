-- Deliverable 4 transaction
-- scenario: flight 3 (AA2301 BNA->DFW) gets cancelled, so we add a replacement
-- flight the next day, move everyone's bookings over, and mark flight 3 cancelled.
-- these have to happen together, otherwise people could end up booked on a
-- cancelled flight. ends w/ ROLLBACK so the sample data doesnt actually change
-- (swap to COMMIT to keep it). if something errors, -bail quits before commit
-- and sqlite rolls it back

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
