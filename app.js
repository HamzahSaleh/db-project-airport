// airport flight system - menu app
const readline = require('readline');
const db = require('./db');

const STATUSES = ['Scheduled', 'Delayed', 'Cancelled', 'Departed'];
const CLASSES = ['Economy', 'Premium Economy', 'Business', 'First'];

// reading lines this way instead of rl.question so piped input works too
const rl = readline.createInterface({ input: process.stdin });
const lines = rl[Symbol.asyncIterator]();

async function ask(prompt) {
  process.stdout.write(prompt);
  const { value, done } = await lines.next();
  if (done) throw new Error('EOF');
  return value.trim();
}

// --- input helpers, they throw if the input is bad ---
function fail(msg) {
  throw new db.UserError(msg);
}

async function askText(prompt) {
  const v = await ask(prompt);
  if (!v) fail('this field is required');
  return v;
}

async function askId(prompt) {
  const v = await ask(prompt);
  if (!/^[1-9]\d*$/.test(v)) fail('enter a positive whole number');
  return Number(v);
}

async function askChoice(prompt, options) {
  options.forEach((o, i) => console.log(`  ${i + 1}) ${o}`));
  const n = await askId(prompt);
  if (n > options.length) fail('not one of the options');
  return options[n - 1];
}

function show(rows) {
  if (rows.length) console.table(rows);
  else console.log('nothing found');
}

// --- menu options ---
async function searchFlights(conn) {
  const code = (await ask('departure airport code (like BNA, blank = all): ')).toUpperCase();
  if (code && !/^[A-Z]{3}$/.test(code)) fail('airport codes are 3 letters');
  show(db.searchFlights(conn, code));
}

async function viewItinerary(conn) {
  const email = await askText('passenger email: ');
  if (!db.getPassenger(conn, email)) fail('no passenger with that email');
  show(db.itinerary(conn, email));
}

async function addPassenger(conn) {
  const first = await askText('first name: ');
  const last = await askText('last name: ');
  const email = await askText('email: ');
  if (!/^\S+@\S+\.\S+$/.test(email)) fail('that email doesn\'t look right');
  const dob = await askText('date of birth (YYYY-MM-DD): ');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dob) || isNaN(Date.parse(dob))) fail('date has to be YYYY-MM-DD');
  const passport = await askText('passport number: ');

  const id = db.addPassenger(conn, first, last, email, dob, passport);
  console.log(`added passenger #${id}`);
}

async function bookFlight(conn) {
  const p = db.getPassenger(conn, await askText('passenger email: '));
  if (!p) fail('no passenger with that email, add them first');
  const flightId = await askId('flight id (from search): ');
  const seat = (await askText('seat (like 12A): ')).toUpperCase();
  const travelClass = await askChoice('class: ', CLASSES);
  const fare = Number(await askText('fare paid: '));
  if (isNaN(fare) || fare < 0) fail('fare has to be a number >= 0');

  const id = db.bookFlight(conn, p.PassengerID, flightId, seat, travelClass, fare);
  console.log(`booked, booking #${id}`);
}

async function cancelBooking(conn) {
  const id = await askId('booking id: ');
  if ((await ask('are you sure? (y/n): ')).toLowerCase() !== 'y') return console.log('ok, not cancelled');
  if (!db.cancelBooking(conn, id)) fail('booking not found');
  console.log('booking cancelled');
}

async function updateStatus(conn) {
  const id = await askId('flight id: ');
  const status = await askChoice('new status: ', STATUSES);
  if (!db.setFlightStatus(conn, id, status)) fail('flight not found');
  console.log(`flight ${id} is now ${status}`);
}

async function report(conn) {
  show(db.occupancyReport(conn));
}

const MENU = [
  ['Search flights', searchFlights],
  ['View passenger itinerary', viewItinerary],
  ['Add passenger', addPassenger],
  ['Book a flight', bookFlight],
  ['Cancel a booking', cancelBooking],
  ['Update flight status', updateStatus],
  ['Flight occupancy report', report],
];

// turn sqlite errors into something readable instead of a stack trace
function errorMessage(err) {
  if (err instanceof db.UserError) return err.message;
  const msg = err.message || '';
  if (msg.includes('UNIQUE')) {
    if (msg.includes('Email')) return 'that email is already used';
    if (msg.includes('PassportNumber')) return 'that passport number is already used';
    if (msg.includes('SeatNumber')) return 'that seat is taken';
    if (msg.includes('PassengerID')) return 'passenger is already on this flight';
    return 'duplicate record';
  }
  if (msg.includes('FOREIGN KEY')) return 'that record doesn\'t exist';
  if (msg.includes('CHECK')) return 'value not allowed';
  return 'something went wrong with the database';
}

async function main() {
  let conn;
  try {
    conn = db.open();
  } catch (err) {
    console.log(errorMessage(err));
    return rl.close();
  }

  try {
    while (true) {
      console.log('\n--- Airport Flight System ---');
      MENU.forEach(([name], i) => console.log(`${i + 1}) ${name}`));
      console.log('0) Exit');

      const choice = await ask('> ');
      if (choice === '0') break;
      const option = MENU[Number(choice) - 1];
      if (!option) {
        console.log('invalid option');
        continue;
      }

      try {
        await option[1](conn);
      } catch (err) {
        if (err.message === 'EOF') throw err;
        console.log('error: ' + errorMessage(err));
      }
    }
  } catch (err) {
    if (err.message !== 'EOF') throw err; // EOF = input closed, just quit
  } finally {
    conn.close();
    rl.close();
    console.log('bye');
  }
}

main();
