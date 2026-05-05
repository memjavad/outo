## 2024-05-15 - Missing Tooltips on IconButtons
**Learning:** IconButtons lacking textual labels should implement the tooltip property to provide visual help text and act as semantic labels for screen readers. In Flutter apps with l10n, these tooltips should also be localized properly using AppLocalizations.
**Action:** Always check IconButtons for tooltip properties and ensure that the tooltips are properly localized using the l10n object or AppLocalizations.of(context).
