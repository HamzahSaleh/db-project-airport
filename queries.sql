-- queries for the airport db (sqlite)
-- dates are hardcoded so results stay the same whenever this gets run

.print '--- Req 1 ---'
-- Requirement 1: Filtering and Sorting
-- departure board for nov 3-7, only flights that are still active, earliest first
SELECT FlightNumber, DepartureDateTime, ArrivalDateTime, SeatCapacity, Status
FROM Flight
WHERE Status IN ('Scheduled', 'Delayed')
  AND DepartureDateTime >= '2026-11-03' AND DepartureDateTime < '2026-11-08'
ORDER BY DepartureDateTime;

.print ''
.print '--- Req 2 ---'
-- Requirement 2: INNER JOIN
-- passenger manifest for flight 1 (DL1201 TYS->ATL), who's sitting where
SELECT b.SeatNumber, p.FirstName, p.LastName, b.TravelClass, b.IsCheckedIn
FROM Booking b
INNER JOIN Passenger p ON p.PassengerID = b.PassengerID
WHERE b.FlightID = 1
ORDER BY b.TravelClass, b.SeatNumber;

.print ''
.print '--- Req 3 ---'
-- Requirement 3: LEFT JOIN
-- flights nobody booked yet (booking side comes back null)
SELECT f.FlightNumber, f.DepartureDateTime, f.Status
FROM Flight f
LEFT JOIN Booking b ON b.FlightID = f.FlightID
WHERE b.BookingID IS NULL;

.print ''
.print '--- Req 4 ---'
-- Requirement 4: Three-Table Join
-- full trip list for one passenger (maya chen) w/ airline + from/to airports
SELECT p.FirstName, p.LastName, a.AirlineName, f.FlightNumber,
       dep.AirportCode AS FromAirport, arr.AirportCode AS ToAirport,
       f.DepartureDateTime, b.SeatNumber, b.FarePaid
FROM Passenger p
JOIN Booking b ON b.PassengerID = p.PassengerID
JOIN Flight f ON f.FlightID = b.FlightID
JOIN Airline a ON a.AirlineID = f.AirlineID
JOIN Airport dep ON dep.AirportID = f.DepartureAirportID
JOIN Airport arr ON arr.AirportID = f.ArrivalAirportID
WHERE p.Email = 'maya.chen@example.com'
ORDER BY f.DepartureDateTime;

.print ''
.print '--- Req 5 ---'
-- Requirement 5: Aggregate Query
-- overall ticket sales numbers
SELECT COUNT(*) AS NumBookings,
       SUM(FarePaid) AS TotalRevenue,
       ROUND(AVG(FarePaid), 2) AS AvgFare,
       MIN(FarePaid) AS CheapestFare,
       MAX(FarePaid) AS PriciestFare
FROM Booking;

.print ''
.print '--- Req 6 ---'
-- Requirement 6: GROUP BY and HAVING
-- busiest airports = 3+ departing flights
SELECT ap.AirportCode, ap.City, COUNT(*) AS NumDepartures
FROM Airport ap
JOIN Flight f ON f.DepartureAirportID = ap.AirportID
GROUP BY ap.AirportID
HAVING COUNT(*) >= 3
ORDER BY NumDepartures DESC;

.print ''
.print '--- Req 7 ---'
-- Requirement 7: Subquery
-- bookings that paid more than the avg fare for their class (econ vs econ etc)
SELECT p.FirstName, p.LastName, b.FlightID, b.TravelClass, b.FarePaid
FROM Booking b
JOIN Passenger p ON p.PassengerID = b.PassengerID
WHERE b.FarePaid > (SELECT AVG(b2.FarePaid) FROM Booking b2
                    WHERE b2.TravelClass = b.TravelClass)
ORDER BY b.TravelClass, b.FarePaid DESC;

.print ''
.print '--- Req 8 ---'
-- Requirement 8: Set Operation
-- returning customers: already flew on a departed flight AND have another upcoming one
-- (sqlite wants ORDER BY on a compound select to use a column number/alias, so ORDER BY 1)
SELECT p.PassengerID, p.FirstName, p.LastName
FROM Passenger p
JOIN Booking b ON b.PassengerID = p.PassengerID
JOIN Flight f ON f.FlightID = b.FlightID
WHERE f.Status = 'Departed'
INTERSECT
SELECT p.PassengerID, p.FirstName, p.LastName
FROM Passenger p
JOIN Booking b ON b.PassengerID = p.PassengerID
JOIN Flight f ON f.FlightID = b.FlightID
WHERE f.Status IN ('Scheduled', 'Delayed')
ORDER BY 1;

.print ''
.print '--- Req 9 ---'
-- Requirement 9: View
-- how full each upcoming flight is, emptiest first
-- view does the joins + counting so this stays short
SELECT FlightNumber, AirlineName, DepartureAirport, ArrivalAirport,
       BookedSeats, AvailableSeats,
       ROUND(100.0 * BookedSeats / SeatCapacity, 1) AS PercentFull,
       TotalRevenue
FROM FlightBookingSummary
WHERE Status IN ('Scheduled', 'Delayed')
ORDER BY PercentFull;
