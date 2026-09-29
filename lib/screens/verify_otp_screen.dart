import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../api_constants.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String phone;
  const VerifyOtpScreen({super.key, required this.phone});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  
  static const int _otpLength = 6;
  
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _otpController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
      setState(() {}); // update UI for box filling
      if (_otpController.text.length == _otpLength) {
        _verifyOtp();
      }
    });
    // Request focus after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
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
          'phone': widget.phone,
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
        body: jsonEncode({'phone': widget.phone}),
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
                          ? Theme.of(context).primaryColor
                          : hasValue
                              ? Colors.grey.shade400
                              : Colors.grey.shade200,
                  width: isFocused || isError ? 2 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "Mã xác thực gồm 6 chữ số đã được gửi tới số điện thoại\n"),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Hidden TextField to capture keyboard input
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
                                        ? Theme.of(context).primaryColor
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
                    backgroundColor: Theme.of(context).primaryColor,
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
          ),
        ),
      ),
    );
  }
}
