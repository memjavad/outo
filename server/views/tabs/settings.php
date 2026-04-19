    <div id="settings" class="tab-pane">
        <form id="settings-form">
            <input type="hidden" name="csrf_token" value="<?= $csrfToken ?>">
            <div class="grid" style="grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));">
                <!-- Section: Identity & Time -->
                <div class="card">
                    <h2 class="card-title"><i class="fas fa-palette"></i> Identity & Time</h2>
                    <div class="form-group">
                        <label>
                            App Title
                            <i class="fas fa-circle-question help-icon" data-tooltip="The name of the application displayed on students' mobile devices."></i>
                        </label>
                        <input type="text" name="app_title" value="<?= htmlspecialchars($appTitle) ?>">
                    </div>
                    <div class="form-group">
                        <label>
                            Primary Color
                            <i class="fas fa-circle-question help-icon" data-tooltip="The main theme color used for buttons and highlights in the Flutter app."></i>
                        </label>
                        <input type="color" name="primary_color" value="<?= htmlspecialchars($primaryColor) ?>" style="height:45px;">
                    </div>
                    <div class="form-group">
                        <label>
                            Flex Color Scheme
                            <i class="fas fa-circle-question help-icon" data-tooltip="The global premium app theme applied to all mobile devices dynamically."></i>
                        </label>
                        <select name="flex_color_scheme" class="form-control" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border);">
                            <option value="blueWhale" <?= $flexColorScheme === 'blueWhale' ? 'selected' : '' ?>>Blue Whale</option>
                            <option value="indigo" <?= $flexColorScheme === 'indigo' ? 'selected' : '' ?>>Indigo Nights</option>
                            <option value="sakura" <?= $flexColorScheme === 'sakura' ? 'selected' : '' ?>>Japanese Sakura</option>
                            <option value="hippieBlue" <?= $flexColorScheme === 'hippieBlue' ? 'selected' : '' ?>>Hippie Blue</option>
                            <option value="brandBlue" <?= $flexColorScheme === 'brandBlue' ? 'selected' : '' ?>>Brand Blue</option>
                            <option value="money" <?= $flexColorScheme === 'money' ? 'selected' : '' ?>>Money Green</option>
                            <option value="ebonyClay" <?= $flexColorScheme === 'ebonyClay' ? 'selected' : '' ?>>Ebony Clay</option>
                            <option value="damask" <?= $flexColorScheme === 'damask' ? 'selected' : '' ?>>Damask Red</option>
                        </select>
                    </div>
                    <div class="form-grid" style="grid-template-columns:1fr 1fr;">
                        <div class="form-group">
                            <label>
                                Exam Timer (m)
                                <i class="fas fa-circle-question help-icon" data-tooltip="Total time limit (in minutes) for the entire exam session."></i>
                            </label>
                            <input type="number" name="exam_timer" value="<?= htmlspecialchars($examTimer) ?>">
                        </div>
                        <div class="form-group">
                            <label>
                                Question Timer (s)
                                <i class="fas fa-circle-question help-icon" data-tooltip="Optional time limit (in seconds) for each individual question. Set to 0 to disable."></i>
                            </label>
                            <input type="number" name="question_timer" value="<?= htmlspecialchars($questionTimer) ?>">
                        </div>
                    </div>
                </div>

                <!-- Section: Telegram Integration -->
                <div class="card">
                    <h2 class="card-title"><i class="fab fa-telegram"></i> Telegram Integration</h2>
                    <div class="form-group">
                        <label>
                            Telegram Bot Username
                            <i class="fas fa-circle-question help-icon" data-tooltip="The @username of your Telegram bot, used for the secure login flow."></i>
                        </label>
                        <input type="text" name="tg_bot_username" value="<?= htmlspecialchars($tgBotUsername) ?>" placeholder="e.g. MyQuizBot">
                    </div>
                    <div class="form-group">
                        <label>
                            Telegram Bot Token
                            <i class="fas fa-circle-question help-icon" data-tooltip="The API token provided by @BotFather for your Telegram bot."></i>
                        </label>
                        <input type="password" name="tg_bot_token" value="<?= htmlspecialchars($tgBotToken) ?>" placeholder="123456789:ABCDefgh...">
                        <small style="color:var(--text-muted); font-size:0.7rem;">Get this from <a href="https://t.me/BotFather" target="_blank">@BotFather</a></small>
                    </div>
                </div>

                <!-- Section: Automated AI Grading -->
                <div class="card">
                    <h2 class="card-title"><i class="fas fa-robot"></i> Automated AI Grading</h2>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 15px;">
                        Configure the global generative AI model responsible for asynchronously evaluating Essay assignments behind the scenes.
                    </p>
                    <div class="form-group">
                        <label>
                            Google AI Studio (Gemini) API Key
                            <i class="fas fa-circle-question help-icon" data-tooltip="The secure API token unlocking deep generative grading networks natively."></i>
                        </label>
                        <div style="display:flex; gap: 10px;">
                            <input type="password" name="ai_api_key" value="<?= htmlspecialchars($aiApiKey) ?>" placeholder="AIzaSyA..." style="flex:1;">
                            <button type="button" class="btn btn-secondary" onclick="testAiConnection()"><i class="fas fa-plug"></i> Test</button>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>
                            Generative Evaluation Model
                            <i class="fas fa-circle-question help-icon" data-tooltip="Select the primary neural network explicitly tasked with executing the teacher rubrics safely."></i>
                        </label>
                        <select name="ai_model" class="form-control" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border);">
                            <optgroup label="Gemini Core Models (Recommended)">
                                <option value="gemini-3.1-pro-preview" <?= $aiModel === 'gemini-3.1-pro-preview' ? 'selected' : '' ?>>Gemini 3.1 Pro Preview</option>
                                <option value="gemini-3.1-flash-lite-preview" <?= $aiModel === 'gemini-3.1-flash-lite-preview' ? 'selected' : '' ?>>Gemini 3.1 Flash Lite Preview</option>
                                <option value="gemini-3-pro-preview" <?= $aiModel === 'gemini-3-pro-preview' ? 'selected' : '' ?>>Gemini 3 Pro Preview</option>
                                <option value="gemini-3-flash-preview" <?= $aiModel === 'gemini-3-flash-preview' ? 'selected' : '' ?>>Gemini 3 Flash Preview</option>
                                <option value="gemini-2.5-pro" <?= $aiModel === 'gemini-2.5-pro' ? 'selected' : '' ?>>Gemini 2.5 Pro</option>
                                <option value="gemini-2.5-flash" <?= $aiModel === 'gemini-2.5-flash' ? 'selected' : '' ?>>Gemini 2.5 Flash</option>
                                <option value="gemini-2.5-flash-lite" <?= $aiModel === 'gemini-2.5-flash-lite' ? 'selected' : '' ?>>Gemini 2.5 Flash-Lite</option>
                                <option value="gemini-2.0-flash" <?= $aiModel === 'gemini-2.0-flash' ? 'selected' : '' ?>>Gemini 2.0 Flash</option>
                                <option value="gemini-2.0-flash-lite" <?= $aiModel === 'gemini-2.0-flash-lite' ? 'selected' : '' ?>>Gemini 2.0 Flash-Lite</option>
                            </optgroup>
                            
                            <optgroup label="Latest Auto-Updating Endpoints">
                                <option value="gemini-pro-latest" <?= $aiModel === 'gemini-pro-latest' ? 'selected' : '' ?>>Gemini Pro Latest</option>
                                <option value="gemini-flash-latest" <?= $aiModel === 'gemini-flash-latest' ? 'selected' : '' ?>>Gemini Flash Latest</option>
                                <option value="gemini-flash-lite-latest" <?= $aiModel === 'gemini-flash-lite-latest' ? 'selected' : '' ?>>Gemini Flash-Lite Latest</option>
                            </optgroup>

                            <optgroup label="Gemma Open Models">
                                <option value="gemma-3-27b-it" <?= $aiModel === 'gemma-3-27b-it' ? 'selected' : '' ?>>Gemma 3 27B</option>
                                <option value="gemma-3-12b-it" <?= $aiModel === 'gemma-3-12b-it' ? 'selected' : '' ?>>Gemma 3 12B</option>
                                <option value="gemma-3-4b-it" <?= $aiModel === 'gemma-3-4b-it' ? 'selected' : '' ?>>Gemma 3 4B</option>
                                <option value="gemma-3-1b-it" <?= $aiModel === 'gemma-3-1b-it' ? 'selected' : '' ?>>Gemma 3 1B</option>
                                <option value="gemma-3n-e4b-it" <?= $aiModel === 'gemma-3n-e4b-it' ? 'selected' : '' ?>>Gemma 3n E4B</option>
                                <option value="gemma-3n-e2b-it" <?= $aiModel === 'gemma-3n-e2b-it' ? 'selected' : '' ?>>Gemma 3n E2B</option>
                            </optgroup>

                            <optgroup label="Experimental & Specialized">
                                <option value="gemini-2.5-flash-exp" <?= $aiModel === 'gemini-2.5-flash-exp' ? 'selected' : '' ?>>Gemini 2.5 Flash Experimental</option>
                                <option value="deep-research-pro-preview-12-2025" <?= $aiModel === 'deep-research-pro-preview-12-2025' ? 'selected' : '' ?>>Deep Research Pro Preview</option>
                                <option value="gemini-robotics-er-1.5-preview" <?= $aiModel === 'gemini-robotics-er-1.5-preview' ? 'selected' : '' ?>>Gemini Robotics-ER 1.5 Preview</option>
                                <option value="gemini-2.5-computer-use-preview-10-2025" <?= $aiModel === 'gemini-2.5-computer-use-preview-10-2025' ? 'selected' : '' ?>>Gemini 2.5 Computer Use Preview</option>
                            </optgroup>
                        </select>
                    </div>
                </div>

                <!-- Section: System Update -->
                <div class="card" id="update-card">
                    <h2 class="card-title"><i class="fas fa-cloud-arrow-up"></i> System Update</h2>
                    <p style="font-size:0.85rem; color:var(--text-muted); margin-bottom:15px;">
                        Current Version: <strong style="color:var(--primary-color);"><?= htmlspecialchars($systemVersion) ?></strong>
                    </p>
                    <div class="form-group">
                        <label>
                            Upload Update ZIP
                            <i class="fas fa-circle-question help-icon" data-tooltip="Upload a .zip file containing the new version of the dashboard and plugin files."></i>
                        </label>
                        <input type="file" id="update-zip-file" accept=".zip" style="width:100%; border:1px dashed var(--border-color); padding:10px; border-radius:8px;">
                    </div>
                    <div class="form-group">
                        <label>
                            New Version Number
                            <i class="fas fa-circle-question help-icon" data-tooltip="Enter the version number of the update (e.g., 1.4.0) to update the system footer."></i>
                        </label>
                        <input type="text" id="new-version-number" placeholder="e.g. 1.4.0">
                    </div>
                    <button type="button" class="btn btn-primary" onclick="performSystemUpdate()" style="width:100%;">Install Update</button>
                </div>

                <!-- Section: System Maintenance -->
                <div class="card">
                    <h2 class="card-title"><i class="fas fa-database"></i> System Maintenance</h2>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 15px;">
                        If you encounter SQL errors adding students or the platform behaves unexpectedly after an update, click this button to explicitly force a database schema upgrade.
                    </p>
                    <button type="button" class="btn btn-primary" onclick="fixDatabaseSchema()" style="width:100%;"><i class="fas fa-wrench"></i> Run Auto Database Update / Fix Schema</button>
                    <div id="db-fix-message" style="margin-top: 15px; font-size: 0.85rem; display: none;"></div>
                </div>
            </div>
            <div style="margin-top: 20px; text-align: right;">
                <button type="submit" class="btn btn-primary" style="padding: 12px 40px; font-weight: bold;"><i class="fas fa-save"></i> Save All Settings</button>
            </div>
        </form>
    </div>

<script>
async function testAiConnection() {
    const apiKey = document.querySelector('input[name="ai_api_key"]').value;
    const model = document.querySelector('select[name="ai_model"]').value;
    
    if (!apiKey) {
        showToast('Please enter an API Key first', 'error');
        return;
    }
    
    showToast('Testing AI connection...', 'info');
    
    try {
        const res = await fetch('api.php?action=test_ai_connection', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ ai_api_key: apiKey, ai_model: model })
        });
        const data = await res.json();
        
        if (data.status === 'success') {
            showToast('AI Connection Successful!', 'success');
        } else {
            showToast('Connection failed: ' + (data.error || 'Invalid API Key'), 'error');
        }
    } catch(err) {
        showToast('Network error while testing AI', 'error');
    }
}
</script>
