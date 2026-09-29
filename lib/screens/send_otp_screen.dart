import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../api_constants.dart';
import 'reset_password_screen.dart';

enum ForgotPasswordState { enterPhone, verifyOtp }

class SendOtpScreen extends StatefulWidget {
  const SendOtpScreen({super.key});

  @override
  State<SendOtpScreen> createState() => _SendOtpScreenState();
}

class _SendOtpScreenState extends State<SendOtpScreen> {
  // Common
  ForgotPasswordState _currentState = ForgotPasswordState.enterPhone;
  bool _isLoading = false;
  String? _errorMessage;

  // Phone Step
  final TextEditingController _phoneController = TextEditingController();

  // OTP Step
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  static const int _otpLength = 6;
  int _countdown = 60;
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
      setState(() {}); // update UI for box filling
      if (_otpController.text.length == _otpLength) {
        _verifyOtp();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Transition to OTP step
        setState(() {
          _currentState = ForgotPasswordState.verifyOtp;
          _errorMessage = null;
        });
        _startTimer();
        // Request focus after short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocusNode.requestFocus();
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy số điện thoại này hoặc có lỗi xảy ra.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < _otpLength) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text.trim(),
          'otp': _otpController.text,
        }),
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resetToken = data['data']['resetToken'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(resetToken: resetToken),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Mã OTP sai hoặc đã hết hạn';
        });
        _otpController.clear();
        _otpFocusNode.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0) return;
    
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phoneController.text.trim()}),
      );
      
      if (!mounted) return;
      setState(() => _isResending = false);

      if (response.statusCode == 200) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã OTP mới đã được gửi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Không thể gửi lại OTP. Thử lại sau.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      });
    }
  }

  Widget _buildOtpBoxes() {
    return GestureDetector(
      onTap: () => _otpFocusNode.requestFocus(),
      child: Container(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            final text = _otpController.text;
            final isFocused = _otpFocusNode.hasFocus && 
                (text.length == index || (text.length == _otpLength && index == _otpLength - 1));
            final hasValue = index < text.length;
            final isError = _errorMessage != null;

            return Container(
              width: 50,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isError
                      ? Colors.red.shade400
                      : isFocused
                          ? Colors.blueAccent
                          : hasValue
                              ? Colors.grey.shade400
                              : Colors.grey.shade200,
                  width: isFocused || isError ? 2 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                hasValue ? text[index] : '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Quên mật khẩu",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Vui lòng nhập số điện thoại đã đăng ký, chúng tôi sẽ gửi mã OTP để đặt lại mật khẩu.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),

        // Error Message
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            hintText: 'Nhập số điện thoại của bạn',
            prefixIcon: const Icon(Icons.phone_android_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Gửi mã OTP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Xác thực OTP",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "Mã xác thực 6 số đã được gửi tới\n"),
              TextSpan(
                text: _phoneController.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        
        // Hidden TextField for keyboard
        SizedBox(
          height: 0,
          width: 0,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              maxLength: _otpLength,
            ),
          ),
        ),

        // Custom OTP Boxes
        _buildOtpBoxes(),
        
        const SizedBox(height: 16),

        // Error Message
        if (_errorMessage != null)
          Center(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        const SizedBox(height: 32),

        // Timer & Resend
        Center(
          child: Column(
            children: [
              if (_countdown > 0)
                Text(
                  "Mã sẽ hết hạn trong $_countdown giây",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Chưa nhận được mã? ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: _countdown == 0 && !_isResending ? _resendOtp : null,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Gửi lại",
                            style: TextStyle(
                              color: _countdown == 0
                                  ? Colors.blueAccent
                                  : Colors.grey.shade400,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        
        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (_otpController.text.length == _otpLength && !_isLoading)
                ? _verifyOtp
                : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Xác nhận",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            if (_currentState == ForgotPasswordState.verifyOtp) {
              setState(() {
                _currentState = ForgotPasswordState.enterPhone;
                _otpController.clear();
                _errorMessage = null;
              });
              _timer?.cancel();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentState == ForgotPasswordState.enterPhone
                ? _buildPhoneStep()
                : _buildOtpStep(),
          ),
        ),
      ),
    );
  }
}
