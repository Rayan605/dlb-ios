import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Renvoie `true` via Navigator.pop si l'inscription a réussi.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _social = TextEditingController();
  final _password = TextEditingController();
  String? _gender;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _social.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      showSnack(context, 'Sélectionne ton genre.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            gender: _gender!,
            social: _social.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INSCRIPTION')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text('REJOINS\nLA LISTE', style: AppTheme.heading(size: 34)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 14),
                _genderSelector(),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _social,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Insta ou Snap',
                    hintText: '@ton_pseudo',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ton insta ou snap est obligatoire'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    helperText: '8 caractères minimum',
                    helperStyle: const TextStyle(color: AppColors.muted),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.sub),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? '8 caractères minimum'
                      : null,
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Je veux être dans le bon →'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Déjà un compte ? ',
                        style: TextStyle(color: AppColors.sub),
                        children: [
                          TextSpan(
                            text: 'Connexion',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderSelector() {
    Widget chip(String value, String label) {
      final active = _gender == value;
      final isGirl = value == 'F';
      final color = isGirl ? AppColors.pink : AppColors.accent;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _gender = value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? color.withValues(alpha: 0.12) : AppColors.raised,
              border: Border.all(color: active ? color : AppColors.border),
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: Text(label,
                style: TextStyle(
                    color: active ? color : AppColors.sub,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GENRE', style: AppTheme.mono(size: 10.5)),
        const SizedBox(height: 8),
        Row(children: [
          chip('F', 'Femme'),
          chip('M', 'Homme'),
          chip('X', 'Autre'),
        ]),
      ],
    );
  }
}
