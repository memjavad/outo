<?php
// Get translation and language
$isRtl = ($lang == 'ar');
?>
<!DOCTYPE html>
<html lang="<?= $lang ?>" dir="<?= $isRtl ? 'rtl' : 'ltr' ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $t[$lang]['dashboard'] ?> | Premium Admin</title>
    <!-- Premium Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <?php if (!$isLoggedIn && empty($forcePasswordChange)): ?>
        <script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
        <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet"/>
        <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet"/>
        <script>
            tailwind.config = {
                darkMode: "class",
                theme: {
                    extend: {
                        colors: {
                            "inverse-surface": "#2e3132", "surface-container": "#eceeef", "surface-container-low": "#f2f4f5", "on-tertiary-fixed": "#0a1e26", "secondary-fixed-dim": "#92ccff", "error": "#ba1a1a", "on-primary": "#ffffff", "background": "#f8fafb", "on-background": "#191c1d", "on-secondary-container": "#00476e", "surface-bright": "#f8fafb", "surface-container-lowest": "#ffffff", "tertiary-fixed-dim": "#b6c9d5", "outline": "#72787e", "on-primary-container": "#759cbb", "inverse-primary": "#a4cbec", "outline-variant": "#c2c7ce", "on-surface": "#191c1d", "on-secondary-fixed-variant": "#004b73", "surface-container-highest": "#e1e3e4", "primary-fixed": "#cae6ff", "surface": "#f8fafb", "tertiary-fixed": "#d1e6f1", "surface-container-high": "#e6e8e9", "on-primary-fixed": "#001e30", "secondary": "#006497", "on-tertiary": "#ffffff", "on-error": "#ffffff", "surface-dim": "#d8dadb", "secondary-fixed": "#cce5ff", "primary": "#001d2f", "on-surface-variant": "#42474d", "on-tertiary-container": "#879aa5", "surface-variant": "#e1e3e4", "tertiary": "#091d25", "on-secondary": "#ffffff", "primary-fixed-dim": "#a4cbec", "on-primary-fixed-variant": "#214a66", "surface-tint": "#3b627f", "error-container": "#ffdad6", "secondary-container": "#58b8ff", "primary-container": "#00334e", "inverse-on-surface": "#eff1f2", "on-error-container": "#93000a", "on-secondary-fixed": "#001d31", "tertiary-container": "#20323b", "on-tertiary-fixed-variant": "#374953"
                        },
                        fontFamily: { "headline": ["Manrope"], "body": ["Inter"], "label": ["Inter"] },
                        borderRadius: { "DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "2xl": "1rem", "3xl": "1.5rem", "full": "9999px" },
                    },
                },
            }
        </script>
        <style>
            .material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
            .bg-primary-gradient { background: linear-gradient(135deg, #001d2f 0%, #00334e 100%); }
            .glass-nav { background-color: rgba(248, 250, 251, 0.8); backdrop-filter: blur(20px); }
            body { min-height: max(884px, 100dvh); }
        </style>
    <?php endif; ?>
</head>
<body class="<?= $isLoggedIn ? 'has-sidebar' : '' ?>">
    <?php if (!$isLoggedIn): ?>
        <!-- STUDENT LOGIN VIEW (Tailwind styled) -->
        <div class="bg-background text-on-background font-body min-h-screen flex flex-col items-center justify-center p-6 w-full absolute top-0 left-0" id="student-login-view" style="display: none; z-index: 100;">
            <!-- Hero Content & Branding -->
            <header class="w-full max-w-md text-center mb-10">
                <div class="flex justify-center mb-8">
                    <div class="w-24 h-24 rounded-full bg-surface-container-highest flex items-center justify-center shadow-[0_20px_40px_rgba(0,29,47,0.08)] relative">
                        <div class="absolute inset-0 rounded-full border border-white/40"></div>
                        <span class="material-symbols-outlined text-primary text-5xl" style="font-variation-settings: 'FILL' 1;">school</span>
                    </div>
                </div>
                <h1 class="font-headline text-[1.75rem] font-bold text-primary mb-3 tracking-tight">مرحباً بك في اختبار الطلاب</h1>
                <p class="font-body text-on-surface-variant text-sm px-8 leading-relaxed">
                    اختبر معلوماتك واحصل على تقييم فوري!
                </p>
            </header>

            <!-- Main Login Card -->
            <main class="w-full max-w-md relative z-10">
                <div class="bg-surface-container-lowest rounded-3xl p-8 shadow-[0_4px_30px_rgba(0,29,47,0.04)] space-y-6">
                    <form id="student-web-form">
                        <!-- Phone Input Section -->
                        <div class="space-y-2 mb-4">
                            <label class="block text-xs font-semibold text-primary mr-2 uppercase tracking-wider text-right">رقم الهاتف</label>
                            <div class="relative group">
                                <div class="absolute inset-y-0 right-4 flex items-center pointer-events-none text-on-surface-variant">
                                    <span class="material-symbols-outlined text-[20px]">phone_iphone</span>
                                </div>
                                <input class="w-full bg-surface-container-highest border-0 rounded-xl py-4 pr-12 pl-4 text-on-surface placeholder:text-on-surface-variant/60 focus:ring-2 focus:ring-secondary/40 transition-all font-headline font-semibold text-left" dir="ltr" id="student_phone" name="phone" placeholder="05xxxxxxxx" required type="tel"/>
                            </div>
                        </div>

                        <!-- Password Input Section -->
                        <div class="space-y-2 mb-4">
                            <div class="flex justify-between items-center px-2">
                                <label class="text-xs font-semibold text-primary uppercase tracking-wider text-right w-full">كلمة المرور</label>
                            </div>
                            <div class="relative group">
                                <div class="absolute inset-y-0 right-4 flex items-center pointer-events-none text-on-surface-variant">
                                    <span class="material-symbols-outlined text-[20px]">lock_open</span>
                                </div>
                                <input class="w-full bg-surface-container-highest border-0 rounded-xl py-4 pr-12 pl-4 text-on-surface placeholder:text-on-surface-variant/60 focus:ring-2 focus:ring-secondary/40 transition-all font-headline font-semibold text-left" dir="ltr" id="student_password" name="password" placeholder="••••••••" required type="password"/>
                            </div>
                        </div>

                        <div id="student-error" class="hidden mb-4 p-3 rounded-xl bg-error-container text-on-error-container text-sm font-semibold text-center mt-2"></div>

                        <!-- Login Actions -->
                        <div class="pt-2 space-y-4">
                            <!-- Primary Button -->
                            <button class="w-full bg-primary-gradient text-on-primary py-4 rounded-3xl font-headline font-bold text-lg shadow-[0_10px_25px_rgba(0,29,47,0.2)] active:scale-95 transition-all duration-150" id="student-login-btn" type="submit">
                                دخول
                            </button>

                            <!-- Divider -->
                            <div class="flex items-center gap-4 py-2">
                                <div class="h-[1px] flex-1 bg-surface-container-high"></div>
                                <span class="text-[10px] font-bold text-on-surface-variant/50 uppercase tracking-widest">أو عبر</span>
                                <div class="h-[1px] flex-1 bg-surface-container-high"></div>
                            </div>

                            <!-- Telegram Button -->
                            <button class="w-full bg-secondary text-on-secondary py-4 rounded-3xl font-headline font-semibold flex items-center justify-center gap-3 active:scale-95 transition-all duration-150" onclick="studentTelegramLogin()" type="button">
                                <span class="material-symbols-outlined text-[22px]" style="font-variation-settings: 'FILL' 1;">send</span>
                                تسجيل الدخول عبر تيليجرام
                            </button>
                        </div>
                    </form>
                </div>

                <!-- Footer Links -->
                <footer class="mt-8 space-y-6 text-center">
                    <a class="block text-primary font-bold text-sm hover:opacity-70 transition-opacity" href="#" onclick="alert('لإنشاء حساب يرجى التواصل مع الإدارة.'); return false;">
                        ليس لديك حساب؟ تسجيل جديد
                    </a>
                    <div class="pt-4 border-t border-surface-container-high">
                        <a class="inline-flex items-center gap-2 text-on-surface-variant font-semibold text-xs py-2 px-6 rounded-full bg-surface-container-low hover:bg-surface-container-high transition-colors" href="#" onclick="document.getElementById('student-login-view').style.display='none'; document.getElementById('admin-login-view').style.display='flex'; return false;" style="text-decoration: none;">
                            <span class="material-symbols-outlined text-[18px]">admin_panel_settings</span>
                            دخول المعلم / الإدارة
                        </a>
                    </div>
                </footer>
            </main>

            <!-- Decorative Elements (Asymmetric Floating Shapes) -->
            <div class="fixed top-[-10%] left-[-10%] w-64 h-64 bg-secondary-container/10 rounded-full blur-[80px] -z-10 absolute pointer-events-none"></div>
            <div class="fixed bottom-[-5%] right-[-5%] w-80 h-80 bg-primary-container/5 rounded-full blur-[100px] -z-10 absolute pointer-events-none"></div>
        </div>
        
        <script>
            document.getElementById('student-web-form').addEventListener('submit', async (e) => {
                e.preventDefault();
                const btn = document.getElementById('student-login-btn');
                const errBox = document.getElementById('student-error');
                const phone = document.getElementById('student_phone').value;
                const password = document.getElementById('student_password').value;
                
                errBox.classList.add('hidden');
                btn.innerHTML = '<span class="material-symbols-outlined animate-spin text-xl">progress_activity</span>';
                
                try {
                    const res = await fetch('api.php?action=student_login', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ phone, password, device_info: 'Web Portal' })
                    });
                    const data = await res.json();
                    
                    if (data.status === 'success') {
                        localStorage.setItem('student_token', data.token);
                        localStorage.setItem('student_data', JSON.stringify(data.student));
                        btn.innerHTML = 'تم الدخول بنجاح!';
                        btn.classList.add('bg-green-600', 'text-white');
                        setTimeout(() => {
                            window.location.href = 'student_portal.php'; 
                        }, 500);
                    } else {
                        throw new Error(data.error || 'فشل تسجيل الدخول');
                    }
                } catch (err) {
                    errBox.innerText = err.message;
                    errBox.classList.remove('hidden');
                    btn.innerHTML = 'دخول';
                }
            });

            function studentTelegramLogin() {
                alert('تسجيل الدخول عبر تيليجرام غير متاح مؤقتاً.');
            }
        </script>

        <!-- ADMIN LOGIN VIEW -->
        <div id="admin-login-view" style="display: flex; align-items: center; justify-content: center; width: 100%; height: 100vh; background: var(--bg-color); position: absolute; top:0; left:0; z-index: 110;">
            <button type="button" onclick="document.getElementById('admin-login-view').style.display='none'; document.getElementById('student-login-view').style.display='flex'; return false;" style="position: absolute; top: 15px; left: 15px; background: none; border: none; font-size: 1.1rem; cursor: pointer; color: var(--text-muted); padding: 10px; display: flex; align-items: center; gap: 8px;"><i class="fas fa-arrow-left"></i> Go to Student Login</button>
            <div class="card" style="max-width: 400px; width: 90%; text-align: center;">
                <div class="logo" style="justify-content: center; margin-bottom: 30px;">
                    <div class="logo-icon"><i class="fas fa-shield-halved"></i></div>
                    <div class="logo-text">Auto Platform</div>
                </div>
                
                <?php if ($noAdmins): ?>
                    <h2 style="font-size: 1.2rem; font-weight: 800; color: var(--primary-color); margin-bottom: 10px;">Setup Admin Account</h2>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 25px;">No administrators found. Create the first one to begin.</p>
                <?php endif; ?>

                <?php 
                $errorMsg = isset($_SESSION['login_error']) ? $_SESSION['login_error'] : (isset($error) ? $error : null);
                if ($errorMsg): 
                    unset($_SESSION['login_error']);
                ?>
                    <div class="error" style="color: #E53E3E; background: #FFF5F5; padding: 12px; border-radius: 12px; margin-bottom: 20px; font-size: 0.9rem;">
                        <i class="fas fa-circle-exclamation"></i> <?= $errorMsg ?>
                    </div>
                <?php endif; ?>

                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?= $csrfToken ?>">
                    <div class="form-group" style="text-align: left;">
                        <label><?= $t[$lang]['username'] ?></label>
                        <input type="text" name="username" placeholder="Username" required>
                    </div>
                    <div class="form-group" style="text-align: left;">
                        <label><?= $t[$lang]['password'] ?></label>
                        <input type="password" name="password" placeholder="<?= $noAdmins ? 'Min. 6 characters' : '••••••••' ?>" required minlength="<?= $noAdmins ? '6' : '1' ?>">
                    </div>
                    
                    <?php if ($noAdmins): ?>
                        <button type="submit" name="register_admin" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                            Create & Login <i class="fas fa-user-plus"></i>
                        </button>
                    <?php else: ?>
                        <button type="submit" name="login" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                            <?= $t[$lang]['login_btn'] ?> <i class="fas fa-right-to-bracket"></i>
                        </button>
                    <?php endif; ?>

                    <div style="margin-top: 30px; font-size: 0.85rem; color: var(--text-muted);">
                        <a href="?lang=en" style="text-decoration: none; color: inherit;">EN</a> • 
                        <a href="?lang=ar" style="text-decoration: none; color: inherit;">العربية</a>
                    </div>
                </form>
            </div>
        </div>
    <?php elseif ($forcePasswordChange): ?>
        <!-- Force Password Change Screen -->
        <div style="display: flex; align-items: center; justify-content: center; width: 100%; height: 100vh; background: var(--bg-color);">
            <div class="card" style="max-width: 420px; width: 90%;">
                <div class="logo" style="justify-content: center; margin-bottom: 25px;">
                    <div class="logo-icon" style="background: linear-gradient(135deg, #f59e0b, #fbbf24);"><i class="fas fa-key"></i></div>
                    <div class="logo-text" style="color: #d97706;"><?= $t[$lang]['change_password'] ?></div>
                </div>
                <p style="text-align: center; color: var(--text-muted); margin-bottom: 25px; font-size: 0.9rem;">
                    For security reasons, please update your default password.
                </p>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="<?= $csrfToken ?>">
                    <div class="form-group">
                        <label><?= $t[$lang]['new_password'] ?></label>
                        <input type="password" name="new_password" placeholder="Min. 6 chars" minlength="6" required>
                    </div>
                    <div class="form-group">
                        <label><?= $t[$lang]['confirm_password'] ?></label>
                        <input type="password" name="confirm_password" placeholder="Confirm" minlength="6" required>
                    </div>
                    <button type="submit" name="change_password" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                        <i class="fas fa-save"></i> <?= $t[$lang]['change_password'] ?>
                    </button>
                </form>
            </div>
        </div>
    <?php else: ?>
        <!-- Sidebar Navigation -->
        <div class="sidebar">
            <div class="logo">
                <div class="logo-icon"><i class="fas fa-graduation-cap"></i></div>
                <div class="logo-text">Auto Platform</div>
            </div>
            
            <ul class="nav-links">
                <li class="nav-item">
                    <a href="#" class="nav-link active" data-tab="analytics">
                        <i class="fas fa-chart-pie"></i> <?= $t[$lang]['analytics'] ?>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="results">
                        <i class="fas fa-list-check"></i> <?= $t[$lang]['student_results'] ?>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="students">
                        <i class="fas fa-users-gear"></i> <?= $t[$lang]['manage_students'] ?>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="standard_exams">
                        <i class="fas fa-book-open"></i> Standard Exams
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="campaign_exams">
                        <i class="fas fa-map"></i> Campaign Mode
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="essay_exams">
                        <i class="fas fa-pen-nib"></i> Essay Assignments
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="essay_submissions">
                        <i class="fas fa-file-signature"></i> Essay Submissions
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="logs">
                        <i class="fas fa-terminal"></i> System Logs
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-tab="settings">
                        <i class="fas fa-gears"></i> <?= $t[$lang]['app_appearance'] ?>
                    </a>
                </li>
            </ul>

            <div style="margin-top: auto;">
                <div style="padding: 15px; background: rgba(99, 102, 241, 0.05); border-radius: 16px; margin-bottom: 20px; font-size: 0.8rem; color: var(--text-muted); border: 1px solid rgba(99, 102, 241, 0.1);">
                    <div style="font-weight: 700; color: var(--primary-color); margin-bottom: 6px;">Language / اللغة</div>
                    <a href="?lang=en" style="color: <?= $lang=='en' ? 'var(--primary-dark)' : 'inherit' ?>; font-weight: <?= $lang=='en' ? '700' : '400' ?>; text-decoration: none;">English</a> | 
                    <a href="?lang=ar" style="color: <?= $lang=='ar' ? 'var(--primary-dark)' : 'inherit' ?>; font-weight: <?= $lang=='ar' ? '700' : '400' ?>; text-decoration: none;">العربية</a>
                </div>
                <a href="?logout=1" class="btn btn-danger" style="width: 100%;">
                    <i class="fas fa-power-off"></i> <?= $t[$lang]['logout'] ?>
                </a>
            </div>
        </div>

        <!-- Main Content Area -->
        <main class="main-content">
            <header class="header">
                <div class="header-title">
                    <h1 id="page-title"><?= $t[$lang]['analytics'] ?></h1>
                    <p style="font-weight: 600; color: var(--text-muted);"><?= date('l, F j, Y') ?> · <span style="color: var(--primary-color);">Premium Admin Access</span></p>
                </div>
                <div style="display: flex; gap: 15px; align-items: center;">
                    <button class="btn btn-primary" onclick="window.location.reload()" style="padding: 10px 14px; border-radius: 8px;">
                        <i class="fas fa-arrows-rotate"></i>
                    </button>
                    <div style="width: 36px; height: 36px; border-radius: 10px; background: var(--primary-color); color: white; display: flex; align-items: center; justify-content: center; font-weight: 800; box-shadow: 0 4px 12px rgba(99, 102, 241, 0.2);">
                        <?= strtoupper(substr($_SESSION['admin_user'] ?? 'A', 0, 1)) ?>
                    </div>
                </div>
            </header>
    <?php endif; ?>
