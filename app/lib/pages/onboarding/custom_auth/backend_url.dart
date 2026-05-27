import 'package:flutter/material.dart';

import 'package:omi/backend/preferences.dart';
import 'package:omi/env/env.dart';
import 'package:omi/utils/l10n_extensions.dart';

/// Developer-mode form to point the app at a custom backend (e.g. our
/// atwenture-fork stub). Persists the URL in SharedPreferences and applies
/// it as a runtime override via [Env.overrideApiBaseUrl] immediately.
///
/// The persisted URL is re-applied on every cold start by `main.dart` BEFORE
/// any HTTP call — see the "custom backend URL" block in `main()`.
class CustomBackendURLForm extends StatefulWidget {
  const CustomBackendURLForm({super.key});

  @override
  State<StatefulWidget> createState() => _CustomBackendURLFormState();
}

class _CustomBackendURLFormState extends State<CustomBackendURLForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    // Prefill with currently persisted override (empty if none) so the user
    // can edit-in-place instead of retyping. Falls back to the compile-time
    // default to make discovery easier.
    final stored = SharedPreferencesUtil().customBackendUrl;
    _urlController = TextEditingController(
      text: stored.isNotEmpty ? stored : (Env.apiBaseUrl ?? ''),
    );
  }

  // Function to validate the URL
  String? _validateURL(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return context.l10n.enterBackendUrlError;
    }

    // Check if the URL ends with '/'
    if (!value.endsWith('/')) {
      return context.l10n.urlMustEndWithSlashError;
    }

    // Use Uri.tryParse to validate the URL format
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAbsolutePath || uri.scheme.isEmpty) {
      return context.l10n.invalidUrlError;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return context.l10n.invalidUrlError;
    }

    return null;
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final backendURL = _urlController.text.trim();

    // 1. Persist for next cold start.
    SharedPreferencesUtil().customBackendUrl = backendURL;

    // 2. Apply immediately so any subsequent in-session HTTP call hits the
    //    new backend without needing to restart the app.
    Env.overrideApiBaseUrl(backendURL);

    debugPrint('[CustomBackendURLForm] Custom backend URL saved + applied: $backendURL');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.backendUrlSavedSuccess)));
  }

  void _clearOverride() {
    SharedPreferencesUtil().customBackendUrl = '';
    _urlController.text = '';
    // Note: Env.overrideApiBaseUrl has no "clear" — but on next cold start,
    // the absence of a stored value means no override is applied, and the
    // compile-time default wins again.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom backend URL cleared. Restart app for full effect.')),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For consistent styling, you can reuse the theme from the previous form
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Add gradient background
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.customBackendUrlTitle,
                        style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.blueAccent[700]),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: context.l10n.backendUrlLabel,
                          prefixIcon: const Icon(Icons.link),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        validator: (value) => _validateURL(value, context),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            backgroundColor: Colors.blueAccent[700],
                          ),
                          child: Text(context.l10n.saveUrlButton, style: const TextStyle(fontSize: 18.0)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearOverride,
                        child: const Text('Clear override (use default)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
