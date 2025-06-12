#!/bin/bash

# Create a demonstration HTML file to visualize cookie isolation problems
# This script generates an HTML file that shows which cookies are visible across deployments

echo "Creating cookie isolation visualization tool..."

# Define HTML content
cat > /home/whitex/dev/github/learnhouse/cookie-isolation-demo.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LearnHouse Cookie Isolation Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #0066cc;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
        }
        h2 {
            color: #0066cc;
            margin-top: 30px;
        }
        .test-panel {
            border: 1px solid #ddd;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
            background-color: #f9f9f9;
        }
        button {
            background-color: #0066cc;
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px 0;
            font-size: 14px;
        }
        button:hover {
            background-color: #0055aa;
        }
        #results {
            border: 1px solid #ddd;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
            min-height: 200px;
            background-color: #fff;
        }
        .success {
            color: green;
            font-weight: bold;
        }
        .failure {
            color: red;
            font-weight: bold;
        }
        .deployment {
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .dev {
            background-color: #e6f7ff;
            border-left: 5px solid #0099ff;
        }
        .live {
            background-color: #fff0e6;
            border-left: 5px solid #ff9966;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .info {
            background-color: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border-left: 5px solid #999;
        }
    </style>
</head>
<body>
    <h1>LearnHouse Cookie Isolation Test</h1>
    
    <div class="info">
        <p>This tool helps visualize cookie isolation between DEV and LIVE LearnHouse deployments. 
           It will help you identify if cookies from one deployment are visible to the other, which 
           could lead to session contamination.</p>
    </div>

    <div class="test-panel">
        <h2>1. Set Test Cookies</h2>
        <p>First, set test cookies on both deployments:</p>
        <button onclick="setDevCookie()">Set DEV Cookie</button>
        <button onclick="setLiveCookie()">Set LIVE Cookie</button>
        <div id="setCookieResult"></div>
    </div>

    <div class="test-panel">
        <h2>2. Test Cookie Isolation</h2>
        <p>Now check if cookies are properly isolated between deployments:</p>
        <button onclick="testCookieIsolation()">Test Cookie Isolation</button>
    </div>

    <h2>Results</h2>
    <div id="results">
        <p>Results will appear here after running tests...</p>
    </div>

    <script>
        const DEV_URL = 'http://adr-lms.whitex.cloud';
        const LIVE_URL = 'http://edu.adradviser.ro';
        
        // Function to fetch with CORS handling
        async function fetchWithCors(url) {
            try {
                const response = await fetch(url, {
                    method: 'GET',
                    mode: 'cors', 
                    credentials: 'include', // Important: include cookies
                    headers: {
                        'Accept': 'application/json',
                    }
                });
                
                if (!response.ok) {
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
                
                return await response.json();
            } catch (error) {
                console.error('Fetch error:', error);
                return { error: error.message };
            }
        }

        // Set cookie on DEV deployment
        async function setDevCookie() {
            document.getElementById('setCookieResult').innerHTML = 'Setting DEV cookie...';
            const result = await fetchWithCors(`${DEV_URL}/api/v1/debug/cookies`);
            document.getElementById('setCookieResult').innerHTML = 
                `<div class="deployment dev">Set DEV cookie: ${JSON.stringify(result.message || 'Failed')}</div>`;
        }

        // Set cookie on LIVE deployment
        async function setLiveCookie() {
            document.getElementById('setCookieResult').innerHTML = 'Setting LIVE cookie...';
            const result = await fetchWithCors(`${LIVE_URL}/api/v1/debug/cookies`);
            document.getElementById('setCookieResult').innerHTML = 
                `<div class="deployment live">Set LIVE cookie: ${JSON.stringify(result.message || 'Failed')}</div>`;
        }

        // Test if cookies are isolated between deployments
        async function testCookieIsolation() {
            document.getElementById('results').innerHTML = 'Testing cookie isolation...';
            
            // Test DEV cookies
            const devResult = await fetchWithCors(`${DEV_URL}/api/v1/debug/cookies`);
            
            // Test LIVE cookies
            const liveResult = await fetchWithCors(`${LIVE_URL}/api/v1/debug/cookies`);
            
            // Analyze results
            let html = '<h3>Cookie Isolation Test Results</h3>';
            
            html += '<div class="deployment dev">';
            html += '<h4>DEV Deployment Cookies</h4>';
            html += '<table>';
            html += '<tr><th>Cookie</th><th>Value</th></tr>';
            
            const devCookies = devResult.detected_isolation_cookies || {};
            if (Object.keys(devCookies).length === 0) {
                html += '<tr><td colspan="2">No isolation test cookies found</td></tr>';
            } else {
                for (const [cookie, value] of Object.entries(devCookies)) {
                    html += `<tr><td>${cookie}</td><td>${value}</td></tr>`;
                }
            }
            
            html += '</table></div>';
            
            html += '<div class="deployment live">';
            html += '<h4>LIVE Deployment Cookies</h4>';
            html += '<table>';
            html += '<tr><th>Cookie</th><th>Value</th></tr>';
            
            const liveCookies = liveResult.detected_isolation_cookies || {};
            if (Object.keys(liveCookies).length === 0) {
                html += '<tr><td colspan="2">No isolation test cookies found</td></tr>';
            } else {
                for (const [cookie, value] of Object.entries(liveCookies)) {
                    html += `<tr><td>${cookie}</td><td>${value}</td></tr>`;
                }
            }
            
            html += '</table></div>';
            
            // Analysis
            html += '<h4>Analysis</h4>';
            
            const devHasLiveCookies = Object.keys(devCookies).some(c => c.includes('LIVE'));
            const liveHasDevCookies = Object.keys(liveCookies).some(c => c.includes('DEV'));
            
            if (!devHasLiveCookies && !liveHasDevCookies) {
                html += '<div class="success">SUCCESS: Cookie isolation is working correctly!</div>';
                html += '<p>The DEV cookies are not visible to the LIVE deployment, and vice versa.</p>';
                html += '<p>This means that sessions should be properly isolated between deployments.</p>';
            } else {
                html += '<div class="failure">FAILURE: Cookie isolation is NOT working!</div>';
                
                if (devHasLiveCookies) {
                    html += '<p>- DEV deployment can see LIVE cookies</p>';
                }
                
                if (liveHasDevCookies) {
                    html += '<p>- LIVE deployment can see DEV cookies</p>';
                }
                
                html += '<p>This means session contamination is occurring between deployments.</p>';
                html += '<p>Please ensure each deployment has a unique cookie domain set with:</p>';
                html += '<pre>LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud  (for DEV)\nLEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro     (for LIVE)</pre>';
            }
            
            document.getElementById('results').innerHTML = html;
        }
    </script>
</body>
</html>
EOL

echo "Cookie isolation demonstration tool has been created at:"
echo "/home/whitex/dev/github/learnhouse/cookie-isolation-demo.html"
echo
echo "To use this tool:"
echo "1. Open the HTML file in a browser"
echo "2. Click 'Set DEV Cookie' and 'Set LIVE Cookie' buttons"
echo "3. Click 'Test Cookie Isolation' to see if cookies are properly isolated"
echo
echo "This tool demonstrates visually whether the cookie domains are properly isolated between deployments."
