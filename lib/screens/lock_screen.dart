import 'package:flutter/material.dart';
import 'package:pass_keeper/services/auth_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authInProgress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _tryAuth();
        });
      }
    });
  }

  Future<void> _tryAuth() async {
    if (_authInProgress) return;
    setState(() {
      _authInProgress = true;
      _error = null;
    });

    final ok = await AuthService.instance.authenticate();
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      setState(() {
        _error = 'Authentication failed or was canceled.';
        _authInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 19, 19, 19),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'Locked',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Authenticate with biometrics or device PIN to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _authInProgress ? null : _tryAuth,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(
                      _authInProgress ? 'Authenticating...' : 'Unlock',
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
}
