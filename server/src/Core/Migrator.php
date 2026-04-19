<?php
namespace App\Core;

use PDO;
use PDOException;

class Migrator {
    private $pdo;

    public function __construct(PDO $pdo) {
        $this->pdo = $pdo;
    }

    public function up() {
        try {
            $execSilent = function($sql) {
                try {
                    $this->pdo->exec($sql);
                } catch (\PDOException $e) { /* Ignore */ }
            };

            $createCategoriesTable = "
                CREATE TABLE IF NOT EXISTS categories (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ";
            $this->pdo->exec($createCategoriesTable);

            $createQuestionsTable = "
                CREATE TABLE IF NOT EXISTS questions (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    category_id INT DEFAULT NULL,
                    question_text TEXT NOT NULL,
                    rich_text TEXT DEFAULT NULL,
                    correct_answer_index INT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
                );
            ";
            $this->pdo->exec($createQuestionsTable);

            // ALTER existing table if needed
            try {
                $this->pdo->exec("ALTER TABLE questions ADD COLUMN category_id INT DEFAULT NULL");
                $this->pdo->exec("ALTER TABLE questions ADD CONSTRAINT fk_cat FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL");
                $this->pdo->exec("ALTER TABLE questions ADD COLUMN rich_text TEXT DEFAULT NULL");
            } catch (PDOException $e) {
                // columns probably already exist, safe to ignore
            }

            $createOptionsTable = "
                CREATE TABLE IF NOT EXISTS options (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    question_id INT NOT NULL,
                    option_text VARCHAR(255) NOT NULL,
                    option_index INT NOT NULL,
                    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
                );
            ";
            $this->pdo->exec($createOptionsTable);

            $createResultsTable = "
                CREATE TABLE IF NOT EXISTS results (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    student_name VARCHAR(100) NOT NULL,
                    score_percentage FLOAT NOT NULL,
                    grade VARCHAR(10) NOT NULL,
                    total_questions INT NOT NULL,
                    correct_answers INT NOT NULL,
                    time_taken_seconds INT NOT NULL,
                    gps_location VARCHAR(255) DEFAULT NULL,
                    cheat_flag VARCHAR(255) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ";
            $this->pdo->exec($createResultsTable);

            $createSettingsTable = "
                CREATE TABLE IF NOT EXISTS settings (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    setting_key VARCHAR(50) UNIQUE NOT NULL,
                    setting_value VARCHAR(255) NOT NULL
                );
            ";
            $this->pdo->exec($createSettingsTable);

            $createTgAuthSessionsTable = "
                CREATE TABLE IF NOT EXISTS tg_auth_sessions (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    session_id VARCHAR(255) NOT NULL UNIQUE,
                    status VARCHAR(50) DEFAULT 'pending',
                    auth_date BIGINT DEFAULT NULL,
                    first_name VARCHAR(255) DEFAULT NULL,
                    username VARCHAR(255) DEFAULT NULL,
                    photo_url VARCHAR(500) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ";
            $this->pdo->exec($createTgAuthSessionsTable);

            $createStudentsTable = "
                CREATE TABLE IF NOT EXISTS students (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    access_code VARCHAR(50) UNIQUE DEFAULT NULL,
                    name VARCHAR(100) NOT NULL,
                    email VARCHAR(100) UNIQUE DEFAULT NULL,
                    phone VARCHAR(50) UNIQUE DEFAULT NULL,
                    password_hash VARCHAR(255) DEFAULT NULL,
                    bio TEXT DEFAULT NULL,
                    profile_image VARCHAR(500) DEFAULT NULL,
                    enrolled TINYINT(1) DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ";
            $this->pdo->exec($createStudentsTable);

            // Helper function to silently execute schema changes that might already exist
            $execSilent = function($sql) {
                try {
                    $this->pdo->exec($sql);
                } catch (PDOException $e) {}
            };

            // ALTER existing table for new student fields
            $execSilent("ALTER TABLE students ADD COLUMN email VARCHAR(100) UNIQUE DEFAULT NULL");
            $execSilent("ALTER TABLE students ADD COLUMN phone VARCHAR(50) UNIQUE DEFAULT NULL");
            $execSilent("ALTER TABLE students ADD COLUMN password_hash VARCHAR(255) DEFAULT NULL");
            $execSilent("ALTER TABLE students ADD COLUMN bio TEXT DEFAULT NULL");
            $execSilent("ALTER TABLE students ADD COLUMN profile_image VARCHAR(500) DEFAULT NULL");
            $execSilent("ALTER TABLE students ADD COLUMN enrolled TINYINT(1) DEFAULT 0");
            $execSilent("ALTER TABLE students MODIFY COLUMN access_code VARCHAR(50) DEFAULT NULL");

            $createStudentTokensTable = "
                CREATE TABLE IF NOT EXISTS student_tokens (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    student_id INT NOT NULL,
                    token VARCHAR(255) UNIQUE NOT NULL,
                    expires_at DATETIME NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
                );
            ";
            $this->pdo->exec($createStudentTokensTable);

            // Insert default settings if they don't exist
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('app_title', 'Student Quiz')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('primary_color', '#673AB7')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('exam_timer', '10')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('randomize_questions', '1')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('randomize_options', '1')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('strict_app_focus', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('question_timer', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('require_gps', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('record_screen', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('prevent_screenshots', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('detect_vpn', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('require_biometrics', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('require_tg_login', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('tg_bot_username', '')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('tg_bot_token', '')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('allow_review', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('allow_backtracking', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('require_access_code', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('exam_start_date', '')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('exam_end_date', '')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('record_audio', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('immediate_feedback', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('flex_color_scheme', 'blueWhale')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('api_key', '')");

            $createAdminsTable = "
                CREATE TABLE IF NOT EXISTS admins (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    username VARCHAR(50) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    role ENUM('admin','teacher','viewer') NOT NULL DEFAULT 'admin',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ";
            $this->pdo->exec($createAdminsTable);

            $execSilent("ALTER TABLE admins ADD COLUMN role ENUM('admin','teacher','viewer') NOT NULL DEFAULT 'admin'");

            $defaultAdminPass = password_hash('password', PASSWORD_DEFAULT);
            $this->pdo->exec("INSERT IGNORE INTO admins (username, password_hash, role) VALUES ('admin', '$defaultAdminPass', 'admin')");

            $this->pdo->exec("CREATE TABLE IF NOT EXISTS exams (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT DEFAULT NULL,
                is_active TINYINT(1) DEFAULT 1,
                created_by INT DEFAULT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE SET NULL
            )");

            $execSilent("ALTER TABLE exams ADD COLUMN exam_timer INT NOT NULL DEFAULT 10");
            $execSilent("ALTER TABLE exams ADD COLUMN question_timer INT NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN randomize_questions TINYINT(1) NOT NULL DEFAULT 1");
            $execSilent("ALTER TABLE exams ADD COLUMN randomize_options TINYINT(1) NOT NULL DEFAULT 1");
            $execSilent("ALTER TABLE exams ADD COLUMN strict_app_focus TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN detect_vpn TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN require_gps TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN record_screen TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN require_biometrics TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN require_tg_login TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN require_access_code TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN record_audio TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN immediate_feedback TINYINT(1) NOT NULL DEFAULT 0");
            $execSilent("ALTER TABLE exams ADD COLUMN prevent_screenshots TINYINT(1) NOT NULL DEFAULT 1");
            $execSilent("ALTER TABLE exams ADD COLUMN allow_review TINYINT(1) NOT NULL DEFAULT 1");
            $execSilent("ALTER TABLE exams ADD COLUMN allow_backtracking TINYINT(1) NOT NULL DEFAULT 1");
            $execSilent("ALTER TABLE exams ADD COLUMN exam_start_date DATETIME DEFAULT NULL");
            $execSilent("ALTER TABLE exams ADD COLUMN exam_end_date DATETIME DEFAULT NULL");
            $execSilent("ALTER TABLE exams ADD COLUMN exam_type ENUM('standard', 'campaign', 'essay') NOT NULL DEFAULT 'standard'");
            $execSilent("ALTER TABLE exams ADD COLUMN grading_type VARCHAR(50) DEFAULT 'percentage'");
            $execSilent("ALTER TABLE exams ADD COLUMN rubric TEXT DEFAULT NULL"); // Added
            $execSilent("ALTER TABLE essay_results ADD COLUMN scheduled_grading_time DATETIME DEFAULT NULL"); // Added
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('ai_api_key', '')"); // Added
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('ai_model', 'gemini-3.0-flash')"); // Added
            $execSilent("ALTER TABLE exams ADD COLUMN prerequisite_exam_id INT DEFAULT NULL");
            $execSilent("ALTER TABLE exams ADD CONSTRAINT fk_prereq_exam FOREIGN KEY (prerequisite_exam_id) REFERENCES exams(id) ON DELETE SET NULL");
            $execSilent("ALTER TABLE exams ADD COLUMN unlock_cost INT NOT NULL DEFAULT 0");

            $execSilent("ALTER TABLE questions ADD COLUMN exam_id INT DEFAULT NULL");
            $execSilent("ALTER TABLE questions ADD CONSTRAINT fk_exam_q FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE SET NULL");

            $execSilent("ALTER TABLE results ADD COLUMN exam_id INT DEFAULT NULL");
            $execSilent("ALTER TABLE results ADD CONSTRAINT fk_exam_r FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE SET NULL");
            $execSilent("ALTER TABLE results ADD COLUMN student_id INT DEFAULT NULL");
            $execSilent("ALTER TABLE results ADD CONSTRAINT fk_student_r FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL");

            $execSilent("ALTER TABLE questions ADD COLUMN points INT NOT NULL DEFAULT 1");
            $execSilent("ALTER TABLE questions ADD COLUMN image_url VARCHAR(500) DEFAULT NULL");
            // Switch away from rigid ENUMs avoiding 'essay' strings failing under MySQL strict mode bindings
            $execSilent("ALTER TABLE questions MODIFY COLUMN question_type VARCHAR(50) NOT NULL DEFAULT 'single'");
            $execSilent("ALTER TABLE questions ADD COLUMN domain VARCHAR(50) NOT NULL DEFAULT 'standard'");
            $execSilent("ALTER TABLE results ADD COLUMN answers_json TEXT DEFAULT NULL");
            $execSilent("ALTER TABLE results ADD COLUMN is_graded TINYINT(1) DEFAULT 1");
            $execSilent("ALTER TABLE results ADD COLUMN teacher_feedback TEXT DEFAULT NULL");

            $this->pdo->exec("CREATE TABLE IF NOT EXISTS active_sessions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                student_name VARCHAR(100) NOT NULL,
                exam_id INT DEFAULT NULL,
                current_question INT DEFAULT 0,
                total_questions INT DEFAULT 0,
                answered_count INT DEFAULT 0,
                ip_address VARCHAR(45) DEFAULT NULL,
                started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_heartbeat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                status ENUM('active','completed','abandoned') DEFAULT 'active',
                FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE SET NULL
            )");

            $this->pdo->exec("CREATE TABLE IF NOT EXISTS admin_tokens (
                id INT AUTO_INCREMENT PRIMARY KEY,
                admin_id INT NOT NULL,
                token VARCHAR(255) UNIQUE NOT NULL,
                expires_at DATETIME NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE
            )");

            $this->pdo->exec("CREATE TABLE IF NOT EXISTS audit_log (
                id INT AUTO_INCREMENT PRIMARY KEY,
                admin_id INT DEFAULT NULL,
                action VARCHAR(100) NOT NULL,
                details TEXT DEFAULT NULL,
                ip_address VARCHAR(45) DEFAULT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_action (action),
                INDEX idx_time (created_at)
            )");

            $this->pdo->exec("CREATE TABLE IF NOT EXISTS webhooks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                event_name VARCHAR(100) NOT NULL,
                url VARCHAR(500) NOT NULL,
                is_active TINYINT(1) DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )");

            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('ip_whitelist', '')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('webhook_enabled', '0')");
            $this->pdo->exec("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES ('system_version', '1.3.13')");
            $this->pdo->exec("UPDATE settings SET setting_value = '1.3.13' WHERE setting_key = 'system_version'");

            $execSilent("CREATE TABLE IF NOT EXISTS essay_results (
                id INT AUTO_INCREMENT PRIMARY KEY,
                student_name VARCHAR(100) NOT NULL,
                student_id INT DEFAULT NULL,
                exam_id INT DEFAULT NULL,
                score_percentage FLOAT NOT NULL DEFAULT 0,
                grade VARCHAR(50) NOT NULL DEFAULT 'Pending Grading',
                time_taken_seconds INT NOT NULL DEFAULT 0,
                gps_location VARCHAR(255) DEFAULT NULL,
                cheat_flag VARCHAR(255) DEFAULT NULL,
                answers_json TEXT DEFAULT NULL,
                is_graded TINYINT(1) DEFAULT 0,
                teacher_feedback TEXT DEFAULT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE SET NULL,
                FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL
            )");

            $execSilent("CREATE TABLE IF NOT EXISTS student_responses (
                id INT AUTO_INCREMENT PRIMARY KEY,
                result_id INT DEFAULT NULL,
                exam_id INT DEFAULT NULL,
                question_id INT NOT NULL,
                selected_option_index INT DEFAULT NULL,
                is_correct TINYINT(1) DEFAULT 0,
                time_taken_seconds INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_result (result_id),
                INDEX idx_exam_req (exam_id),
                INDEX idx_question_resp (question_id)
            )");

            // Apply Structural Indexes for High-Scale Performance
            $execSilent("CREATE INDEX idx_student_results ON results(student_id)");
            $execSilent("CREATE INDEX idx_exam_results ON results(exam_id)");
            $execSilent("CREATE INDEX idx_exam_questions ON questions(exam_id)");
            $execSilent("CREATE INDEX idx_cat_questions ON questions(category_id)");
            $execSilent("CREATE INDEX idx_student_sessions ON active_sessions(student_name)");
            $execSilent("CREATE INDEX idx_exam_sessions ON active_sessions(exam_id)");

            return ["status" => "success", "message" => "Database schema updated successfully."];
        } catch (\Throwable $e) {
            error_log(date('[Y-m-d H:i:s]') . " MIGRATOR FATAL: " . $e->getMessage() . " on line " . $e->getLine() . "\n", 3, __DIR__ . '/../../logs/error.log');
            return ["status" => "error", "error" => "Database Setup failed: " . $e->getMessage()];
        }
    }
}
