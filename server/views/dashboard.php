<!-- Dashboard Content -->

<!-- AJAX & Toast Core -->
<div id="toast-container" style="position: fixed; bottom: 30px; right: 30px; z-index: 9999; display: flex; flex-direction: column; gap: 10px;"></div>

<script>
    async function apiCall(action, data = {}, isUpload = false) {
        let body;
        if (isUpload) {
            body = data; // data is already FormData
        } else {
            body = new FormData();
            body.append('csrf_token', '<?= $csrfToken ?>');
            for (const [key, value] of Object.entries(data)) {
                body.append(key, value);
            }
        }

        try {
            const response = await fetch(`api.php?action=${action}`, {
                method: 'POST',
                body: body
            });
            const res = await response.json();
            if (res.error) throw new Error(res.error);
            return res;
        } catch (e) {
            console.error('API Error:', e);
            showToast(e.message || 'Connection failed', 'error');
            return { status: 'error', error: e.message };
        }
    }

    function showToast(message, type = 'success') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = 'card';
        toast.style.margin = '0';
        toast.style.padding = '12px 24px';
        toast.style.minWidth = '250px';
        toast.style.display = 'flex';
        toast.style.alignItems = 'center';
        toast.style.gap = '12px';
        toast.style.borderLeft = `5px solid ${type === 'success' ? '#10B981' : '#EF4444'}`;
        toast.style.animation = 'slideIn 0.3s ease-out';
        
        toast.innerHTML = `
            <i class="fas ${type === 'success' ? 'fa-circle-check' : 'fa-circle-exclamation'}" style="color: ${type === 'success' ? '#10B981' : '#EF4444'}"></i>
            <span style="font-weight: 600; font-size: 0.9rem;">${message}</span>
        `;
        
        container.appendChild(toast);
        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transform = 'translateX(20px)';
            toast.style.transition = 'all 0.3s ease';
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }

    function showTab(tabId) {
        document.querySelectorAll('.tab-pane').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
        
        const target = document.getElementById(tabId);
        if (target) target.classList.add('active');
        
        const navLink = document.querySelector(`.nav-link[data-tab="${tabId}"]`);
        if (navLink) navLink.classList.add('active');
        
        const titleMap = {
            'analytics': 'Analytics Overview',
            'results': 'Student Results',
            'students': 'Manage Students',
            'standard_exams': 'Standard Exams & Questions',
            'campaign_exams': 'Campaign Mode',
            'essay_exams': 'Essay Assignments',
            'essay_submissions': 'Essay Submissions',
            'logs': 'System Logs',
            'settings': 'Settings'
        };
        const pageTitle = document.getElementById('page-title');
        if (pageTitle) pageTitle.innerText = titleMap[tabId] || 'Dashboard';
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
</script>

<style>
@keyframes slideIn { from { opacity: 0; transform: translateX(50px); } to { opacity: 1; transform: translateX(0); } }
.tab-pane { display: none; animation: fadeIn 0.4s ease-out; }
.tab-pane.active { display: block; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* Tooltip Styles */
.help-icon {
    color: var(--primary-color);
    font-size: 0.8rem;
    cursor: help;
    opacity: 0.6;
    transition: opacity 0.2s;
    margin-left: 8px;
}
.help-icon:hover { opacity: 1; }

[data-tooltip] { position: relative; }
[data-tooltip]:hover::after {
    content: attr(data-tooltip);
    position: absolute;
    bottom: 125%;
    left: 50%;
    transform: translateX(-50%);
    background: #333;
    color: #fff;
    padding: 8px 12px;
    border-radius: 6px;
    font-size: 0.75rem;
    white-space: normal;
    width: 200px;
    z-index: 1000;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    font-weight: normal;
    line-height: 1.4;
    pointer-events: none;
}
[data-tooltip]:hover::before {
    content: '';
    position: absolute;
    bottom: 115%;
    left: 50%;
    border: 6px solid transparent;
    border-top-color: #333;
    transform: translateX(-50%);
    pointer-events: none;
}
</style>

<div class="tab-content">
    <!-- TAB: Analytics -->
    <?php include __DIR__ . '/tabs/analytics.php'; ?>

    <!-- TAB: Results -->
    <?php include __DIR__ . '/tabs/results.php'; ?>

    <!-- TAB: Students -->
    <?php include __DIR__ . '/tabs/students.php'; ?>

    <!-- TAB: Standard Exams & Questions -->
    <?php include __DIR__ . '/tabs/standard_exams.php'; ?>

    <!-- TAB: Campaign Mode -->
    <?php include __DIR__ . '/tabs/campaign_exams.php'; ?>

    <!-- TAB: Essay Assignments -->
    <?php include __DIR__ . '/tabs/essay_exams.php'; ?>

    <!-- TAB: Essay Submissions -->
    <?php include __DIR__ . '/tabs/essay_submissions.php'; ?>

    <!-- TAB: System Logs -->
    <?php include __DIR__ . '/tabs/logs.php'; ?>

    <!-- TAB: Settings -->
    <?php include __DIR__ . '/tabs/settings.php'; ?>
</div>

<!-- Review Modal -->
<div id="reviewModal" class="modal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.6);">
    <div class="card" style="max-width:700px; margin:60px auto; max-height:85vh; overflow-y:auto;">
        <div style="display:flex; justify-content:space-between; align-items:center; mb:20px;">
            <h2 id="reviewTitle" class="card-title" style="margin:0;">Review</h2>
            <button class="btn btn-danger" onclick="closeReview()"><i class="fas fa-times"></i></button>
        </div>
        <div id="reviewContent"></div>
    </div>
</div>

<!-- Edit Exam Modal -->
<div id="editExamModal" class="modal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.6);">
    <div class="card" style="max-width:500px; margin:100px auto;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 20px;">
            <h2 class="card-title" style="margin:0;"><i class="fas fa-edit"></i> Edit Exam</h2>
            <button class="btn btn-danger" onclick="closeModal('editExamModal')"><i class="fas fa-times"></i></button>
        </div>
        <form id="edit-exam-form">
            <input type="hidden" name="id" id="edit-exam-id">
            <div class="form-group"><label>Exam Title</label><input type="text" name="title" id="edit-exam-title" required></div>
            <div class="form-group"><label>Description</label><textarea name="description" id="edit-exam-description" rows="2"></textarea></div>
            <div class="form-group">
                <label>Exam Type</label>
                <select name="exam_type" id="edit-exam-type" onchange="
                    document.getElementById('edit-exam-campaign-fields').style.display = this.value === 'campaign' ? 'block' : 'none';
                    document.getElementById('edit-exam-essay-fields').style.display = this.value === 'essay' ? 'block' : 'none';
                ">
                    <option value="standard">Standard</option>
                    <option value="campaign">Campaign (Story Mode)</option>
                    <option value="essay">Essay</option>
                </select>
            </div>
            
            <div id="edit-exam-essay-fields" style="display:none; background:var(--surface-color); padding:10px; border-radius:8px; border:1px solid var(--border-color); margin-bottom:15px;">
                <label style="font-size:0.8rem; color:var(--text-muted); margin-top:0;">Grammar & Mechanics</label>
                <textarea id="edit-rubric-grammar" rows="2" style="margin-bottom:10px;"></textarea>
                
                <label style="font-size:0.8rem; color:var(--text-muted);">Content & Knowledge</label>
                <textarea id="edit-rubric-content" rows="2" style="margin-bottom:10px;"></textarea>
                
                <label style="font-size:0.8rem; color:var(--text-muted);">Organization</label>
                <textarea id="edit-rubric-org" rows="2" style="margin-bottom:10px;"></textarea>
                
                <label style="font-size:0.8rem; color:var(--text-muted);">Creativity & Originality</label>
                <textarea id="edit-rubric-create" rows="2" style="margin-bottom:10px;"></textarea>
                <input type="hidden" name="rubric" id="edit-rubric-payload">
            </div>

            <div id="edit-exam-campaign-fields" style="display:none; background:var(--surface-color); padding:10px; border-radius:8px; border:1px solid var(--border-color); margin-bottom:15px;">
                <div class="form-group">
                    <label>Prerequisite Exam (Optional)</label>
                    <select name="prerequisite_exam_id" id="edit-prerequisite">
                        <option value="">None</option>
                        <?php foreach($exams as $ex): ?><option value="<?= $ex['id'] ?>"><?= htmlspecialchars($ex['title']) ?></option><?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label>Unlock Cost (Coins)</label>
                    <input type="number" name="unlock_cost" id="edit-unlock-cost" value="0" min="0">
                </div>
            </div>

            <!-- Per-Quiz Overrides -->
            <div style="background:var(--surface-color); padding:15px; border-radius:8px; border:1px solid var(--border-color); margin-bottom:15px; max-height: 250px; overflow-y: auto;">
                <h4 style="margin:0 0 10px 0;"><i class="fas fa-sliders"></i> Configuration Overrides</h4>
                <div class="form-grid" style="grid-template-columns:1fr 1fr; margin-bottom:10px;">
                    <div class="form-group"><label>Total Timer (m)</label><input type="number" name="exam_timer" id="edit-exam-timer" value="10"></div>
                    <div class="form-group"><label>Question Timer (s)</label><input type="number" name="question_timer" id="edit-exam-qtimer" value="0"></div>
                </div>
                <div class="form-grid" style="grid-template-columns:1fr 1fr; margin-bottom:10px;">
                    <div class="form-group"><label>Start Date</label><input type="datetime-local" name="exam_start_date" id="edit-exam-start"></div>
                    <div class="form-group"><label>End Date</label><input type="datetime-local" name="exam_end_date" id="edit-exam-end"></div>
                </div>
                
                <hr style="border:0; border-top:1px solid var(--border-color); margin:10px 0;">
                
                <div class="switch-group"><label>Randomize Questions</label><input type="checkbox" name="randomize_questions" id="edit-exam-rq" value="1"></div>
                <div class="switch-group"><label>Randomize Options</label><input type="checkbox" name="randomize_options" id="edit-exam-ro" value="1"></div>
                <div class="switch-group"><label>Allow Backtracking</label><input type="checkbox" name="allow_backtracking" id="edit-exam-ab" value="1"></div>
                <div class="switch-group"><label>Allow Review after sumbit</label><input type="checkbox" name="allow_review" id="edit-exam-ar" value="1"></div>
                <div class="switch-group"><label>Immediate Feedback</label><input type="checkbox" name="immediate_feedback" id="edit-exam-if" value="1"></div>
                
                <hr style="border:0; border-top:1px solid var(--border-color); margin:10px 0;">
                
                <div class="switch-group"><label>Strict Focus Flagging</label><input type="checkbox" name="strict_app_focus" id="edit-exam-sf" value="1"></div>
                <div class="switch-group"><label>Detect VPN/Proxy</label><input type="checkbox" name="detect_vpn" id="edit-exam-vpn" value="1"></div>
                <div class="switch-group"><label>Require GPS</label><input type="checkbox" name="require_gps" id="edit-exam-gps" value="1"></div>
                <div class="switch-group"><label>Record Remote Audio</label><input type="checkbox" name="record_audio" id="edit-exam-audio" value="1"></div>
                <div class="switch-group"><label>Record Screen (Beta)</label><input type="checkbox" name="record_screen" id="edit-exam-screen" value="1"></div>
                <div class="switch-group"><label>Prevent Screenshots</label><input type="checkbox" name="prevent_screenshots" id="edit-exam-ss" value="1"></div>
                <div class="switch-group"><label>Require Telegram</label><input type="checkbox" name="require_tg_login" id="edit-exam-tg" value="1"></div>
            </div>
            <button type="submit" class="btn btn-primary" style="width:100%;">Save Changes</button>
        </form>
    </div>
</div>

<!-- Edit Question Modal -->
<div id="editQuestionModal" class="modal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.6);">
    <div class="card" style="max-width:600px; margin:50px auto; max-height:90vh; overflow-y:auto;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 20px;">
            <h2 class="card-title" style="margin:0;"><i class="fas fa-edit"></i> Edit Question</h2>
            <button class="btn btn-danger" onclick="closeModal('editQuestionModal')"><i class="fas fa-times"></i></button>
        </div>
        <form id="edit-question-form">
            <input type="hidden" name="id" id="edit-question-id">
            <input type="hidden" name="existing_image" id="edit-question-existing-image">
            <div class="form-grid" style="grid-template-columns: 1fr 1fr; gap: 15px;">
                <div class="form-group">
                    <label>Category</label>
                    <select name="category_id" id="edit-question-category">
                        <option value="">General</option>
                        <?php foreach($categories as $cat): ?><option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option><?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label>Link to Exam</label>
                    <select name="exam_id" id="edit-question-exam">
                        <option value="">None (Universal)</option>
                        <?php foreach($exams as $ex): ?><option value="<?= $ex['id'] ?>"><?= htmlspecialchars($ex['title']) ?></option><?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="form-group"><label>Question Text</label><textarea name="question_text" id="edit-question-text" rows="2" required></textarea></div>
            <div class="form-grid" style="grid-template-columns:1fr 1fr;">
                <input type="text" name="option_0" id="edit-option-0" placeholder="Option 1" required>
                <input type="text" name="option_1" id="edit-option-1" placeholder="Option 2" required>
                <input type="text" name="option_2" id="edit-option-2" placeholder="Option 3" required>
                <input type="text" name="option_3" id="edit-option-3" placeholder="Option 4" required>
            </div>
            <div class="form-group"><label>Correct Index</label><select name="correct_index" id="edit-question-correct"><option value="0">1</option><option value="1">2</option><option value="2">3</option><option value="3">4</option></select></div>
            <div class="form-group">
                <label>Change Image (Optional)</label>
                <div id="edit-question-image-preview" style="margin-bottom:10px;"></div>
                <input type="file" name="question_image" accept="image/*">
            </div>
            <button type="submit" class="btn btn-primary" style="width:100%;">Update Question</button>
        </form>
    </div>
</div>

<!-- Import Excel Modal -->
<div id="importExcelModal" class="modal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.6);">
    <div class="card" style="max-width:500px; margin:100px auto;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 20px;">
            <h2 class="card-title" style="margin:0;"><i class="fas fa-file-excel"></i> Bulk Import Questions</h2>
            <button class="btn btn-danger" onclick="closeModal('importExcelModal')"><i class="fas fa-times"></i></button>
        </div>
        <p style="margin-bottom:15px; font-size:0.9rem; color:var(--text-muted);">
            Upload an Excel (.xlsx) file. Columns must be: Category ID, Exam ID, Question, Opt1, Opt2, Opt3, Opt4, CorrectIndex (1-4), Type.
        </p>
        <div style="margin-bottom: 20px;">
            <a href="template.xlsx" download class="btn btn-secondary" style="display:inline-block; width:100%; text-align:center;"><i class="fas fa-download"></i> Download .xlsx Template</a>
        </div>
        <form id="import-excel-form">
            <div class="form-group">
                <label>Select .xlsx File</label>
                <input type="file" name="excel_file" accept=".xlsx" required>
            </div>
            <button type="submit" id="import-excel-btn" class="btn btn-primary" style="width:100%;"><i class="fas fa-upload"></i> Process Import</button>
        </form>
    </div>
</div>

<script>
    document.getElementById('import-excel-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('import-excel-btn');
        btn.disabled = true;
        btn.innerText = 'Importing...';
        
        const res = await apiCall('import_questions', new FormData(e.target), true);
        
        if (res.status === 'success') {
            showToast(`${res.count} questions imported successfully!`, 'success');
            closeModal('importExcelModal');
            e.target.reset();
            setTimeout(() => location.reload(), 1500);
        } else {
            showToast(res.error || 'Import failed', 'error');
        }
        
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-upload"></i> Process Import';
    });

    // AJAX Submissions
    document.getElementById('add-student-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const res = await apiCall('add_student', Object.fromEntries(new FormData(e.target)));
        if (res.status === 'success') {
            showToast('Student created successfully');
            appendStudentRow(res);
            e.target.reset();
        }
    });

    document.querySelectorAll('.add-question-form-domain').forEach(form => {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const res = await apiCall('add_question', new FormData(e.target), true);
            if (res.status === 'success') {
                showToast('Question added');
                setTimeout(() => location.reload(), 800);
            }
        });
    });

    document.getElementById('settings-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const data = Object.fromEntries(formData);
        
        // Explicitly handle checkboxes that are NOT in the FormData (unchecked)
        e.target.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            if (!cb.checked) {
                data[cb.name] = '0';
            }
        });

        const res = await apiCall('update_settings', data);
        if (res.status === 'success') {
            showToast('Settings updated');
        }
    });
    
    // TAB: Exams -> Add Exam
    document.querySelectorAll('.add-exam-form-domain').forEach(form => {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (form.id === 'add-essay-exam-form') {
                const g = form.querySelector('#add-rubric-grammar').value;
                const c = form.querySelector('#add-rubric-content').value;
                const o = form.querySelector('#add-rubric-org').value;
                const cr = form.querySelector('#add-rubric-create').value;
                const payload = { Grammar: g, Content: c, Organization: o, Creativity: cr };
                form.querySelector('#add-rubric-payload').value = JSON.stringify(payload);
            }

            const data = Object.fromEntries(new FormData(e.target));
            
            // Explicitly handle checkboxes that are NOT in the FormData (unchecked)
            e.target.querySelectorAll('input[type="checkbox"]').forEach(cb => {
                if (!cb.checked) data[cb.name] = '0';
            });

            const res = await apiCall('add_exam', data);
            if (res.status === 'success') {
                showToast('Exam created successfully');
                setTimeout(() => location.reload(), 800);
            }
        });
    });

    async function deleteItem(type, id) {
        if (!confirm('Confirm deletion?')) return;
        const res = await apiCall('delete_item', { type, id });
        if (res.status === 'success') {
            const row = document.getElementById(`${type}-row-${id}`);
            if (row) row.remove();
            showToast('Item deleted');
            refreshStats(); // Trigger stats update
            
            // If it was an exam, remove from question dropdown
            if (type === 'exam') {
                const select = document.getElementById('question-exam-select');
                for (let i=0; i<select.options.length; i++) {
                    if (select.options[i].value == id) {
                        select.remove(i);
                        break;
                    }
                }
            }
        }
    }

    function appendStudentRow(s) {
        const tbody = document.getElementById('student-list-body');
        const tr = document.createElement('tr');
        tr.id = `student-row-${s.id}`;
        tr.innerHTML = `<td style="font-weight:600;">${escapeHtml(s.name)}</td><td><code>${escapeHtml(s.phone)}</code></td><td><button class="btn btn-danger" onclick="deleteItem('student', ${s.id})"><i class="fas fa-trash"></i></button></td>`;
        tbody.prepend(tr);
    }

    function appendQuestionRow(q) {
        const tbody = document.getElementById('question-list-body');
        const tr = document.createElement('tr');
        tr.id = `question-row-${q.id}`;
        tr.innerHTML = `<td><div style="font-weight:600;">${escapeHtml(q.question)}</div>${q.imageUrl ? `<img src="${q.imageUrl}" style="height:35px; margin-top:5px; border-radius:4px;">` : ''}</td><td><button class="btn btn-danger" onclick="deleteItem('question', ${q.id})"><i class="fas fa-trash"></i></button></td>`;
        tbody.prepend(tr);
    }
    
    function appendExamRow(ex) {
        const tbody = document.getElementById('exam-list-body');
        const tr = document.createElement('tr');
        tr.id = `exam-row-${ex.id}`;
        tr.innerHTML = `<td style="font-weight:600;">${escapeHtml(ex.title)}</td><td><span class="badge" style="background:#10B981; margin-bottom: 4px; display: inline-block;">Active</span><br><span class="badge" style="background:#3B82F6; font-size: 0.65rem;">${escapeHtml((ex.exam_type || 'standard').charAt(0).toUpperCase() + (ex.exam_type || 'standard').slice(1))}</span></td><td><button class="btn btn-danger" onclick="deleteItem('exam', ${ex.id})"><i class="fas fa-trash"></i></button></td>`;
        tbody.prepend(tr);
    }

    async function approveStudent(id) {
        if (!confirm('Approve this student?')) return;
        const res = await apiCall('approve_student', { id });
        if (res.status === 'success') {
            showToast('Student approved');
            const row = document.getElementById(`pending-row-${id}`);
            if (row) row.remove();
            location.reload(); // Simplest way to refresh lists
        }
    }

    async function rejectStudent(id) {
        if (!confirm('Reject and delete this student?')) return;
        const res = await apiCall('reject_student', { id });
        if (res.status === 'success') {
            showToast('Student rejected');
            const row = document.getElementById(`pending-row-${id}`);
            if (row) row.remove();
        }
    }

    // Edit Functionality JS
    function closeModal(id) {
        document.getElementById(id).style.display = 'none';
    }

    function showEditExam(id, examJsonString) {
        document.getElementById('edit-exam-id').value = id;
        
        // Parse the JSON representation of the exam row dumped from PHP
        let exam = {};
        try {
            exam = JSON.parse(examJsonString);
        } catch(e) {
            console.error("Failed to parse exam JSON", e);
            showToast('Failed to load exam details', 'error');
            return;
        }

        document.getElementById('edit-exam-title').value = exam.title || '';
        document.getElementById('edit-exam-description').value = exam.description || '';
        document.getElementById('edit-exam-timer').value = exam.exam_timer || 10;
        document.getElementById('edit-exam-qtimer').value = exam.question_timer || 0;
        
        document.getElementById('edit-exam-type').value = exam.exam_type || 'standard';
        document.getElementById('edit-prerequisite').value = exam.prerequisite_exam_id || '';
        document.getElementById('edit-unlock-cost').value = exam.unlock_cost || 0;
        document.getElementById('edit-exam-campaign-fields').style.display = (exam.exam_type === 'campaign') ? 'block' : 'none';
        
        let rGrammar = "Weight: 25%. Evaluate for correct syntax, spelling, punctuation, and formatting.";
        let rContent = "Weight: 25%. Evaluate for accuracy, depth of knowledge, and relevance to the prompt.";
        let rOrg = "Weight: 25%. Evaluate logical flow, paragraph structure, and clear introductions/conclusions.";
        let rCreate = "Weight: 25%. Evaluate unique perspectives, engaging voice, and original ideas.";
        
        if (exam.rubric) {
            try {
                let rObj = JSON.parse(exam.rubric);
                rGrammar = rObj.Grammar || rGrammar;
                rContent = rObj.Content || rContent;
                rOrg = rObj.Organization || rOrg;
                rCreate = rObj.Creativity || rCreate;
            } catch (e) {
                rGrammar = exam.rubric; 
            }
        }
        
        document.getElementById('edit-rubric-grammar').value = rGrammar;
        document.getElementById('edit-rubric-content').value = rContent;
        document.getElementById('edit-rubric-org').value = rOrg;
        document.getElementById('edit-rubric-create').value = rCreate;
        document.getElementById('edit-exam-essay-fields').style.display = (exam.exam_type === 'essay') ? 'block' : 'none';
        
        // Dates
        if (exam.exam_start_date) {
            document.getElementById('edit-exam-start').value = exam.exam_start_date.replace(' ', 'T').slice(0, 16);
        } else {
            document.getElementById('edit-exam-start').value = '';
        }

        if (exam.exam_end_date) {
            document.getElementById('edit-exam-end').value = exam.exam_end_date.replace(' ', 'T').slice(0, 16);
        } else {
            document.getElementById('edit-exam-end').value = '';
        }

        // Toggles
        document.getElementById('edit-exam-rq').checked = (exam.randomize_questions == 1);
        document.getElementById('edit-exam-ro').checked = (exam.randomize_options == 1);
        document.getElementById('edit-exam-ab').checked = (exam.allow_backtracking == 1);
        document.getElementById('edit-exam-ar').checked = (exam.allow_review == 1);
        document.getElementById('edit-exam-if').checked = (exam.immediate_feedback == 1);
        document.getElementById('edit-exam-sf').checked = (exam.strict_app_focus == 1);
        document.getElementById('edit-exam-vpn').checked = (exam.detect_vpn == 1);
        document.getElementById('edit-exam-gps').checked = (exam.require_gps == 1);
        document.getElementById('edit-exam-audio').checked = (exam.record_audio == 1);
        document.getElementById('edit-exam-screen').checked = (exam.record_screen == 1);
        document.getElementById('edit-exam-ss').checked = (exam.prevent_screenshots == 1);
        document.getElementById('edit-exam-tg').checked = (exam.require_tg_login == 1);

        document.getElementById('editExamModal').style.display = 'block';
    }

    document.getElementById('edit-exam-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const typeSelect = document.getElementById('edit-exam-type').value;
        if (typeSelect === 'essay') {
            const g = document.getElementById('edit-rubric-grammar').value;
            const c = document.getElementById('edit-rubric-content').value;
            const o = document.getElementById('edit-rubric-org').value;
            const cr = document.getElementById('edit-rubric-create').value;
            const payload = { Grammar: g, Content: c, Organization: o, Creativity: cr };
            document.getElementById('edit-rubric-payload').value = JSON.stringify(payload);
        }

        const data = Object.fromEntries(new FormData(e.target));
        
        // Force unchecked checkboxes to 0 so the backend overrides previous settings
        e.target.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            if (!cb.checked) data[cb.name] = '0';
        });

        const res = await apiCall('update_exam', data);
        if (res.status === 'success') {
            showToast('Exam updated successfully');
            closeModal('editExamModal');
            // Update table row title
            const row = document.getElementById(`exam-row-${data.id}`);
            if (row) {
                row.querySelector('td:first-child').innerText = data.title;
                // Since clicking edit again would require the full updated JSON, an easy hack is to refresh table.
                // However, since we just patched the title locally:
                location.reload(); 
            }
        }
    });

    async function showEditQuestion(id) {
        const res = await apiCall('get_question_details', { id });
        if (res.error) return showToast(res.error, 'error');

        document.getElementById('edit-question-id').value = res.id;
        document.getElementById('edit-question-text').value = res.question_text;
        document.getElementById('edit-question-category').value = res.category_id || '';
        document.getElementById('edit-question-exam').value = res.exam_id || '';
        document.getElementById('edit-question-correct').value = res.correct_answer_index;
        document.getElementById('edit-question-existing-image').value = res.image_url || '';
        
        const preview = document.getElementById('edit-question-image-preview');
        preview.innerHTML = res.image_url ? `<img src="${res.image_url}" style="height:60px; border-radius:8px;">` : '';

        // Fill options
        if (res.options) {
            res.options.forEach((opt, i) => {
                const input = document.getElementById(`edit-option-${i}`);
                if (input) input.value = opt.option_text;
            });
        }

        document.getElementById('editQuestionModal').style.display = 'block';
    }

    document.getElementById('edit-question-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const res = await apiCall('update_question', new FormData(e.target), true);
        if (res.status === 'success') {
            showToast('Question updated');
            closeModal('editQuestionModal');
            // Update row
            const row = document.getElementById(`question-row-${document.getElementById('edit-question-id').value}`);
            if (row) {
                row.querySelector('div').innerText = document.getElementById('edit-question-text').value;
                const img = row.querySelector('img');
                if (res.imageUrl) {
                    if (img) img.src = res.imageUrl;
                    else {
                        const cell = row.querySelector('td:first-child');
                        const newImg = document.createElement('img');
                        newImg.src = res.imageUrl;
                        newImg.style.cssText = "height:35px; margin-top:5px; border-radius:4px;";
                        cell.appendChild(newImg);
                    }
                } else if (img) img.remove();
            }
        }
    });

    // Modal logic
    function showReview(answers, name) {
        document.getElementById('reviewTitle').innerText = `Review: ${name}`;
        const content = document.getElementById('reviewContent');
        content.innerHTML = '';
        answers.forEach((ans, i) => {
            const div = document.createElement('div');
            div.className = 'card';
            div.style.padding = '15px'; div.style.marginBottom = '10px';
            div.style.borderLeft = `4px solid ${ans.isCorrect ? '#10B981' : '#EF4444'}`;
            div.innerHTML = `<div style="font-weight:700; mb:5px;">Q${i+1}: ${ans.question}</div><div style="font-size:0.8rem;"><b>Student:</b> ${ans.selectedOption} | <b>Correct:</b> ${ans.correctOption}</div>`;
            content.appendChild(div);
        });
        document.getElementById('reviewModal').style.display = 'block';
    }
    function closeReview() { document.getElementById('reviewModal').style.display = 'none'; }

    // Analytics Initialization
    let gradeChart;
    function initChart(dist = []) {
        const ctx = document.getElementById('gradeChart').getContext('2d');
        gradeChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['A', 'B', 'C', 'D', 'F'],
                datasets: [{ 
                    data: [0,0,0,0,0], 
                    backgroundColor: ['#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#6B7280'],
                    borderRadius: 12
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
        });
        if (dist.length) updateChart(dist);
    }
    function updateChart(dist) {
        const counts = { A:0, B:0, C:0, D:0, F:0 };
        dist.forEach(d => counts[d.grade] = d.count);
        gradeChart.data.datasets[0].data = [counts.A, counts.B, counts.C, counts.D, counts.F];
        gradeChart.update();
    }
    async function performSystemUpdate() {
        const fileInput = document.getElementById('update-zip-file');
        const versionInput = document.getElementById('new-version-number');
        
        if (!fileInput.files.length) {
            showToast('Please select a ZIP file.', 'error');
            return;
        }

        const formData = new FormData();
        formData.append('update_zip', fileInput.files[0]);
        if (versionInput.value) {
            formData.append('new_version', versionInput.value);
        }

        const btn = document.querySelector('#update-card .btn');
        btn.disabled = true;
        btn.innerText = 'Updating...';

        try {
            const result = await apiCall('update_system', formData, true);

            if (result.status === 'success') {
                showToast(result.message, 'success');
                setTimeout(() => location.reload(), 2000);
            } else {
                showToast(result.error || 'Update failed.', 'error');
            }
        } catch (error) {
            showToast('Network error during update.', 'error');
        } finally {
            btn.disabled = false;
            btn.innerText = 'Install Update';
        }
    }

    async function fixDatabaseSchema() {
        if (!confirm('Are you sure you want to force a database schema update?')) return;
        try {
            const res = await apiCall('fix_db', { force: true });
            const msgDiv = document.getElementById('db-fix-message');
            msgDiv.style.display = 'block';
            
            if (res.status === 'success') {
                showToast(res.message, 'success');
                msgDiv.innerHTML = `<span style="color:#10B981;"><i class="fas fa-check-circle"></i> ${res.message}</span>`;
            } else if (res.status === 'partial') {
                showToast('Some schema updates failed.', 'error');
                msgDiv.innerHTML = `<span style="color:#EF4444;"><i class="fas fa-exclamation-triangle"></i> ${res.message}<br><br><b>Errors:</b><br>${res.errors.join('<br>')}</span>`;
            } else {
                showToast(res.error || 'Failed to update database.', 'error');
            }
        } catch (e) {
            showToast('Network error during database fix.', 'error');
        }
    }

    async function refreshStats() {
        const res = await apiCall('analytics_data');
        if (res.stats) {
            document.getElementById('stat-students').innerText = res.stats.students;
            document.getElementById('stat-exams').innerText = res.stats.exams;
            document.getElementById('stat-questions').innerText = res.stats.questions;
            document.getElementById('stat-results').innerText = res.stats.results;
            updateChart(res.distribution);
        }
    }
    
    // Auto-update stats
    setInterval(refreshStats, 20000);
    
    // WebSockets Monitor
    const ws = new WebSocket('ws://' + window.location.hostname + ':8080');
    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            const feed = document.getElementById('live-activity');
            if (feed.querySelector('p')) feed.innerHTML = '';
            const item = document.createElement('div');
            item.style.padding = '8px 10px';
            item.style.borderBottom = '1px solid var(--border-color)';
            item.innerHTML = `<b>${data.student}</b> answered Q${data.question_index + 1} on Exam #${data.exam_id}`;
            feed.prepend(item);
            if (feed.children.length > 50) feed.lastChild.remove();
        } catch (e) {}
    };
    ws.onopen = () => console.log('Real-Time Monitor Connected');

    window.onload = () => initChart(<?= json_encode($gradeDistribution ?? []) ?>);

    // Global click listener for tab switching
    document.querySelectorAll('.nav-link[data-tab]').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            showTab(link.getAttribute('data-tab'));
        });
    });
</script>
