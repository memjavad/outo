
## 2024-11-23 - Insecure File Upload / RCE vulnerability
**Vulnerability:** ExamController::uploadImage() blindly trusted the client-provided file extension without validating the actual file content, allowing executable `.php` files to be uploaded.
**Learning:** Using `pathinfo($file->getClientFilename(), PATHINFO_EXTENSION)` without MIME type validation on the actual content creates a critical RCE vulnerability via malicious file uploads.
**Prevention:** Always extract and validate the file's MIME type from the content stream using `finfo_buffer()` and strictly map it to a safe extension using an allowlist, ignoring the client-provided extension completely.
