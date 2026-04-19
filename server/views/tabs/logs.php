<div id="logs" class="tab-pane">
    <div class="card" style="margin-bottom: 20px;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 10px;">
             <h3 style="margin: 0; font-size: 1.3rem;"><i class="fas fa-terminal" style="color:var(--primary-color); margin-right: 8px;"></i> System Event Logs</h3>
             <div style="display:flex; gap: 10px;">
                <button class="btn btn-primary" onclick="refreshSystemLogs()" style="padding:6px 15px;"><i class="fas fa-sync"></i> Refresh</button>
                <button class="btn btn-danger" onclick="clearSystemLogs()" style="padding:6px 15px;"><i class="fas fa-trash"></i> Clear Logs</button>
             </div>
        </div>
        <p style="color:var(--text-muted); font-size:0.95rem; margin-bottom: 20px;">View recent internal backend processing outputs, AI grading activity, and captured server errors in real-time.</p>
        
        <div style="background-color: #1a1a2e; color: #a6accd; padding: 20px; border-radius: 12px; font-family: 'Courier New', monospace; height: 550px; overflow-y: auto; white-space: pre-wrap; word-wrap: break-word; font-size: 0.9rem; line-height: 1.5; box-shadow: inset 0 2px 10px rgba(0,0,0,0.5);" id="system-logs-container">
            Loading logs from server...
        </div>
    </div>
</div>
<script>
async function refreshSystemLogs() {
    const container = document.getElementById('system-logs-container');
    container.innerHTML = '<i class="fas fa-circle-notch fa-spin"></i> Fetching logs...';
    try {
        const res = await fetch('api.php?action=get_system_logs', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({}) });
        const data = await res.json();
        if (data.status === 'success') {
            container.innerText = data.logs || "No logs available. The system is operating normally.";
            container.scrollTop = container.scrollHeight; // Auto scroll to bottom
        } else {
            container.innerText = "Error loading logs: " + (data.error || 'Unknown error');
        }
    } catch(err) {
        container.innerText = "Network Error loading logs. Verify connection.";
    }
}

async function clearSystemLogs() {
    if (!confirm('Are you certain you wish to permanently delete all server logs?')) return;
    try {
        const res = await fetch('api.php?action=clear_system_logs', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({}) });
        const data = await res.json();
        if (data.status === 'success') {
            showToast('System logs fully cleared', 'success');
            refreshSystemLogs();
        } else {
            showToast(data.error || 'Failed to clear logs', 'error');
        }
    } catch(err) {
        showToast('Network error while clearing logs', 'error');
    }
}

// Initial load hook
document.addEventListener('DOMContentLoaded', () => {
    const logTabBtn = document.querySelector('.nav-link[data-tab="logs"]');
    if (logTabBtn) {
        logTabBtn.addEventListener('click', () => {
            refreshSystemLogs();
        });
    }
});
</script>
