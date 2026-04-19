<div id="standard_exams" class="tab-pane">
    <div class="grid" style="grid-template-columns: 400px 1fr; margin-bottom: 20px;">
        <div class="card">
            <h2 class="card-title"><i class="fas fa-plus-circle"></i> Create Standard Exam</h2>
            <form id="add-standard-exam-form" class="add-exam-form-domain">
                <input type="hidden" name="exam_type" value="standard">
                <div class="form-group"><label>Exam Title</label><input type="text" name="title" placeholder="e.g. Midterm 2024" required></div>
                <div class="form-group"><label>Description</label><textarea name="description" rows="3" placeholder="Optional details..."></textarea></div>
                <button type="submit" class="btn btn-primary" style="width:100%;">Create Standard Exam</button>
            </form>
        </div>
        <div class="card">
            <h2 class="card-title"><i class="fas fa-book-open"></i> Standard Exams</h2>
            <div class="table-container">
                <table class="table-compact">
                    <thead><tr><th>Title</th><th>Status</th><th>Actions</th></tr></thead>
                    <tbody id="standard-exam-list-body">
                        <?php foreach($standardExams as $ex): ?>
                        <tr id="exam-row-<?= $ex['id'] ?>">
                            <td style="font-weight:600;"><?= htmlspecialchars($ex['title']) ?></td>
                            <td>
                                <span class="badge" style="background:<?= $ex['is_active'] ? '#10B981' : '#6B7280' ?>; margin-bottom: 4px; display: inline-block;"><?= $ex['is_active'] ? 'Active' : 'Draft' ?></span><br>
                                <span class="badge" style="background:#3B82F6; font-size: 0.65rem;">Standard</span>
                            </td>
                            <td>
                                <button class="btn btn-primary" style="padding:4px 8px; font-size:0.7rem;" onclick='showEditExam(<?= $ex["id"] ?>, <?= json_encode(json_encode($ex)) ?>)'><i class="fas fa-edit"></i></button>
                                <button class="btn btn-danger" style="padding:4px 8px; font-size:0.7rem;" onclick="deleteItem('exam', <?= $ex['id'] ?>)"><i class="fas fa-trash"></i></button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div class="grid" style="grid-template-columns: 400px 1fr;">
        <div class="card">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
                <h2 class="card-title" style="margin:0;"><i class="fas fa-file-signature"></i> Create Question</h2>
                <button class="btn btn-secondary" onclick="document.getElementById('importExcelModal').style.display='block'" style="padding:6px 12px; font-size:0.8rem; background: #10B981; color: white; border: none; cursor:pointer; border-radius:6px;"><i class="fas fa-file-excel"></i> Bulk Import</button>
            </div>
            <form id="add-standard-question-form" class="add-question-form-domain">
                <input type="hidden" name="domain" value="standard">
                <div class="form-grid" style="grid-template-columns: 1fr 1fr; gap: 15px;">
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category_id">
                            <option value="">General</option>
                            <?php foreach($categories as $cat): ?><option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option><?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Link to Exam</label>
                        <select name="exam_id" id="standard-question-exam-select">
                            <option value="">None (Universal)</option>
                            <?php foreach($standardExams as $ex): ?><option value="<?= $ex['id'] ?>"><?= htmlspecialchars($ex['title']) ?></option><?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div class="form-group"><label>Question Text</label><textarea name="question_text" rows="2" required></textarea></div>
                <div class="form-grid" style="grid-template-columns:1fr 1fr;">
                    <input type="text" name="option_0" placeholder="Option 1" required>
                    <input type="text" name="option_1" placeholder="Option 2" required>
                    <input type="text" name="option_2" placeholder="Option 3" required>
                    <input type="text" name="option_3" placeholder="Option 4" required>
                </div>
                <div class="form-group"><label>Correct Index</label><select name="correct_index"><option value="0">1</option><option value="1">2</option><option value="2">3</option><option value="3">4</option></select></div>
                <div class="form-group"><label>Image (Optional)</label><input type="file" name="question_image" accept="image/*"></div>
                <button type="submit" class="btn btn-primary" style="width:100%;">Add to Standard Bank</button>
            </form>
        </div>
        <div class="card">
            <h2 class="card-title"><i class="fas fa-database"></i> Standard Question Bank</h2>
            <div class="table-container">
                <table class="table-compact">
                    <thead><tr><th>Question</th><th>Actions</th></tr></thead>
                    <tbody id="standard-question-list-body">
                        <?php foreach($standardQuestions as $q): ?>
                        <tr id="question-row-<?= $q['id'] ?>">
                            <td>
                                <div style="font-weight:600;"><?= htmlspecialchars($q['question_text']) ?></div>
                                <?php if($q['image_url']): ?><img src="<?= htmlspecialchars($q['image_url']) ?>" style="height:35px; margin-top:5px; border-radius:4px;"><?php endif; ?>
                            </td>
                            <td>
                                <button class="btn btn-primary" style="padding:4px 8px; font-size:0.7rem;" onclick="showEditQuestion(<?= $q['id'] ?>)"><i class="fas fa-edit"></i></button>
                                <button class="btn btn-danger" style="padding:4px 8px; font-size:0.7rem;" onclick="deleteItem('question', <?= $q['id'] ?>)"><i class="fas fa-trash"></i></button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
