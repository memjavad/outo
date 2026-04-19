    <div id="results" class="tab-pane">
        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                <h2 class="card-title" style="margin:0;"><i class="fas fa-list-check"></i> <?= $t[$lang]['student_results'] ?></h2>
                <a href="?export=csv" class="btn btn-primary" style="font-size: 0.8rem;"><i class="fas fa-file-code"></i> Export Data</a>
            </div>
            <div class="table-container">
                <table class="table-compact">
                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Score</th>
                            <th>Grade</th>
                            <th>Time</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="results-list-body">
                        <?php foreach ($results as $res): ?>
                        <tr>
                            <td><div style="font-weight:700;"><?= htmlspecialchars($res['student_name']) ?></div></td>
                            <td><?= round($res['score_percentage']) ?>%</td>
                            <td><span class="badge" style="background:<?= $res['grade'] == 'F' ? '#EF4444' : '#10B981' ?>;"><?= $res['grade'] ?></span></td>
                            <td style="font-size:0.8rem; color:var(--text-muted);"><?= date('H:i', strtotime($res['created_at'])) ?></td>
                            <td>
                                <button class="btn btn-primary" style="padding:4px 8px; font-size:0.7rem;" onclick="showReview(<?= htmlspecialchars($res['answers_json']) ?>, '<?= htmlspecialchars($res['student_name']) ?>')">Review</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
