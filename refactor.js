const fs = require('fs');
const path = require('path');

const dashboardPath = path.join(__dirname, 'front/src/components/Dashboard.tsx');
let content = fs.readFileSync(dashboardPath, 'utf-8');

const detailStartLine = 260; // "if (selectedItem) {"
const detailEndLine = 707; // "  }"
const listStartLine = 709; // "  return ("
const listEndLine = 896; // "      </div>"
const modalsStartLine = 898; // "      {/* Modern Modal Overlay */}"
const modalsEndLine = 1231; // "    </div>"

const lines = content.split('\n');

const importsLines = lines.slice(0, 35); // imports and constants
const stateLines = lines.slice(35, 259); // from "export default function Dashboard() {" to "if (selectedItem) {"

const detailViewLines = lines.slice(detailStartLine - 1, detailEndLine);
const listViewLines = lines.slice(listStartLine - 1, listEndLine);
const modalsLines = lines.slice(modalsStartLine - 1, modalsEndLine);

console.log("Lines lengths:", {
  imports: importsLines.length,
  state: stateLines.length,
  detail: detailViewLines.length,
  list: listViewLines.length,
  modals: modalsLines.length
});
