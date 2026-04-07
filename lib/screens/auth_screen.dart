import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/biometric_service.dart';
import '../services/secure_storage_service.dart';
import 'notes_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final BiometricService _biometricService = BiometricService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _setupPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  bool _isBiometricSupported = false;
  bool _isLoading = true;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final supported = await _biometricService.isDeviceSupported();
    final hasPin = await SecureStorageService.hasPin();
    setState(() {
      _isBiometricSupported = supported;
      _hasPin = hasPin;
      _isLoading = false;
    });
    
    if (_isBiometricSupported && _hasPin) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated && mounted) {
      await SecureStorageService.updateLastActivity();
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const NotesListScreen())
      );
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      _showSnackBar('Please enter your PIN');
      return;
    }
    
    final storedHash = await SecureStorageService.loadPinHash();
    if (storedHash == null) {
      _showSetupPinDialog();
      return;
    }
    
    final inputHash = sha256.convert(utf8.encode(_pinController.text)).toString();
    if (inputHash == storedHash) {
      await SecureStorageService.updateLastActivity();
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const NotesListScreen())
        );
      }
    } else {
      _showSnackBar('Wrong PIN. Try again.');
      _pinController.clear();
    }
  }

  void _showSetupPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set Up PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _setupPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter 4-6 digit PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _setupPinController.clear();
              _confirmPinController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_setupPinController.text.length < 4) {
                _showSnackBar('PIN must be at least 4 digits');
                return;
              }
              if (_setupPinController.text != _confirmPinController.text) {
                _showSnackBar('PINs do not match');
                return;
              }
              final hash = sha256.convert(utf8.encode(_setupPinController.text)).toString();
              await SecureStorageService.savePinHash(hash);
              _setupPinController.clear();
              _confirmPinController.clear();
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('PIN set successfully!');
                _pinController.clear();
                setState(() => _hasPin = true);
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Secure Notes',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              if (_isBiometricSupported && _hasPin) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock with Biometrics'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('OR', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _hasPin ? 'Enter PIN' : 'Set up PIN to continue',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyPin,
                  child: Text(_hasPin ? 'Unlock with PIN' : 'Set Up PIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _setupPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}