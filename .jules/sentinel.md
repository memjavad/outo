
## 2024-04-21 - [Zip File Path Traversal Vulnerability]
**Vulnerability:** Directly calling `$zip->extractTo()` without validating the contents of the ZIP archive allows an attacker to exploit Path Traversal/Arbitrary File Write by uploading a maliciously crafted ZIP with `../` or `/` prefixed entries, potentially overwriting critical system files outside the target directory.
**Learning:** Never trust the file paths inside uploaded zip files.
**Prevention:** Always loop over the contents of a ZIP file using `$zip->getNameIndex($i)` and validate that the paths do not contain directory traversal sequences (`../`, `..\`) or absolute paths (`/`, `\`) before attempting extraction.
