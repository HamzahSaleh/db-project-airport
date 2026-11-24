// all the sql lives here. user input always goes in through ? placeholders
const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

const DB_FILE = process.env.DB_FILE || path.join(__dirname, 'airport.db');

// errors we want to show the user as-is
class UserError extends Error {}

function open() {
  if (!fs.existsSync(DB_FILE)) throw new UserError('airport.db not found, run "npm run setup" first');
  const db = new Database(DB_FILE);
  db.pragma('foreign_keys = ON'); // sqlite has these off by default
  return db;
}

// blank code = show every flight
function searchFlights(db, code) {
  return db.prepare(`
    SELECT f.FlightID, f.FlightNumber, dep.AirportCode AS "From", arr.AirportCode AS "To",
           f.DepartureDateTime, f.Status
    FROM Flight f
    JOIN Airport dep ON dep.AirportID = f.DepartureAirportID
    JOIN Airport arr ON arr.AirportID = f.ArrivalAirportID
    WHERE ? = '' OR dep.AirportCode = ?
    ORDER BY f.DepartureDateTime`).all(code, code);
}

function getPassenger(db, email) {
  return db.prepare('SELECT * FROM Passenger WHERE Email = ?').get(email);
}

// every flight a passenger is booked on, w/ airline + airports
function itinerary(db, email) {
  return db.prepare(`
    SELECT b.BookingID, a.AirlineName, f.FlightNumber,
           dep.AirportCode AS "From", arr.AirportCode AS "To",
           f.DepartureDateTime, b.SeatNumber, b.TravelClass, b.FarePaid
    FROM Passenger p
    JOIN Booking b ON b.PassengerID = p.PassengerID
    JOIN Flight f ON f.FlightID = b.FlightID
    JOIN Airline a ON a.AirlineID = f.AirlineID
    JOIN Airport dep ON dep.AirportID = f.DepartureAirportID
    JOIN Airport arr ON arr.AirportID = f.ArrivalAirportID
    WHERE p.Email = ?
    ORDER BY f.DepartureDateTime`).all(email);
}

function addPassenger(db, first, last, email, dob, passport) {
  return db.prepare(`
    INSERT INTO Passenger (FirstName, LastName, Email, DateOfBirth, PassportNumber)
    VALUES (?, ?, ?, ?, ?)`).run(first, last, email, dob, passport).lastInsertRowid;
}

// check + insert in one transaction so two people can't grab the last seat
function bookFlight(db, passengerId, flightId, seat, travelClass, fare) {
  return db.transaction(() => {
    const f = db.prepare('SELECT Status, AvailableSeats FROM FlightBookingSummary WHERE FlightID = ?')
      .get(flightId);
    if (!f) throw new UserError('flight not found');
    if (f.Status === 'Cancelled' || f.Status === 'Departed') throw new UserError(`flight is ${f.Status.toLowerCase()}`);
    if (f.AvailableSeats <= 0) throw new UserError('flight is full');

    return db.prepare(`
      INSERT INTO Booking (PassengerID, FlightID, BookingDate, SeatNumber, TravelClass, FarePaid)
      VALUES (?, ?, date('now'), ?, ?, ?)`)
      .run(passengerId, flightId, seat, travelClass, fare).lastInsertRowid;
  })();
}

// these two return how many rows changed, 0 means the id didn't exist
function cancelBooking(db, bookingId) {
  return db.prepare('DELETE FROM Booking WHERE BookingID = ?').run(bookingId).changes;
}

function setFlightStatus(db, flightId, status) {
  return db.prepare('UPDATE Flight SET Status = ? WHERE FlightID = ?').run(status, flightId).changes;
}

// the view from deliverable 3 already does the joins + counting
function occupancyReport(db) {
  return db.prepare(`
    SELECT FlightID, FlightNumber, DepartureAirport AS "From", ArrivalAirport AS "To", Status,
           BookedSeats, SeatCapacity,
           ROUND(100.0 * BookedSeats / SeatCapacity, 1) AS PctFull, TotalRevenue
    FROM FlightBookingSummary
    ORDER BY PctFull DESC`).all();
}

module.exports = {
  UserError, open, searchFlights, getPassenger, itinerary, addPassenger,
  bookFlight, cancelBooking, setFlightStatus, occupancyReport,
};
