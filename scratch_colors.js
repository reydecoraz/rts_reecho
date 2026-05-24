const fs = require('fs');
const path = require('path');

function recolorFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');

    // Change Indigo to Yellow (App primary color)
    content = content.replace(/indigo-600/g, 'yellow-600');
    content = content.replace(/indigo-500/g, 'yellow-500');
    content = content.replace(/indigo-400/g, 'yellow-400');
    content = content.replace(/indigo-900/g, 'yellow-900');

    // Change Emerald to Green (App secondary color)
    content = content.replace(/emerald-600/g, 'green-600');
    content = content.replace(/emerald-500/g, 'green-500');

    // Change Purple to Purple (Already matches app)
    // No change needed for purple

    // Change Slate to Zinc (More neutral/darker black)
    content = content.replace(/slate-950/g, 'zinc-950');
    content = content.replace(/slate-900/g, 'zinc-900');
    content = content.replace(/slate-800/g, 'zinc-900'); // make cards very dark
    content = content.replace(/slate-700/g, 'zinc-800');
    content = content.replace(/slate-400/g, 'zinc-400');
    content = content.replace(/slate-300/g, 'zinc-300');
    content = content.replace(/slate-200/g, 'zinc-200');
    content = content.replace(/slate-100/g, 'zinc-100');
    content = content.replace(/slate-50/g, 'zinc-50');
    
    // Hardcoded backgrounds
    content = content.replace(/bg-\[#06070a\]/g, 'bg-black');
    content = content.replace(/bg-\[#0f111a\]/g, 'bg-zinc-900');
    
    // Corners
    content = content.replace(/rounded-2xl/g, 'rounded-sm');
    content = content.replace(/rounded-xl/g, 'rounded-sm');
    content = content.replace(/rounded-lg/g, 'rounded-sm');

    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Recolored ${filePath}`);
}

const basePath = path.join(__dirname, 'front', 'src', 'components');
recolorFile(path.join(basePath, 'Dashboard.tsx'));
recolorFile(path.join(basePath, 'EntityModal.tsx'));
