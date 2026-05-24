const fs = require('fs');
const path = require('path');

function redesignFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');

    // Backgrounds
    content = content.replace(/bg-\[#06070a\]/g, 'bg-slate-950');
    content = content.replace(/bg-\[#0f111a\]/g, 'bg-slate-900');
    
    // Borders
    content = content.replace(/border-white\/5/g, 'border-slate-800');
    content = content.replace(/border-white\/10/g, 'border-slate-700');
    
    // Radii
    content = content.replace(/rounded-\[2\.5rem\]/g, 'rounded-2xl');
    content = content.replace(/rounded-\[3rem\]/g, 'rounded-2xl');
    content = content.replace(/rounded-\[4rem\]/g, 'rounded-2xl');
    content = content.replace(/rounded-3xl/g, 'rounded-xl');
    
    // Padding
    content = content.replace(/p-10/g, 'p-6');
    content = content.replace(/p-12/g, 'p-6');
    content = content.replace(/px-10/g, 'px-6');
    content = content.replace(/py-5/g, 'py-3');
    
    // Typography
    content = content.replace(/text-3xl/g, 'text-xl');
    content = content.replace(/text-gray-100/g, 'text-slate-200');
    content = content.replace(/text-gray-500/g, 'text-slate-400');
    content = content.replace(/text-gray-200/g, 'text-slate-300');
    content = content.replace(/text-white/g, 'text-slate-50');
    
    // Elements
    content = content.replace(/bg-white\/2/g, 'bg-slate-800/40');
    content = content.replace(/bg-white\/5/g, 'bg-slate-800');
    content = content.replace(/hover:bg-white\/5/g, 'hover:bg-slate-800');

    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Redesigned ${filePath}`);
}

const basePath = path.join(__dirname, 'front', 'src', 'components');
redesignFile(path.join(basePath, 'Dashboard.tsx'));
redesignFile(path.join(basePath, 'EntityModal.tsx'));
