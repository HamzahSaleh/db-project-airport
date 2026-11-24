-- airport flight system schema (sqlite)
-- run this first, then insert_data.sql

PRAGMA foreign_keys = ON;

-- drop view/indexes first, then tables in reverse FK order so nothing breaks
DROP VIEW IF EXISTS FlightBookingSummary;
DROP INDEX IF EXISTS idx_booking_date;
DROP INDEX IF EXISTS idx_flight_departure;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS Airport;
DROP TABLE IF EXISTS Airline;

CREATE TABLE Airline (
    AirlineID    INTEGER PRIMARY KEY,
    AirlineName  TEXT NOT NULL,
    IATACode     TEXT NOT NULL UNIQUE,
    Country      TEXT NOT NULL,
    CHECK (length(IATACode) = 2)
);

CREATE TABLE Airport (
    AirportID    INTEGER PRIMARY KEY,
    AirportCode  TEXT NOT NULL UNIQUE,
    AirportName  TEXT NOT NULL,
    City         TEXT NOT NULL,
    Country      TEXT NOT NULL,
    CHECK (length(AirportCode) = 3)
);

CREATE TABLE Passenger (
    PassengerID     INTEGER PRIMARY KEY,
    FirstName       TEXT NOT NULL,
    LastName        TEXT NOT NULL,
    Email           TEXT NOT NULL UNIQUE,
    DateOfBirth     TEXT NOT NULL,
    PassportNumber  TEXT NOT NULL UNIQUE,
    CHECK (DateOfBirth GLOB '????-??-??')
);

CREATE TABLE Flight (
    FlightID            INTEGER PRIMARY KEY,
    AirlineID           INTEGER NOT NULL,
    DepartureAirportID  INTEGER NOT NULL,
    ArrivalAirportID    INTEGER NOT NULL,
    FlightNumber        TEXT NOT NULL,
    DepartureDateTime   TEXT NOT NULL, -- UTC, YYYY-MM-DD HH:MM:SS
    ArrivalDateTime     TEXT NOT NULL, -- UTC, YYYY-MM-DD HH:MM:SS
    SeatCapacity        INTEGER NOT NULL CHECK (SeatCapacity > 0),
    Status              TEXT NOT NULL DEFAULT 'Scheduled'
                            CHECK (Status IN ('Scheduled', 'Delayed', 'Cancelled', 'Departed')),
    FOREIGN KEY (AirlineID) REFERENCES Airline(AirlineID),
    FOREIGN KEY (DepartureAirportID) REFERENCES Airport(AirportID),
    FOREIGN KEY (ArrivalAirportID) REFERENCES Airport(AirportID),
    CHECK (DepartureAirportID <> ArrivalAirportID),
    CHECK (ArrivalDateTime > DepartureDateTime),
    UNIQUE (FlightNumber, DepartureDateTime)
);

CREATE TABLE Booking (
    BookingID    INTEGER PRIMARY KEY,
    PassengerID  INTEGER NOT NULL,
    FlightID     INTEGER NOT NULL,
    BookingDate  TEXT NOT NULL, -- YYYY-MM-DD
    SeatNumber   TEXT NOT NULL,
    TravelClass  TEXT NOT NULL CHECK (TravelClass IN ('Economy', 'Premium Economy', 'Business', 'First')),
    FarePaid     REAL NOT NULL CHECK (FarePaid >= 0),
    IsCheckedIn  INTEGER NOT NULL DEFAULT 0 CHECK (IsCheckedIn IN (0, 1)),
    FOREIGN KEY (PassengerID) REFERENCES Passenger(PassengerID),
    FOREIGN KEY (FlightID) REFERENCES Flight(FlightID),
    UNIQUE (FlightID, SeatNumber),    -- no double booked seats
    UNIQUE (PassengerID, FlightID)   -- 1 booking per person per flight
);

-- for filtering/grouping bookings by date
CREATE INDEX idx_booking_date ON Booking(BookingDate);

-- departure board stuff filters + sorts on this
CREATE INDEX idx_flight_departure ON Flight(DepartureDateTime);

-- per flight summary: route, airline, seats booked/left, revenue
-- LEFT JOIN so flights w/ 0 bookings still show up
CREATE VIEW FlightBookingSummary AS
SELECT
    f.FlightID,
    f.FlightNumber,
    a.AirlineName,
    departure.AirportCode AS DepartureAirport,
    arrival.AirportCode AS ArrivalAirport,
    f.DepartureDateTime,
    f.ArrivalDateTime,
    f.Status,
    f.SeatCapacity,
    COUNT(b.BookingID) AS BookedSeats,
    f.SeatCapacity - COUNT(b.BookingID) AS AvailableSeats,
    COALESCE(SUM(b.FarePaid), 0) AS TotalRevenue,
    COALESCE(SUM(CASE WHEN b.IsCheckedIn = 1 THEN 1 ELSE 0 END), 0) AS CheckedInPassengers
FROM Flight AS f
JOIN Airline AS a ON a.AirlineID = f.AirlineID
JOIN Airport AS departure ON departure.AirportID = f.DepartureAirportID
JOIN Airport AS arrival ON arrival.AirportID = f.ArrivalAirportID
LEFT JOIN Booking AS b ON b.FlightID = f.FlightID
GROUP BY
    f.FlightID, f.FlightNumber, a.AirlineName,
    departure.AirportCode, arrival.AirportCode,
    f.DepartureDateTime, f.ArrivalDateTime, f.Status, f.SeatCapacity;
