const fs = require('fs');
const path = require('path');

const baseUrl = process.env.API_BASE_URL || 'https://f1-backend-tarkiainen.fly.dev';

const outputPath = path.join(__dirname, '..', 'src', 'Config.elm');

const content = `module Config exposing (apiBaseUrl)

apiBaseUrl : String
apiBaseUrl =
    "${baseUrl}"
`;

fs.writeFileSync(outputPath, content, 'utf8');

console.log(`Generated Config.elm with apiBaseUrl=${baseUrl}`);

