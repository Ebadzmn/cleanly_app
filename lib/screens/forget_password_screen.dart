import "dart:convert";
import "dart:developer";

import "package:cleanly_app/screens/reset_password.dart";
import "package:cleanly_app/widgets/app_button.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../config/api_config.dart";
import "../services/localization_service.dart";
import "../services/network_caller.dart";

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    5,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    5,
    (index) => FocusNode(),
  );

  bool _showOTPFields = false;
  bool _isLoading = false;
  bool _isVerifyLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.7, 1.0],
            colors: [
              Color(0xFFC7F0F9), // Light sky blue
              Color(0xFFEDF8FA), // Light transition
              Color(0xFFFCE18D), // Soft yellow transition
              Color(0xFFF4C535), // Golden yellow
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildLogoSection(),

                      const SizedBox(height: 10),

                      Center(child: _buildForgetPasswordLink()),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            _buildEmailSection(),
                            if (_showOTPFields) ...[
                              const SizedBox(height: 24),
                              _buildOTPSection(),
                            ],
                          ],
                        ),
                      ),

                      const Spacer(),

                      if (_showOTPFields) ...[
                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 30),
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

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/images/Cleanly_Logo.jpg",
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          LocalizationService().translate("forgotPassword.appName") ?? "Cleanly",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForgetPasswordLink() {
    return Text(
      LocalizationService().translate("forgotPassword.title") ?? "Forgot Password",
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              LocalizationService().translate("forgotPassword.email") ?? "Email Address",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A4D3D),
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              "*",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC70036),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F5ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5A4D3D),
            ),
            decoration: InputDecoration(
              hintText: LocalizationService().translate(
                "forgotPassword.emailPlaceholder",
              ) ?? "name@company.com",
              hintStyle: const TextStyle(
                color: Color(0xFFA19C93),
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.mail_outline,
                color: Color(0xFFA19C93),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1F3A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isLoading ? null : _recoverPassword,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService().translate("forgotPassword.enterOTP"),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return _buildOTPField(index);
          }),
        ),
      ],
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5A4D3D),
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          hintText: "-",
          hintStyle: TextStyle(color: Color(0xFFA19C93), fontSize: 20),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          }
        },
        onTap: () {
          _otpControllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[index].text.length,
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AppButton(
      label: LocalizationService().translate("common.submit"),
      onPressed: _isVerifyLoading ? null : _handleSubmit,
      variant: AppButtonVariant.primary,
      isLoading: _isVerifyLoading,
      fullWidth: true,
    );
  }

  void _recoverPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate("forgotPassword.enterEmail"),
          ),
        ),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate("forgotPassword.enterValidEmail"),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(ApiConfig.buildUrl('/forgot-password'));

    try {
      final response = await NetworkCaller.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({"email": _emailController.text.trim()}),
      );

      final data = response.data;
      log('Forgot Password Response: $data');

      if (response.isSuccess) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        if (data != null && data['user'] != null && data['user']['phone'] != null) {
          await prefs.setString('phone', data['user']['phone']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data?["message"] ??
                  LocalizationService().translate("forgotPassword.otpSent"),
            ),
          ),
        );

        setState(() {
          _isLoading = false;
          _showOTPFields = true;
        });
      } else {
        String errorMessage = response.message ?? data?['message'] ?? LocalizationService().translate("forgotPassword.failedToSendOTP");
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate("forgotPassword.invalidEmail"),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmit() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 4) {
      _showErrorDialog(
        LocalizationService().translate("forgotPassword.complete_otp"),
      );
      return;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate("forgotPassword.emailMissing"),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isVerifyLoading = true;
    });

    final url = Uri.parse(ApiConfig.buildUrl('/verify-code'));

    try {
      final response = await NetworkCaller.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({"email": _emailController.text.trim(), "code": otp}),
      );

      final data = response.data;
      debugPrint("Verify Code Response: $data");

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data?['message'] ?? LocalizationService().translate("forgotPassword.codeVerified"))),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPassword(email: _emailController.text.trim()),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? data?['error'] ?? LocalizationService().translate("forgotPassword.verificationFailed"))),
        );
      }
    } catch (e) {
      debugPrint("Error verifying code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translateWithParams(
              "forgotPassword.errorOccurred",
              {"error": e.toString()},
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        _isVerifyLoading = false;
      });
    }
  }

  
  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate("common.error")),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService().translate("common.ok")),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate("common.success")),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService().translate("common.ok")),
            ),
          ],
        );
      },
    );
  }
}
