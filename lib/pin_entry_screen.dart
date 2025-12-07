// lib/pin_entry_screen.dart
import 'package:flutter/material.dart';
import 'security_helper.dart';
import 'forgot_pin_screen.dart';

class PinEntryScreen extends StatefulWidget {
  final bool isSetup;
  final String? title;

  const PinEntryScreen({super.key, this.isSetup = false, this.title});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String pin = '';
  String confirmPin = '';
  bool isConfirming = false;
  bool hasError = false;
  String errorMessage = '';

  void _addDigit(String digit) {
    setState(() {
      hasError = false;
      if (widget.isSetup) {
        if (!isConfirming) {
          if (pin.length < 6) {
            pin += digit;
            if (pin.length == 6) {
              // Move to confirmation
              isConfirming = true;
            }
          }
        } else {
          if (confirmPin.length < 6) {
            confirmPin += digit;
            if (confirmPin.length == 6) {
              _verifySetup();
            }
          }
        }
      } else {
        if (pin.length < 6) {
          pin += digit;
          if (pin.length == 6) {
            _verifyPin();
          }
        }
      }
    });
  }

  void _removeDigit() {
    setState(() {
      hasError = false;
      if (widget.isSetup) {
        if (isConfirming && confirmPin.isNotEmpty) {
          confirmPin = confirmPin.substring(0, confirmPin.length - 1);
        } else if (!isConfirming && pin.isNotEmpty) {
          pin = pin.substring(0, pin.length - 1);
        }
      } else {
        if (pin.isNotEmpty) {
          pin = pin.substring(0, pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyPin() async {
    final isValid = await SecurityHelper.verifyPin(pin);
    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        hasError = true;
        errorMessage = 'PIN salah!';
        pin = '';
      });
    }
  }

  Future<void> _verifySetup() async {
    if (pin == confirmPin) {
      await SecurityHelper.savePin(pin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        hasError = true;
        errorMessage = 'PIN tidak cocok!';
        confirmPin = '';
        isConfirming = false;
        pin = '';
      });
    }
  }

  void _resetSetup() {
    setState(() {
      pin = '';
      confirmPin = '';
      isConfirming = false;
      hasError = false;
    });
  }

  void _openForgotPin() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPinScreen()));
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayPin = widget.isSetup
        ? (isConfirming ? confirmPin : pin)
        : pin;

    String title =
        widget.title ??
        (widget.isSetup
            ? (isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Baru')
            : 'Masukkan PIN');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1976D2), Color(0xFF2196F3), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33FFFFFF),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PIN 6 Angka',
                style: TextStyle(
                  color: const Color(0xCCFFFFFF),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < displayPin.length
                          ? Colors.white
                          : const Color(0x4DFFFFFF),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (widget.isSetup && isConfirming) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resetSetup,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              if (!widget.isSetup) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _openForgotPin,
                  child: const Text(
                    'Lupa PIN?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              const SizedBox(height: 60),
              // Number pad
              _buildNumberPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumberRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumberRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildNumberRow(['', '0', 'DEL']),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((value) {
        if (value.isEmpty) {
          return const SizedBox(width: 70, height: 70);
        }
        if (value == 'DEL') {
          return InkWell(
            onTap: _removeDigit,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x33FFFFFF),
              ),
              child: const Icon(Icons.backspace_outlined, color: Colors.white),
            ),
          );
        }
        return InkWell(
          onTap: () => _addDigit(value),
          borderRadius: BorderRadius.circular(35),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33FFFFFF),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
