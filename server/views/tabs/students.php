    <div id="students" class="tab-pane">
        <div class="grid">
            <div class="card">
                <h2 class="card-title"><i class="fas fa-user-plus"></i> Add Student</h2>
                <form id="add-student-form">
                    <div class="form-group"><label>Full Name</label><input type="text" name="name" required></div>
                    <div class="form-group"><label>Phone Number (Username)</label><input type="text" name="phone" required></div>
                    <div class="form-group"><label>Password</label><input type="text" name="password" required></div>
                    <button type="submit" class="btn btn-primary" style="width:100%;">Save Student Role</button>
                </form>
                <div style="margin-top:16px; padding-top:16px; border-top:1px solid #eee;">
                    <form method="POST" enctype="multipart/form-data">
                        <input type="hidden" name="csrf_token" value="<?= $csrfToken ?>">
                        <label style="font-size:0.8rem; color:var(--text-muted);">Bulk Import CSV (Format: Name, Phone, Password)</label>
                        <input type="file" name="student_csv" accept=".csv" class="form-group" style="font-size:0.7rem;">
                        <button type="submit" name="import_students" class="btn btn-secondary" style="width:100%;">Upload List</button>
                    </form>
                </div>
            </div>
            <div class="card" style="grid-column: span 2;">
                <h2 class="card-title"><i class="fas fa-user-clock"></i> Pending Approvals (<?= count($pendingStudents) ?>)</h2>
                <div class="table-container" style="margin-bottom: 16px;">
                    <table class="table-compact" style="background: #fff9f0;">
                        <thead><tr><th>Name</th><th>Phone</th><th>Actions</th></tr></thead>
                        <tbody id="pending-list-body">
                            <?php foreach ($pendingStudents as $ps): ?>
                            <tr id="pending-row-<?= $ps['id'] ?>">
                                <td style="font-weight:600;"><?= htmlspecialchars($ps['name']) ?></td>
                                <td><?= htmlspecialchars($ps['phone']) ?></td>
                                <td style="display:flex; gap:10px;">
                                    <button class="btn btn-primary" style="background:#10B981; padding:8px 15px;" onclick="approveStudent(<?= $ps['id'] ?>)"><i class="fas fa-check"></i> Approve</button>
                                    <button class="btn btn-danger" style="padding:8px 15px;" onclick="rejectStudent(<?= $ps['id'] ?>)"><i class="fas fa-times"></i> Reject</button>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>

                <h2 class="card-title"><i class="fas fa-users-gear"></i> Student Directory</h2>
                <div class="table-container">
                    <table class="table-compact">
                        <thead><tr><th>Name</th><th>Phone Number (Username)</th><th>Actions</th></tr></thead>
                        <tbody id="student-list-body">
                            <?php foreach ($students as $stu): ?>
                            <tr id="student-row-<?= $stu['id'] ?>">
                                <td style="font-weight:600;"><?= htmlspecialchars($stu['name']) ?></td>
                                <td><code><?= htmlspecialchars($stu['phone'] ?? $stu['email'] ?? $stu['access_code']) ?></code></td>
                                <td><button class="btn btn-danger" onclick="deleteItem('student', <?= $stu['id'] ?>)"><i class="fas fa-trash"></i></button></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
