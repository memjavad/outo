<?php
// Live Server Logs Viewer
$logFile = __DIR__ . '/logs/error.log';
$logs = @file_get_contents($logFile);

// Handle manual clear request
if (isset($_GET['clear']) && $_GET['clear'] === 'true') {
    @file_put_contents($logFile, "");
    header("Location: view_logs.php");
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Live Server Logs</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            background: #0f172a; /* Slate 900 */
            color: #10b981; /* Emerald 500 */
            font-family: 'Courier New', Courier, monospace; 
            padding: 20px; 
            margin: 0;
        }
        h2 { color: #f8fafc; margin-top: 0; }
        pre { 
            background: #020617; 
            padding: 16px; 
            border-radius: 8px;
            border: 1px solid #1e293b;
            white-space: pre-wrap; 
            word-wrap: break-word; 
            overflow-x: auto;
            max-height: 80vh;
            overflow-y: auto;
        }
        .controls { 
            display: flex;
            gap: 12px;
            margin-bottom: 16px; 
            padding: 12px;
            background: #1e293b;
            border-radius: 8px;
        }
        button { 
            background: #3b82f6; 
            color: white; 
            border: none; 
            border-radius: 6px;
            padding: 8px 16px; 
            font-weight: bold;
            cursor: pointer; 
            transition: all 0.2s;
        }
        button:hover { background: #2563eb; }
        .danger { background: #ef4444; }
        .danger:hover { background: #dc2626; }
    </style>
</head>
<body>
    <div class="controls">
        <button onclick="location.reload()">🔄 Refresh Logs</button>
        <button onclick="scrollToBottom()">⬇️ Scroll to Bottom</button>
        <button class="danger" onclick="clearLogs()">🗑️ Clear Logs</button>
    </div>
    
    <h2>Application Logs (server/logs/error.log)</h2>
    
    <pre id="logTerminal"><?= htmlspecialchars($logs ?: 'Log is completely empty. No crashes recorded.') ?></pre>

    <script>
        function scrollToBottom() {
            const terminal = document.getElementById('logTerminal');
            terminal.scrollTop = terminal.scrollHeight;
        }
        
        function clearLogs() {
            if(confirm('Are you sure you want to permanently erase the error log?')) {
                window.location.href = '?secret=admin123&clear=true';
            }
        }

        // Auto-scroll on load if there's content
        window.onload = scrollToBottom;
    </script>
</body>
</html>
