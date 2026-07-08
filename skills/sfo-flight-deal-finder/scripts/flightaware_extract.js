// Paste this into browser_console() after navigating to:
// https://www.flightaware.com/live/findflight?origin=SFO&destination=XXX
//
// Returns a JSON array of all flights visible in the results table.
// Filter by day using the 'depart' field (e.g. .filter(f => f.depart.includes('Wed')))

const rows = document.querySelectorAll('table tr');
const flights = [];
rows.forEach(row => {
  const cells = row.querySelectorAll('td');
  if (cells.length >= 6) {
    const depart = cells[4]?.innerText?.trim();
    const arrive = cells[6]?.innerText?.trim();
    if (depart && arrive) {
      flights.push({
        airline:    cells[0]?.innerText?.trim(),
        ident:      cells[1]?.innerText?.trim(),
        aircraft:   cells[2]?.innerText?.trim(),
        origin:     cells[3]?.innerText?.trim(),
        depart:     depart,
        dest:       cells[5]?.innerText?.trim(),
        arrive:     arrive,
        connection: cells[7]?.innerText?.trim() || 'nonstop'
      });
    }
  }
});
JSON.stringify(flights, null, 2);
