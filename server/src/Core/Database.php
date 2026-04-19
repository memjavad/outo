<?php
namespace App\Core;

use PDO;
use PDOException;

class Database {
    private static $instance = null;
    private $connection;

    private function __construct() {
        $host = Config::get('db_host');
        $dbname = Config::get('db_name');
        $user = Config::get('db_user');
        $pass = Config::get('db_pass');

        try {
            // First connect without DB to ensure it exists
            $pdo = new PDO("mysql:host=$host;charset=utf8", $user, $pass);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $pdo->exec("CREATE DATABASE IF NOT EXISTS `$dbname` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
            
            // Now connect to the specific DB
            $this->connection = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
            $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->connection->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            
            // Auto-initialize schema
            $this->initSchema();
        } catch (PDOException $e) {
            die(json_encode(["error" => "Database connection failed: " . $e->getMessage()]));
        }
    }

    public static function getInstance() {
        if (self::$instance == null) {
            self::$instance = new self();
        }
        return self::$instance->connection;
    }

    private function initSchema() {
        $queries = [
            "CREATE TABLE IF NOT EXISTS categories (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )",
            "CREATE TABLE IF NOT EXISTS admins (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                role ENUM('admin','teacher','viewer') NOT NULL DEFAULT 'admin',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )",
            "CREATE TABLE IF NOT EXISTS exams (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT DEFAULT NULL,
                is_active TINYINT(1) DEFAULT 1,
                created_by INT DEFAULT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE SET NULL
            )",
            "CREATE TABLE IF NOT EXISTS questions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                category_id INT DEFAULT NULL,
                exam_id INT DEFAULT NULL,
                question_text TEXT NOT NULL,
                rich_text TEXT DEFAULT NULL,
                image_url VARCHAR(500) DEFAULT NULL,
                question_type ENUM('single', 'multiple', 'true_false', 'short_answer') NOT NULL DEFAULT 'single',
                correct_answer_index INT NOT NULL,
                points INT NOT NULL DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
                FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE SET NULL
            )",
            "CREATE TABLE IF NOT EXISTS options (
                id INT AUTO_INCREMENT PRIMARY KEY,
                question_id INT NOT NULL,
                option_text VARCHAR(255) NOT NULL,
                option_index INT NOT NULL,
                FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
            )",
            "CREATE TABLE IF NOT EXISTS results (
                id INT AUTO_INCREMENT PRIMARY KEY,
                exam_id INT DEFAULT NULL,
                student_name VARCHAR(100) NOT NULL,
                score_percentage FLOAT NOT NULL,
                grade VARCHAR(10) NOT NULL,
                total_questions INT NOT NULL,
                correct_answers INT NOT NULL,
                time_taken_seconds INT NOT NULL,
                gps_location VARCHAR(255) DEFAULT NULL,
                cheat_flag VARCHAR(255) DEFAULT NULL,
                answers_json TEXT DEFAULT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE SET NULL
            )",
            "CREATE TABLE IF NOT EXISTS essay_results (
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
            )",
            "CREATE TABLE IF NOT EXISTS settings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                setting_key VARCHAR(50) UNIQUE NOT NULL,
                setting_value VARCHAR(255) NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS active_sessions (
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
            )",
            "CREATE TABLE IF NOT EXISTS admin_tokens (
                id INT AUTO_INCREMENT PRIMARY KEY,
                admin_id INT NOT NULL,
                token VARCHAR(255) UNIQUE NOT NULL,
                expires_at DATETIME NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE
            )",
            "CREATE TABLE IF NOT EXISTS tg_auth_sessions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                session_id VARCHAR(255) NOT NULL UNIQUE,
                status VARCHAR(50) DEFAULT 'pending',
                auth_date BIGINT DEFAULT NULL,
                first_name VARCHAR(255) DEFAULT NULL,
                username VARCHAR(255) DEFAULT NULL,
                photo_url VARCHAR(500) DEFAULT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )",
            "CREATE TABLE IF NOT EXISTS students (
                id INT AUTO_INCREMENT PRIMARY KEY,
                access_code VARCHAR(50) UNIQUE NOT NULL,
                name VARCHAR(100) NOT NULL,
                enrolled TINYINT(1) DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )",
            "CREATE TABLE IF NOT EXISTS store_items (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                description TEXT DEFAULT NULL,
                cost_points INT NOT NULL DEFAULT 0,
                item_key VARCHAR(50) UNIQUE NOT NULL,
                icon VARCHAR(255) DEFAULT NULL,
                is_active TINYINT(1) DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )",
            "CREATE TABLE IF NOT EXISTS student_inventory (
                id INT AUTO_INCREMENT PRIMARY KEY,
                student_id INT NOT NULL,
                item_key VARCHAR(50) NOT NULL,
                quantity INT DEFAULT 0,
                FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
                UNIQUE KEY unique_student_item (student_id, item_key)
            )"
        ];

        foreach ($queries as $sql) {
            $this->connection->exec($sql);
        }

        // Auto-Migrate Hotfixes: Guarantee new gamification ledger columns exist
        try {
            $this->connection->exec("ALTER TABLE students ADD COLUMN points INT DEFAULT 0");
        } catch (PDOException $e) {}
        try {
            $this->connection->exec("ALTER TABLE students ADD COLUMN total_xp INT DEFAULT 0");
        } catch (PDOException $e) {}
        try {
            $this->connection->exec("ALTER TABLE students ADD COLUMN stars INT DEFAULT 0");
        } catch (PDOException $e) {}
        
        // Ensure Results table can hold campaign metrics
        try {
            $this->connection->exec("ALTER TABLE results ADD COLUMN earned_stars INT DEFAULT 0");
        } catch (PDOException $e) {}
        try {
            $this->connection->exec("ALTER TABLE results ADD COLUMN campaign_score INT DEFAULT 0");
        } catch (PDOException $e) {}

        // Seed default settings if empty
        $this->seedSettings();
        
        // Seed default store power-ups if empty
        $this->seedStoreItems();
    }

    private function seedStoreItems() {
        $items = [
            ['Time Freeze', 'Pauses the Burning Fuse timer for 15 seconds.', 500, 'time_freeze', '🧊'],
            ['50/50 Chop', 'Eliminates two incorrect options instantly.', 1000, 'fifty_fifty', '✂️'],
            ['Combo Shield', 'Prevents your multiplier from breaking on one wrong answer.', 1500, 'combo_shield', '🛡️']
        ];
        $stmt = $this->connection->prepare("INSERT IGNORE INTO store_items (name, description, cost_points, item_key, icon) VALUES (?, ?, ?, ?, ?)");
        foreach ($items as $item) {
            $stmt->execute($item);
        }
    }

    private function seedSettings() {
        $defaults = [
            'app_title' => 'Student Quiz',
            'primary_color' => '#673AB7',
            'exam_timer' => '10',
            'question_timer' => '0',
            'randomize_questions' => '1',
            'randomize_options' => '1',
            'strict_app_focus' => '0',
            'require_gps' => '0',
            'record_screen' => '0',
            'prevent_screenshots' => '1',
            'detect_vpn' => '0',
            'require_biometrics' => '0',
            'require_tg_login' => '0',
            'allow_review' => '1',
            'allow_backtracking' => '1',
            'require_access_code' => '0',
            'record_audio' => '0',
            'immediate_feedback' => '0'
        ];

        $stmt = $this->connection->prepare("INSERT IGNORE INTO settings (setting_key, setting_value) VALUES (?, ?)");
        foreach ($defaults as $key => $value) {
            $stmt->execute([$key, $value]);
        }
    }
}
