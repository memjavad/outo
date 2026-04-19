        <script>
            // Tab Switching Logic with URL hash persistence
            function switchToTab(tabId) {
                document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
                
                const link = document.querySelector('[data-tab="' + tabId + '"]');
                if (link) {
                    link.classList.add('active');
                    document.getElementById(tabId).classList.add('active');
                    document.getElementById('page-title').innerText = link.innerText.trim();
                    location.hash = tabId;
                }
            }

            document.querySelectorAll('.nav-link').forEach(link => {
                link.addEventListener('click', (e) => {
                    e.preventDefault();
                    const tabId = link.getAttribute('data-tab');
                    switchToTab(tabId);
                });
            });

            // Restore active tab from URL hash on page load
            const hash = location.hash.replace('#', '');
            if (hash && document.getElementById(hash)) {
                switchToTab(hash);
            }
        </script>
</body>
</html>
