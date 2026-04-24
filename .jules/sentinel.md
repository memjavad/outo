## 2024-05-24 - Zip Slip in UpdateService
**Vulnerability:** Path traversal (Zip Slip) vulnerability due to insecure `ZipArchive::extractTo()` usage when extracting update packages.
**Learning:** Using `$zip->extractTo()` without validating the contents of the ZIP archive allows malicious archives to write files outside the intended destination (e.g., using `../` in file names), potentially leading to arbitrary file write and remote code execution.
**Prevention:** Always iterate manually over ZIP files and validate each entry name. Check for traversal patterns (`../`, `..\`) and absolute paths (leading `/`). Furthermore, extracting via `$zip->getFromIndex($i)` is safer than the `zip://` wrapper, which breaks on filenames containing `#`.
