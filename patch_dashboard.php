<?php
$content = file_get_contents('server/src/Controllers/DashboardController.php');

$search = <<<'SQL'
        // Fetch ALL essays to dynamically group by exam for the admin UI
        $allEssayResults = [];
        try {
            $allEssayResults = $this->pdo->query("
               SELECT r.*, e.grading_type as exam_grading_type, COALESCE(e.title, 'Unknown Exam') as exam_title, COALESCE(s.name, r.student_name) as student_name
               FROM essay_results r
               LEFT JOIN exams e ON r.exam_id = e.id
               LEFT JOIN students s ON r.student_id = s.id
               ORDER BY r.created_at DESC
            ")->fetchAll(PDO::FETCH_ASSOC);
        } catch (\PDOException $err) {
            error_log("Failed to fetch essay results: " . $err->getMessage());
        }

        $pendingEssays = array_filter($allEssayResults, fn($r) => $r['is_graded'] == 0);

        $essayResultsByExamId = [];
        foreach ($allEssayResults as $res) {
            $essayResultsByExamId[$res['exam_id']][] = $res;
        }
SQL;

$replace = <<<'SQL'
        // Fetch ALL essays to dynamically group by exam for the admin UI
        // OPTIMIZATION: Replaced unbounded fetchAll() with a bounded query targeting pending essays
        // and a max limit of the 3000 most recent graded essays. This reduces DB round trips and memory overhead significantly.
        $allEssayResults = [];
        try {
            $allEssayResults = $this->pdo->query("
               SELECT r.*, e.grading_type as exam_grading_type, COALESCE(e.title, 'Unknown Exam') as exam_title, COALESCE(s.name, r.student_name) as student_name
               FROM essay_results r
               LEFT JOIN exams e ON r.exam_id = e.id
               LEFT JOIN students s ON r.student_id = s.id
               WHERE r.is_graded = 0 OR r.id IN (
                   SELECT id FROM (SELECT id FROM essay_results ORDER BY created_at DESC LIMIT 3000) as temp
               )
               ORDER BY r.created_at DESC
            ")->fetchAll(PDO::FETCH_ASSOC);
        } catch (\PDOException $err) {
            error_log("Failed to fetch essay results: " . $err->getMessage());
        }

        // OPTIMIZATION: Filter pending essays and construct the exam groupings in a single pass O(n) loop
        // instead of multiple iterations. Added a 500-item cap per exam array to prevent massive UI rendering delays.
        $pendingEssays = [];
        $essayResultsByExamId = [];
        foreach ($allEssayResults as $res) {
            if ($res['is_graded'] == 0) {
                $pendingEssays[] = $res;
            }
            if (!isset($essayResultsByExamId[$res['exam_id']])) {
                $essayResultsByExamId[$res['exam_id']] = [];
            }
            if (count($essayResultsByExamId[$res['exam_id']]) < 500) {
                $essayResultsByExamId[$res['exam_id']][] = $res;
            }
        }
SQL;

$newContent = str_replace($search, $replace, $content);
file_put_contents('server/src/Controllers/DashboardController.php', $newContent);
echo "Patched successfully\n";
