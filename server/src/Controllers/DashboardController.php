<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Config;
use PDO;

class DashboardController extends BaseController {
    private $pdo;
    private $lang;
    private $t;

    public function __construct() {
        $this->pdo = Database::getInstance();
        $this->lang = $_SESSION['lang'] ?? 'en';
        $this->t = $this->getTranslations();
    }

    public function index() {
        $isLoggedIn = isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
        $forcePasswordChange = isset($_SESSION['force_password_change']) && $_SESSION['force_password_change'] === true;
        $csrfToken = $_SESSION['csrf_token'];
        $lang = $this->lang;
        $t = $this->t;

        // Check if platform is in "Initial Setup" mode
        $noAdmins = $this->pdo->query("SELECT COUNT(*) FROM admins")->fetchColumn() == 0;

        if (!$isLoggedIn || $forcePasswordChange) {
            $this->render('header', compact('isLoggedIn', 'forcePasswordChange', 'csrfToken', 'lang', 't', 'noAdmins'));
            $this->render('footer');
            return;
        }

        // Load Repositories
        $studentRepo = new \App\Repositories\StudentRepository($this->pdo);
        $examRepo = new \App\Repositories\ExamRepository($this->pdo);
        $settingsRepo = new \App\Repositories\SettingsRepository($this->pdo);

        // Fetch data for the dashboard
        $students = $studentRepo->getAllEnrolled();
        $pendingStudents = $studentRepo->getPending();
        $categories = $this->pdo->query("SELECT * FROM categories ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        
        $questions = $this->pdo->query("SELECT q.*, c.name as category_name FROM questions q LEFT JOIN categories c ON q.category_id = c.id ORDER BY q.created_at DESC")->fetchAll(PDO::FETCH_ASSOC);
        $standardQuestions = array_filter($questions, fn($q) => ($q['domain'] ?? 'standard') === 'standard');
        $campaignQuestions = array_filter($questions, fn($q) => ($q['domain'] ?? 'standard') === 'campaign');
        $essayQuestions = array_filter($questions, fn($q) => ($q['domain'] ?? 'standard') === 'essay');

        // Merge standard exams and essay submissions natively into the global results table
        $results = $this->pdo->query("
            SELECT student_name, score_percentage, COALESCE(grade, '') as grade, answers_json, created_at
            FROM results 
            UNION ALL 
            SELECT student_name, score_percentage, COALESCE(grade, '') as grade, answers_json, created_at
            FROM essay_results 
            ORDER BY created_at DESC
        ")->fetchAll(PDO::FETCH_ASSOC);
        
        $exams = []; 
        try {
            $exams = $examRepo->getAllForAdmin();
        } catch (\Exception $e) {}
        
        $standardExams = array_filter($exams, fn($e) => ($e['exam_type'] ?? 'standard') === 'standard');
        $campaignExams = array_filter($exams, fn($e) => ($e['exam_type'] ?? 'standard') === 'campaign');
        $essayExams = array_filter($exams, fn($e) => ($e['exam_type'] ?? 'standard') === 'essay');

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
        
        $settings = $settingsRepo->getAll();
        
        $appTitle = $settings['app_title'] ?? 'Student Quiz';
        $primaryColor = $settings['primary_color'] ?? '#673AB7';
        $examTimer = $settings['exam_timer'] ?? '10';
        $questionTimer = $settings['question_timer'] ?? '0';
        $randomizeQ = $settings['randomize_questions'] ?? '1';
        $randomizeO = $settings['randomize_options'] ?? '1';
        $strictAppFocus = $settings['strict_app_focus'] ?? '0';
        $detectVpn = $settings['detect_vpn'] ?? '0';
        $requireGps = $settings['require_gps'] ?? '0';
        $recordScreen = $settings['record_screen'] ?? '0';
        $preventScreenshots = $settings['prevent_screenshots'] ?? '1';
        $requireBiometrics = $settings['require_biometrics'] ?? '0';
        $requireTgLogin = $settings['require_tg_login'] ?? '0';
        $tgBotUsername = $settings['tg_bot_username'] ?? '';
        $tgBotToken = $settings['tg_bot_token'] ?? '';
        $allowReview = $settings['allow_review'] ?? '1';
        $allowBacktracking = $settings['allow_backtracking'] ?? '1';
        $requireAccessCode = $settings['require_access_code'] ?? '0';
        $recordAudio = $settings['record_audio'] ?? '0';
        $immediateFeedback = $settings['immediate_feedback'] ?? '0';
        $flexColorScheme = $settings['flex_color_scheme'] ?? 'blueWhale';
        $systemVersion = $settings['system_version'] ?? '1.3.12';
        $aiApiKey = $settings['ai_api_key'] ?? '';
        $aiModel = $settings['ai_model'] ?? 'gemini-3.0-flash';

        // Calculate Grade Distribution
        $grades = ['A'=>0, 'B'=>0, 'C'=>0, 'D'=>0, 'F'=>0];
        $counts = array_count_values(array_column($results, 'grade'));

        foreach ($counts as $grade => $count) {
            if (isset($grades[$grade])) {
                $grades[$grade] = $count;
            }
        }

        $gradeDistribution = [];
        foreach ($grades as $grade => $count) {
            $gradeDistribution[] = ['grade' => $grade, 'count' => $count];
        }

        // Render main views
        include __DIR__ . '/../../views/header.php';
        include __DIR__ . '/../../views/dashboard.php';
        include __DIR__ . '/../../views/footer.php';
    }

    public function handlePost($data, $files) {
        if (!isset($data['csrf_token']) || $data['csrf_token'] !== $_SESSION['csrf_token']) {
            die("Invalid CSRF token.");
        }

        if (isset($data['login'])) {
            $auth = new AuthController();
            if ($auth->webLogin($data)) {
                header("Location: index.php");
                exit();
            }
        }

        if (isset($data['register_admin'])) {
            $auth = new AuthController();
            if ($auth->registerFirstAdmin($data)) {
                header("Location: index.php");
                exit();
            }
        }
        
        // Bulk CSV Import
        if (isset($data['import_students']) && isset($files['student_csv']) && $files['student_csv']['error'] === UPLOAD_ERR_OK) {
            $filename = $files['student_csv']['tmp_name'];
            $file = fopen($filename, "r");
            if ($file) {
                // Generate a CSV response immediately
                header('Content-Type: text/csv; charset=utf-8');
                header('Content-Disposition: attachment; filename=import_results.csv');
                $output = fopen('php://output', 'w');
                fputcsv($output, ['Name', 'Phone', 'Password', 'Status']);

                $db = Database::getInstance();
                $firstRow = true;

                while (($row = fgetcsv($file)) !== FALSE) {
                    if ($firstRow && strtolower(trim($row[0])) === 'name') {
                        $firstRow = false;
                        continue;
                    }

                    $name = trim($row[0] ?? '');
                    $phone = trim($row[1] ?? '');
                    $password = trim($row[2] ?? '');
                    
                    if (empty($name) || empty($phone) || empty($password)) {
                        fputcsv($output, [$name, $phone, '***', 'Failed: Missing Name, Phone, or Password fields.']);
                        continue;
                    }

                    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
                    $accessCode = null;

                    try {
                        $stmt = $db->prepare("INSERT INTO students (name, phone, password_hash, access_code, enrolled) VALUES (?, ?, ?, ?, 1)");
                        $stmt->execute([$name, $phone, $passwordHash, $accessCode]);
                        fputcsv($output, [$name, $phone, '***', 'Added successfully']);
                    } catch (\PDOException $e) {
                         if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
                              fputcsv($output, [$name, $phone, '***', 'Failed: Student with this Phone Number already exists.']);
                         } else {
                             fputcsv($output, [$name, $phone, '***', 'Failed: ' . $e->getMessage()]);
                         }
                    }
                }
                fclose($file);
                fclose($output);
                exit();
            }
        }
        
        // Settings update (if still using standard POST)
        if (isset($data['app_title'])) {
            $settings = new SettingsController();
            $settings->updateSettings($data);
            header("Location: index.php");
            exit();
        }
    }

    public function logout() {
        session_destroy();
        header("Location: index.php");
        exit();
    }

    private function render($view, $data = []) {
        extract($data);
        include __DIR__ . "/../../views/{$view}.php";
    }

    private function getTranslations() {
        // Return the large translation array (or load from file)
        return [
            'en' => [
                'dashboard' => 'Teacher Dashboard',
                'login' => 'Admin Login',
                'username' => 'Username',
                'password' => 'Password',
                'login_btn' => 'Login',
                'logout' => 'Logout',
                'app_appearance' => 'Settings',
                'total_students' => 'Total Students',
                'active_exams' => 'Active Exams',
                'total_questions' => 'Total Questions',
                'submitted_exams' => 'Submitted Exams',
                'results_distribution' => 'Results Distribution',
                'student_results' => 'Student Results',
                'manage_students' => 'Manage Students',
                'manage_questions' => 'Manage Questions',
                'manage_quizzes' => 'Manage Quizzes',
                'analytics' => 'Analytics',
                'app_title' => 'App Title',
                'primary_color' => 'Primary Color',
                'flex_color_scheme' => 'Flex Color Scheme',
                'change_password' => 'Change Password',
                'new_password' => 'New Password',
                'confirm_password' => 'Confirm Password',
                'update_btn' => 'Update',
                'setup_admin' => 'Setup Admin Account',
                'no_admins_msg' => 'No administrators found. Create the first one to begin.',
                'create_login_btn' => 'Create & Login'
            ],
            'ar' => [
                'dashboard' => 'لوحة تحكم المعلم',
                'login' => 'تسجيل دخول المسؤول',
                'username' => 'اسم المستخدم',
                'password' => 'كلمة المرور',
                'login_btn' => 'دخول',
                'logout' => 'تسجيل خروج',
                'app_appearance' => 'الإعدادات',
                'total_students' => 'إجمالي الطلاب',
                'active_exams' => 'الاختبارات النشطة',
                'total_questions' => 'إجمالي الأسئلة',
                'submitted_exams' => 'الاختبارات المسلمة',
                'results_distribution' => 'توزيع النتائج',
                'student_results' => 'نتائج الطلاب',
                'manage_students' => 'إدارة الطلاب',
                'manage_questions' => 'إدارة الأسئلة',
                'manage_quizzes' => 'إدارة الاختبارات',
                'analytics' => 'التحليلات',
                'app_title' => 'عنوان التطبيق',
                'primary_color' => 'اللون الأساسي',
                'flex_color_scheme' => 'مظهر الألوان المرنة',
                'change_password' => 'تغيير كلمة المرور',
                'new_password' => 'كلمة المرور الجديدة',
                'confirm_password' => 'تأكيد كلمة المرور',
                'update_btn' => 'تحديث',
                'setup_admin' => 'إعداد حساب المسؤول',
                'no_admins_msg' => 'لم يتم العثور على مسؤولين. قم بإنشاء الحساب الأول للبدء.',
                'create_login_btn' => 'إنشاء ودخول'
            ]
        ];
    }
}
