const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const errors = [];

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (['node_modules', '.git', 'build', '.dart_tool'].includes(entry.name)) continue;
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(fullPath);
    if (entry.isFile() && entry.name.endsWith('.js')) {
      try {
        new vm.Script(fs.readFileSync(fullPath, 'utf8'), { filename: fullPath });
      } catch (error) {
        errors.push(`${path.relative(root, fullPath)}: ${error.message}`);
      }
    }
  }
}

function checkInlineScript(fileName) {
  const fullPath = path.join(root, 'public', fileName);
  const html = fs.readFileSync(fullPath, 'utf8');
  const scripts = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
    .map((match) => match[1])
    .filter(Boolean)
    .join('\n');
  try {
    new vm.Script(scripts, { filename: fullPath });
  } catch (error) {
    errors.push(`${fileName}: ${error.message}`);
  }
}

walk(root);
checkInlineScript('index.html');
checkInlineScript('admin.html');

const required = [
  'server.js',
  'public/index.html',
  'public/admin.html',
];

if (fs.existsSync(path.join(root, 'maranatha-app'))) {
  required.push(
    'maranatha-app/pubspec.yaml',
    'maranatha-app/lib/main.dart',
    'maranatha-app/lib/screens/intro_screen.dart',
    'maranatha-app/lib/screens/web_screen.dart',
  );
}

for (const file of required) {
  if (!fs.existsSync(path.join(root, file))) errors.push(`${file}: fichier manquant`);
}

if (errors.length > 0) {
  console.error('Vérification échouée :');
  errors.forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

console.log('Vérification statique réussie.');
