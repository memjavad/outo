<div id="campaign_exams" class="tab-pane">
    <!-- AI SEEDER DEPLOYMENT WIDGET -->
    <div class="card" style="margin-bottom: 20px; border-left: 5px solid #00C6FF; background: var(--surface-light, #1e1e1e);">
        <h2 class="card-title" style="color: #00C6FF;"><i class="fas fa-rocket"></i> Automated AI Campaign Deployment</h2>
        <p style="color: var(--text-muted); margin-top: -10px; margin-bottom: 15px; font-size: 0.9rem;">
            Quickly inject 200 progressive levels and 4,000 generated questions directly into your database.
        </p>
        
        
        <div class="form-group" style="margin-bottom: 15px;">
            <label style="color: #bbb; font-size: 0.85rem;">Target JSON Payload URL (Direct Link or Server Path)</label>
            <input type="text" id="ai-json-url" value="https://s.nabuo.org/server/psychology/campaign_data.json" style="background: #2a2a2a; color: white; border: 1px solid #444; width: 100%; padding: 10px; border-radius: 5px;">
        </div>

        <button id="btn-run-ai-seeder" class="btn" style="background: linear-gradient(90deg, #00C6FF, #0072FF); color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
            <i class="fas fa-database"></i> Launch Injection Sequence
        </button>

        <div id="ai-seeder-progress-container" style="display: none; margin-top: 20px;">
            <div style="display: flex; justify-content: space-between; margin-bottom: 5px; font-size: 0.85rem; color: #aaa;">
                <span id="ai-seeder-status">Validating JSON payload...</span>
                <span id="ai-seeder-percentage">0%</span>
            </div>
            <div style="width: 100%; height: 10px; background: #333; border-radius: 5px; overflow: hidden;">
                <div id="ai-seeder-bar" style="width: 0%; height: 100%; background: linear-gradient(90deg, #00C6FF, #0072FF); transition: width 0.2s linear;"></div>
            </div>
        </div>
    </div>

    <script>
    document.getElementById('btn-run-ai-seeder')?.addEventListener('click', async function() {
        const jsonUrl = document.getElementById('ai-json-url').value;
        if (!jsonUrl) {
            alert("Please enter a valid URL or path to the payload.");
            return;
        }
        
        if(!confirm(`Are you sure you want to run the massive array insertion targeting:\n${jsonUrl}?`)) return;
        
        this.disabled = true;
        this.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Initializing Migration...';
        
        const container = document.getElementById('ai-seeder-progress-container');
        const statusText = document.getElementById('ai-seeder-status');
        const percentageText = document.getElementById('ai-seeder-percentage');
        const progressBar = document.getElementById('ai-seeder-bar');
        
        container.style.display = 'block';

        try {
            // Step 1: Run table migration
            statusText.innerText = "Configuring Database Core...";
            let migRes = await fetch(`seed_api.php?action=migrate`).then(r => r.json());
            if (migRes.status === 'error') throw new Error(migRes.message);

            statusText.innerText = "Migration Complete. Starting Data Insertion...";

            // Step 2: Loop chunks
            let currentIdx = 0;
            let total = 200; // Expected total
            let prevId = 'null';

            while (true) {
                let chunkRes = await fetch(`seed_api.php?action=seed_chunk&index=${currentIdx}&prev_id=${prevId}&json_url=${encodeURIComponent(jsonUrl)}`).then(r => r.json());
                
                if (chunkRes.status === 'complete') {
                    statusText.innerText = "🚀 Campaign Successfully Uploaded!";
                    progressBar.style.width = "100%";
                    percentageText.innerText = "100%";
                    break;
                }
                
                if (chunkRes.status === 'error') {
                    throw new Error(chunkRes.message);
                }

                currentIdx = chunkRes.next_index;
                prevId = chunkRes.current_exam_id;
                total = chunkRes.total_levels || 200;

                let pct = Math.floor((currentIdx / total) * 100);
                progressBar.style.width = pct + "%";
                percentageText.innerText = pct + "%";
                statusText.innerText = chunkRes.message;
            }
            
            this.innerHTML = '<i class="fas fa-check"></i> Injection Complete';
            this.style.background = '#10B981';
            
            // Reload page to display new campaigns
            setTimeout(() => location.reload(), 2000);
            
        } catch (err) {
            statusText.innerText = "❌ Error: " + err.message;
            statusText.style.color = "#EF4444";
            this.disabled = false;
            this.innerHTML = '<i class="fas fa-sync"></i> Retry Sequence';
        }
    });
    </script>

    <div class="grid" style="grid-template-columns: 400px 1fr; margin-bottom: 20px;">
        <div class="card">
            <h2 class="card-title"><i class="fas fa-plus-circle"></i> Create Story Campaign</h2>
            <form id="add-campaign-exam-form" class="add-exam-form-domain">
                <input type="hidden" name="exam_type" value="campaign">
                <div class="form-group"><label>Campaign Title</label><input type="text" name="title" placeholder="e.g. Chapter 1: Origins" required></div>
                <div class="form-group"><label>Description</label><textarea name="description" rows="3" placeholder="Story text..."></textarea></div>
                
                <div style="background:var(--surface-color); padding:10px; border-radius:8px; border:1px solid var(--border-color); margin-bottom:15px;">
                    <div class="form-group">
                        <label>Prerequisite Exam (Locks this campaign)</label>
                        <select name="prerequisite_exam_id">
                            <option value="">None (First Chapter)</option>
                            <?php foreach($exams as $ex): ?><option value="<?= $ex['id'] ?>"><?= htmlspecialchars($ex['title']) ?></option><?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Unlock Cost (Coins)</label>
                        <input type="number" name="unlock_cost" value="0" min="0">
                    </div>
                </div>

                <button type="submit" class="btn btn-primary" style="width:100%;">Create Campaign Chapter</button>
            </form>
        </div>
        <div class="card">
            <h2 class="card-title"><i class="fas fa-map"></i> Campaign Trajectory</h2>
            <div class="table-container">
                <table class="table-compact">
                    <thead><tr><th>Story Chapter</th><th>Requirements</th><th>Actions</th></tr></thead>
                    <tbody id="campaign-exam-list-body">
                        <?php foreach($campaignExams as $ex): ?>
                        <tr id="exam-row-<?= $ex['id'] ?>">
                            <td style="font-weight:600;">
                                <?= htmlspecialchars($ex['title']) ?>
                                <div style="font-size: 0.75rem; color: var(--text-muted);"><?= htmlspecialchars($ex['description'] ?? '') ?></div>
                            </td>
                            <td>
                                <?php if($ex['prerequisite_exam_id']): ?>
                                    <span class="badge" style="background:#F59E0B; font-size: 0.65rem;">Locked by ID: <?= $ex['prerequisite_exam_id'] ?></span>
                                <?php endif; ?>
                                <?php if($ex['unlock_cost'] > 0): ?>
                                    <span class="badge" style="background:#EAB308; font-size: 0.65rem; color:#000;">Cost: <?= $ex['unlock_cost'] ?> Coins</span>
                                <?php endif; ?>
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

    <!-- Campaign Questions -->
    <div class="grid" style="grid-template-columns: 400px 1fr;">
        <div class="card">
            <h2 class="card-title"><i class="fas fa-file-signature"></i> Create Campaign Element</h2>
            <form id="add-campaign-question-form" class="add-question-form-domain">
                <input type="hidden" name="domain" value="campaign">
                <div class="form-grid" style="grid-template-columns: 1fr 1fr; gap: 15px;">
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category_id">
                            <option value="">General</option>
                            <?php foreach($categories as $cat): ?><option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option><?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Link to Chapter</label>
                        <select name="exam_id" id="campaign-question-exam-select">
                            <option value="">None (Universal Campaign pool)</option>
                            <?php foreach($campaignExams as $ex): ?><option value="<?= $ex['id'] ?>"><?= htmlspecialchars($ex['title']) ?></option><?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div class="form-group"><label>Story Element (Question)</label><textarea name="question_text" rows="2" required></textarea></div>
                <div class="form-grid" style="grid-template-columns:1fr 1fr;">
                    <input type="text" name="option_0" placeholder="Option 1" required>
                    <input type="text" name="option_1" placeholder="Option 2" required>
                    <input type="text" name="option_2" placeholder="Option 3" required>
                    <input type="text" name="option_3" placeholder="Option 4" required>
                </div>
                <div class="form-group"><label>Correct Index</label><select name="correct_index"><option value="0">1</option><option value="1">2</option><option value="2">3</option><option value="3">4</option></select></div>
                <div class="form-group"><label>Image (Optional)</label><input type="file" name="question_image" accept="image/*"></div>
                <button type="submit" class="btn btn-primary" style="width:100%;">Add to Campaign Bank</button>
            </form>
        </div>
        <div class="card">
            <h2 class="card-title"><i class="fas fa-database"></i> Campaign Question Bank</h2>
            <div class="table-container">
                <table class="table-compact">
                    <thead><tr><th>Story Element</th><th>Actions</th></tr></thead>
                    <tbody id="campaign-question-list-body">
                        <?php foreach($campaignQuestions as $q): ?>
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
