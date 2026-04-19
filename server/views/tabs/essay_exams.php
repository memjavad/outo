<div id="essay_exams" class="tab-pane">
    <div class="grid" style="grid-template-columns: 400px 1fr; margin-bottom: 20px; gap: 20px;">
        <div class="card">
            <h2 class="card-title"><i class="fas fa-plus-circle"></i> Create Essay Assignment</h2>
            <form id="add-essay-exam-form" class="add-exam-form-domain">
                <input type="hidden" name="exam_type" value="essay">
                <div class="form-group"><label>Assignment Title</label><input type="text" name="title" placeholder="e.g. Final Paper" required></div>
                <div class="form-group"><label>Grading Target Scale</label><select name="grading_type" style="width: 100%; padding: 8px; border-radius: 4px; border: 1px solid #d1d5db;"><option value="percentage">Percentage (0-100%)</option><option value="arabic_scale">Arabic Scale (ممتاز، جيد جدا...)</option></select></div>
                <div class="form-group"><label>Description / Guidelines</label><textarea name="description" rows="5" placeholder="Write full instructions here..."></textarea></div>
                <div class="form-group">
                    <label><i class="fas fa-robot"></i> AI Grading Rubric Sections</label>
                    <div style="background:var(--surface-color); padding:10px; border-radius:8px; border:1px solid var(--border-color);">
                        <label style="font-size:0.8rem; color:var(--text-muted); margin-top:0;">Grammar & Mechanics</label>
                        <textarea id="add-rubric-grammar" rows="2" style="margin-bottom:10px;">Weight: 25%. Evaluate for correct syntax, spelling, punctuation, and formatting.</textarea>
                        
                        <label style="font-size:0.8rem; color:var(--text-muted);">Content & Knowledge</label>
                        <textarea id="add-rubric-content" rows="2" style="margin-bottom:10px;">Weight: 25%. Evaluate for accuracy, depth of knowledge, and relevance to the prompt.</textarea>
                        
                        <label style="font-size:0.8rem; color:var(--text-muted);">Organization</label>
                        <textarea id="add-rubric-org" rows="2" style="margin-bottom:10px;">Weight: 25%. Evaluate logical flow, paragraph structure, and clear introductions/conclusions.</textarea>
                        
                        <label style="font-size:0.8rem; color:var(--text-muted);">Creativity & Originality</label>
                        <textarea id="add-rubric-create" rows="2" style="margin-bottom:10px;">Weight: 25%. Evaluate unique perspectives, engaging voice, and original ideas.</textarea>
                    </div>
                    <input type="hidden" name="rubric" id="add-rubric-payload">
                </div>
                <button type="submit" class="btn btn-primary" style="width:100%;">Create Assignment</button>
            </form>
        </div>
        
        <div style="display: flex; flex-direction: column; gap: 20px;">
            <!-- Pending Grading Queue -->
            <div class="card" style="border: 2px solid #F59E0B;">
                <h2 class="card-title" style="color: #D97706;"><i class="fas fa-inbox"></i> Pending Grading (Requires Action)</h2>
                <?php if(empty($pendingEssays)): ?>
                    <p style="color: var(--text-muted); text-align: center; margin-top: 20px;"><i class="fas fa-check-circle" style="color: #10B981; font-size: 24px;"></i><br>All caught up! No essays to grade.</p>
                <?php else: ?>
                    <div class="table-container">
                        <table class="table-compact">
                            <thead><tr><th>Student</th><th>Assignment</th><th>Date Submitted</th><th>Action</th></tr></thead>
                            <tbody>
                                <?php foreach($pendingEssays as $pe): ?>
                                <tr>
                                    <td style="font-weight:600;"><?= htmlspecialchars($pe['student_name']) ?></td>
                                    <td><?= htmlspecialchars($pe['exam_title']) ?></td>
                                    <td><span style="font-size: 0.8rem; color: #666;"><?= $pe['created_at'] ?></span></td>
                                    <td>
                                        <button class="btn btn-warning" style="padding:4px 10px; font-weight: bold; margin-right: 5px;" onclick='openGradeModal(<?= json_encode($pe) ?>)'>
                                            <i class="fas fa-edit"></i> Grade
                                        </button>
                                        <button class="btn btn-primary" style="padding:4px 10px; font-weight: bold; background: #8B5CF6; border-color: #8B5CF6;" onclick='gradeWithAiNow(<?= $pe['id'] ?>)'>
                                            <i class="fas fa-robot"></i> Grade with AI
                                        </button>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>

            <!-- Assignments List -->
            <div class="card">
                <h2 class="card-title"><i class="fas fa-book-open"></i> Assignments List</h2>
                <div class="table-container">
                    <table class="table-compact">
                        <thead><tr><th>Title</th><th>Status</th><th>Actions</th></tr></thead>
                        <tbody id="essay-exam-list-body">
                            <?php foreach($essayExams as $ex): ?>
                            <tr id="exam-row-<?= $ex['id'] ?>" style="cursor: pointer; transition: background 0.2s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background='transparent'">
                                <td>
                                    <span style="font-weight:600;"><?= htmlspecialchars($ex['title']) ?></span>
                                </td>
                                <td>
                                    <span class="badge" style="background:<?= $ex['is_active'] ? '#10B981' : '#6B7280' ?>; margin-bottom: 4px; display: inline-block;"><?= $ex['is_active'] ? 'Active' : 'Draft' ?></span><br>
                                    <span class="badge" style="background:#8B5CF6; font-size: 0.65rem;">Essay</span>
                                </td>
                                <td>
                                    <button class="btn btn-primary" style="padding:4px 8px; font-size:0.7rem;" onclick='event.stopPropagation(); showEditExam(<?= $ex["id"] ?>, <?= json_encode(json_encode($ex)) ?>)'><i class="fas fa-edit"></i></button>
                                    <button class="btn btn-danger" style="padding:4px 8px; font-size:0.7rem;" onclick="event.stopPropagation(); deleteItem('exam', <?= $ex['id'] ?>)"><i class="fas fa-trash"></i></button>
                                </td>
                            </tr>

                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Manual Grade Modal -->
<div id="gradeEssayModal" class="modal" style="display:none; position:fixed; z-index:10000; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.6);">
    <div class="card" style="max-width:600px; margin:50px auto; max-height:90vh; overflow-y:auto; border-top: 5px solid #10B981;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 20px;">
            <h2 class="card-title" style="margin:0;"><i class="fas fa-graduation-cap"></i> Grade Essay</h2>
            <button class="btn btn-danger" onclick="closeModal('gradeEssayModal')"><i class="fas fa-times"></i></button>
        </div>
        <div style="background: var(--surface-color); padding: 15px; border-radius: 8px; margin-bottom: 15px; border: 1px solid var(--border-color);">
            <h4 style="margin:0; font-size: 1.1rem; color: var(--primary-color);" id="grade-student-name">Student Name</h4>
            <p style="margin: 5px 0 0 0; color: var(--text-muted); font-size: 0.9rem;" id="grade-exam-title">Exam Title</p>
        </div>
        
        <div class="form-group">
            <label>Student's Response</label>
            <div id="grade-student-answer" style="background: #f8fafc; padding: 15px; border-radius: 8px; border: 1px solid #e2e8f0; min-height: 150px; white-space: pre-wrap; font-family: monospace; color: #334155;">
                <!-- Answer injected here via JS -->
            </div>
        </div>

        <form id="submit-grade-form" onsubmit="submitEssayGrade(event)">
            <input type="hidden" id="grade-result-id">
            <input type="hidden" id="grade-student-id">
            <input type="hidden" id="grade-exam-grading-type">
            <div class="form-grid" style="grid-template-columns: 1fr 1fr; gap: 15px;">
                <div class="form-group" id="grade-score-pct-group">
                    <label>Score Percentage (0-100%)</label>
                    <input type="number" id="grade-score-pct" min="0" max="100" placeholder="e.g. 95" style="font-size: 1.2rem; font-weight: bold; text-align: center;">
                </div>
                <div class="form-group" id="grade-score-arabic-group" style="display:none;">
                    <label>Letter Grade (Arabic)</label>
                    <select id="grade-score-arabic" style="font-size: 1.2rem; font-weight: bold; text-align: center;">
                        <option value="ممتاز">ممتاز</option>
                        <option value="جيد جدا">جيد جدا</option>
                        <option value="جيد">جيد</option>
                        <option value="متوسط">متوسط</option>
                        <option value="ضعيف">ضعيف</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Points Earned (Optional)</label>
                    <input type="number" id="grade-earned-pts" min="0" value="10" required>
                </div>
            </div>
            <div class="form-group">
                <label>Teacher Feedback (Optional)</label>
                <textarea id="grade-feedback" rows="3" placeholder="Provide constructive feedback..."></textarea>
            </div>
            <button type="submit" id="grade-submit-btn" class="btn btn-success" style="width:100%; font-size: 1.1rem; padding: 12px;"><i class="fas fa-check"></i> Submit Final Grade</button>
        </form>
    </div>
</div>

<script>


function openGradeModal(resultObj) {
    document.getElementById('grade-result-id').value = resultObj.id;
    document.getElementById('grade-student-id').value = resultObj.student_id;
    document.getElementById('grade-student-name').innerText = resultObj.student_name;
    document.getElementById('grade-exam-title').innerText = resultObj.exam_title;
    
    document.getElementById('grade-exam-grading-type').value = resultObj.exam_grading_type || 'percentage';
    
    if (resultObj.exam_grading_type === 'arabic_scale') {
        document.getElementById('grade-score-pct-group').style.display = 'none';
        document.getElementById('grade-score-pct').required = false;
        document.getElementById('grade-score-arabic-group').style.display = 'block';
    } else {
        document.getElementById('grade-score-pct-group').style.display = 'block';
        document.getElementById('grade-score-pct').required = true;
        document.getElementById('grade-score-arabic-group').style.display = 'none';
    }
    
    // Parse the JSON answer natively mapping array formats efficiently bypassing string payloads
    let answerText = "No answer provided.";
    if (resultObj.answers_json) {
        try {
            const parsed = JSON.parse(resultObj.answers_json);
            if (typeof parsed === 'object' && parsed !== null) {
                answerText = Object.values(parsed).join("\n\n");
            } else {
                answerText = parsed;
            }
        } catch (e) {
            answerText = resultObj.answers_json; // fallback raw
        }
    }
    
    document.getElementById('grade-student-answer').innerText = answerText;
    document.getElementById('grade-score-pct').value = '';
    document.getElementById('grade-feedback').value = '';
    
    // Estimate points roughly
    document.getElementById('grade-earned-pts').value = '10';

    document.getElementById('gradeEssayModal').style.display = 'block';
}

async function submitEssayGrade(e) {
    e.preventDefault();
    const btn = document.getElementById('grade-submit-btn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Submitting...';
    
    const gradingType = document.getElementById('grade-exam-grading-type').value;
    let pct = 0;
    let letterGrade = 'F';

    if (gradingType === 'arabic_scale') {
        letterGrade = document.getElementById('grade-score-arabic').value;
        const arabicMap = { 'ممتاز': 100, 'جيد جدا': 89, 'جيد': 79, 'متوسط': 69, 'ضعيف': 59 };
        pct = arabicMap[letterGrade] || 0;
    } else {
        pct = parseFloat(document.getElementById('grade-score-pct').value);
        if (pct >= 90) letterGrade = 'A';
        else if (pct >= 80) letterGrade = 'B';
        else if (pct >= 70) letterGrade = 'C';
        else if (pct >= 60) letterGrade = 'D';
    }

    const payload = {
        action: 'grade_essay',
        id: document.getElementById('grade-result-id').value,
        student_id: document.getElementById('grade-student-id').value,
        score_percentage: pct,
        grade: letterGrade,
        earned_points: parseInt(document.getElementById('grade-earned-pts').value) || 0,
        feedback: document.getElementById('grade-feedback').value
    };

    try {
        const response = await fetch('api.php?action=grade_essay', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        
        const res = await response.json();
        if (res.status === 'success') {
            showToast('Essay graded successfully!', 'success');
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast(res.error || 'Failed to grade essay', 'error');
            btn.disabled = false;
        }
    } catch (err) {
        showToast('Connection error', 'error');
        btn.disabled = false;
    }
}

async function gradeWithAiNow(resultId) {
    if (!confirm('Evaluate this essay immediately using AI? This may take up to 20 seconds depending on the model.')) return;
    
    // Disable all AI buttons
    document.querySelectorAll('.btn-primary[style*="8B5CF6"]').forEach(btn => {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-circle-notch fa-spin"></i> Grading...';
    });
    
    try {
        const response = await fetch('api.php?action=grade_essay_ai_now', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ result_id: resultId })
        });
        
        const data = await response.json();
        if (data.status === 'success') {
            showToast('Essay graded via AI successfully!', 'success');
            setTimeout(() => location.reload(), 1500);
        } else {
            showToast(data.error || 'AI Evaluation failed', 'error');
            document.querySelectorAll('.btn-primary[style*="8B5CF6"]').forEach(btn => {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-robot"></i> Grade with AI';
            });
        }
    } catch(err) {
        showToast('Network error evaluating essay.', 'error');
        document.querySelectorAll('.btn-primary[style*="8B5CF6"]').forEach(btn => {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-robot"></i> Grade with AI';
        });
    }
}
</script>
