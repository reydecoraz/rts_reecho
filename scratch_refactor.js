const fs = require('fs');
const path = require('path');

const basePath = path.join(__dirname, 'front', 'src', 'components');

// 1. Create Directories
['dashboard', 'modals', 'editors', 'ui'].forEach(dir => {
    const dirPath = path.join(basePath, dir);
    if (!fs.existsSync(dirPath)) fs.mkdirSync(dirPath);
});

// 2. Move Files
const filesToMove = {
    'OverrideModal.tsx': 'modals',
    'CivWizardModal.tsx': 'modals',
    'SpriteConfiguratorModal.tsx': 'modals',
    'TechTreeEditor.tsx': 'editors',
    'SpriteGenerator.tsx': 'editors',
    'AdvancedSections.tsx': 'editors',
};

for (const [file, folder] of Object.entries(filesToMove)) {
    const oldPath = path.join(basePath, file);
    const newPath = path.join(basePath, folder, file);
    if (fs.existsSync(oldPath)) {
        fs.renameSync(oldPath, newPath);
        console.log(`Moved ${file} to ${folder}/`);
    }
}

// 3. Update Imports in Dashboard.tsx
let dashboardPath = path.join(basePath, 'Dashboard.tsx');
let content = fs.readFileSync(dashboardPath, 'utf8');

content = content.replace(/import TechTreeEditor from '\.\/TechTreeEditor';/, "import TechTreeEditor from './editors/TechTreeEditor';");
content = content.replace(/import SpriteGenerator from '\.\/SpriteGenerator';/, "import SpriteGenerator from './editors/SpriteGenerator';");
content = content.replace(/import SpriteConfiguratorModal from '\.\/SpriteConfiguratorModal';/, "import SpriteConfiguratorModal from './modals/SpriteConfiguratorModal';");
content = content.replace(/import OverrideModal from '\.\/OverrideModal';/, "import OverrideModal from './modals/OverrideModal';");
content = content.replace(/import CivWizardModal from '\.\/CivWizardModal';/, "import CivWizardModal from './modals/CivWizardModal';");
content = content.replace(/import \{ (.*?) \} from '\.\/AdvancedSections';/, "import { $1 } from './editors/AdvancedSections';");

fs.writeFileSync(dashboardPath, content, 'utf8');
console.log('Imports in Dashboard updated.');
