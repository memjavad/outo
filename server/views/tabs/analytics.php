    <div id="analytics" class="tab-pane active">
        <div class="stats-grid">
            <div class="card stat-card">
                <div class="stat-icon" style="background: rgba(99, 102, 241, 0.1); color: var(--primary-color);"><i class="fas fa-user-graduate"></i></div>
                <div class="stat-details"><h3 id="stat-students"><?= count($students) ?></h3><p><?= $t[$lang]['total_students'] ?></p></div>
            </div>
            <div class="card stat-card">
                <div class="stat-icon" style="background: rgba(16, 185, 129, 0.1); color: var(--accent-color);"><i class="fas fa-file-lines"></i></div>
                <div class="stat-details"><h3 id="stat-exams"><?= count($exams) ?></h3><p><?= $t[$lang]['active_exams'] ?></p></div>
            </div>
            <div class="card stat-card">
                <div class="stat-icon" style="background: rgba(245, 158, 11, 0.1); color: #F59E0B;"><i class="fas fa-circle-question"></i></div>
                <div class="stat-details"><h3 id="stat-questions"><?= count($questions) ?></h3><p><?= $t[$lang]['total_questions'] ?></p></div>
            </div>
            <div class="card stat-card" onclick="showTab('students')" style="cursor:pointer;">
                <div class="stat-icon" style="background: rgba(239, 68, 68, 0.1); color: #EF4444;"><i class="fas fa-user-clock"></i></div>
                <div class="stat-details"><h3 id="stat-pending"><?= count($pendingStudents) ?></h3><p>Pending Students</p></div>
            </div>
        </div>

        <div class="grid" style="margin-top: 16px;">
            <div class="card" style="grid-column: span 2;">
                <h2 class="card-title"><i class="fas fa-chart-area"></i> <?= $t[$lang]['results_distribution'] ?></h2>
                <div style="height: 350px;"><canvas id="gradeChart"></canvas></div>
            </div>
            <div class="card">
                <h2 class="card-title"><i class="fas fa-bolt"></i> Live Feed</h2>
                <div id="live-activity" style="font-size: 0.85rem; color: var(--text-muted);">
                    <p style="text-align:center; padding:20px;">Watching for student activity...</p>
                </div>
            </div>
        </div>
    </div>
