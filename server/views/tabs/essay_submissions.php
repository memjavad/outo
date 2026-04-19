<div id="essay_submissions" class="tab-pane">
    <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <h2 class="card-title" style="margin: 0;"><i class="fas fa-file-signature"></i> Essay Submissions</h2>
            
            <div style="display: flex; gap: 10px; align-items: center;">
                <label style="font-weight: 600; font-size: 0.9rem; color: var(--text-muted);">Select Essay:</label>
                <select id="essay-submission-filter" class="form-control" style="padding: 8px 12px; border-radius: 8px; border: 1px solid var(--border-color); min-width: 250px; background: var(--surface-color); font-weight: 600; cursor: pointer;" onchange="filterEssaySubmissions(this.value)">
                    <option value="">-- Select an Assignment --</option>
                    <?php foreach($essayExams as $ex): ?>
                        <option value="<?= $ex['id'] ?>"><?= htmlspecialchars($ex['title']) ?></option>
                    <?php endforeach; ?>
                </select>
                <button id="export-essay-csv-btn" class="btn btn-secondary" onclick="exportEssayGradesToCSV()" disabled style="display: flex; align-items: center; gap: 6px;">
                    <i class="fas fa-file-csv"></i> Export CSV
                </button>
            </div>
        </div>

        <div id="essay-submissions-container">
            <!-- Tables for each exam, toggled via JS -->
            <div id="no-selection-placeholder" style="text-align: center; color: var(--text-muted); padding: 40px; background: #f8fafc; border-radius: 8px; border: 2px dashed #e2e8f0;">
                <i class="fas fa-hand-pointer" style="font-size: 2rem; color: #94a3b8; margin-bottom: 10px;"></i>
                <h3 style="margin: 0; color: #475569;">Select an assignment from the dropdown</h3>
                <p style="margin: 5px 0 0 0; font-size: 0.9rem;">View student submissions, scores, and AI feedback.</p>
            </div>

            <?php foreach($essayExams as $ex): ?>
                <div id="submission-table-<?= $ex['id'] ?>" class="essay-submission-grid" style="display: none;">
                    <?php if(isset($essayResultsByExamId[$ex['id']]) && count($essayResultsByExamId[$ex['id']]) > 0): ?>
                        <div class="table-container">
                            <table class="table-compact" id="export-table-<?= $ex['id'] ?>">
                                <thead>
                                    <tr>
                                        <th>Student Name</th>
                                        <th>Date Submitted</th>
                                        <th>Score</th>
                                        <th>Letter Grade</th>
                                        <th>Status</th>
                                        <th class="no-export">Feedback</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach($essayResultsByExamId[$ex['id']] as $sub): ?>
                                    <tr>
                                        <td style="font-weight: 600;"><?= htmlspecialchars($sub['student_name']) ?></td>
                                        <td style="font-size: 0.85rem; color: #64748b;"><?= $sub['created_at'] ?></td>
                                        <td style="font-weight: bold;"><?= $sub['score_percentage'] ?>%</td>
                                        <td style="font-weight: bold; color: <?= $sub['grade'] === 'A' ? '#10B981' : ($sub['grade'] === 'F' ? '#EF4444' : 'inherit') ?>;"><?= $sub['grade'] ?></td>
                                        <td>
                                            <?php if($sub['is_graded']): ?>
                                                <span class="badge" style="background: #10B981; font-size: 0.75rem;">Graded</span>
                                            <?php else: ?>
                                                <span class="badge" style="background: #F59E0B; font-size: 0.75rem;">Pending</span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="no-export" style="max-width: 250px;">
                                            <?php if($sub['is_graded'] && !empty($sub['teacher_feedback'])): ?>
                                                <div style="font-size: 0.8rem; color: #334155; max-height: 48px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; cursor: pointer; text-decoration: underline;" onclick="alert(`Feedback for <?= htmlspecialchars($sub['student_name']) ?>:\n\n<?= htmlspecialchars(str_replace('`', '\\`', $sub['teacher_feedback'])) ?>`)">
                                                    <?= htmlspecialchars($sub['teacher_feedback']) ?>
                                                </div>
                                            <?php else: ?>
                                                <span style="color: #cbd5e1; font-size: 0.8rem; font-style: italic;">No feedback</span>
                                            <?php endif; ?>
                                        </td>
                                        <!-- Hidden column holding full raw feedback for CSV export ONLY -->
                                        <td class="raw-feedback-export" style="display: none;"><?= htmlspecialchars($sub['teacher_feedback'] ?? '') ?></td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php else: ?>
                        <div style="text-align: center; color: #94a3b8; font-size: 0.95rem; padding: 30px; background: #f8fafc; border-radius: 8px;">
                            <i class="fas fa-inbox" style="font-size: 1.5rem; margin-bottom: 10px; color: #cbd5e1;"></i><br>
                            No submissions have been received for this assignment yet.
                        </div>
                    <?php endif; ?>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</div>

<script>
function filterEssaySubmissions(examId) {
    // Hide all tables and placeholder
    document.getElementById('no-selection-placeholder').style.display = 'none';
    document.querySelectorAll('.essay-submission-grid').forEach(el => {
        el.style.display = 'none';
    });
    
    const exportBtn = document.getElementById('export-essay-csv-btn');

    if (!examId) {
        document.getElementById('no-selection-placeholder').style.display = 'block';
        exportBtn.disabled = true;
        return;
    }

    // Show the target table
    const targetTable = document.getElementById('submission-table-' + examId);
    if (targetTable) {
        targetTable.style.display = 'block';
        // Only enable export if there are rows in the table (meaning it has a table-compact element, not just the "No submissions" div)
        exportBtn.disabled = !targetTable.querySelector('.table-compact');
    }
}

function exportEssayGradesToCSV() {
    const examId = document.getElementById('essay-submission-filter').value;
    if (!examId) return;

    const selectEl = document.getElementById('essay-submission-filter');
    const examName = selectEl.options[selectEl.selectedIndex].text.trim().replace(/[^a-zA-Z0-9_\-]/g, '_');
    const tableId = `export-table-${examId}`;
    const table = document.getElementById(tableId);
    
    if (!table) return;

    let csvContent = "data:text/csv;charset=utf-8,\uFEFF"; // BOM for UTF-8 Excel support
    const rows = table.querySelectorAll('tr');

    rows.forEach(row => {
        let rowData = [];
        const cols = row.querySelectorAll('th, td');
        
        cols.forEach(col => {
            // Ignore UI only columns like truncated feedback cell
            if (col.classList.contains('no-export')) return;
            
            // If it's a hidden column containing the full raw text (for CSV exports only), parse that instead
            if (col.classList.contains('raw-feedback-export')) {
                let cellData = col.innerText;
                // Escape quotes for CSV
                cellData = cellData.replace(/"/g, '""'); 
                rowData.push(`"${cellData}"`);
            } else {
                let cellData = col.innerText.trim();
                // Strip out commas and new lines so it doesn't break CSV formatting
                cellData = cellData.replace(/"/g, '""');
                rowData.push(`"${cellData}"`);
            }
        });
        
        csvContent += rowData.join(",") + "\r\n";
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    // Dynamic file name
    link.setAttribute("download", `Grades_${examName}_${new Date().toISOString().slice(0,10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
</script>
