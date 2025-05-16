import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Mapeamento de nomes para e-mails
  final Map<String, String> userEmails = {
    '-- Selecione --': 'adm@email.com',
    'Bernardo': 'bernardo@email.com',
    'Cristiano': 'cristiano@email.com',
    'Duth': 'duth@email.com',
    'Gustavo': 'gustavo@email.com',
    'Jenifer': 'jenifer@email.com',
    'Marcio': 'marcio@email.com',
    'Monique': 'monique@email.com',
    'Rodolfo': 'rodolfo@email.com',
    'Veronica': 'veronica@email.com',
    'Vinicius': 'vinicius@email.com',
    'Sabrina': 'sabrina@email.com',
    'Savio': 'savio@email.com',
    'Wagner': 'wagner@email.com',
    'Ygor': 'ygor@gmail.com'
  };

  String selectedName = '-- Selecione --'; // Nome inicialmente selecionado
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final email = userEmails[selectedName]!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Senha'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'Bem-vindo de volta!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Dropdown de nomes
                DropdownButtonFormField<String>(
                  value: selectedName,
                  decoration: const InputDecoration(labelText: 'Usuário'),
                  items: userEmails.keys.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedName = value);
                    }
                  },
                ),

                const SizedBox(height: 16),
                _buildPasswordInput(),

                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          icon: const Icon(Icons.login),
                          onPressed: _login,
                          label: const Text('Entrar'),
                        ),
                ),

                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
