import "dart:convert";
import "dart:developer";

import "package:cleanly_app/screens/reset_password.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../config/api_config.dart";
import "../services/localization_service.dart";
import "package:http/http.dart" as http;

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
    return Scaffold(
      backgroundColor: const Color(0xFFEEFBFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    _buildLogoSection(),

                    const SizedBox(height: 20),

                    _buildForgetPasswordLink(),

                    const SizedBox(height: 40),

                    _buildEmailSection(),

                    const SizedBox(height: 30),

                    if (_showOTPFields) _buildOTPSection(),

                    const Spacer(),

                    if (_showOTPFields) _buildSubmitButton(),

                    const SizedBox(height: 60),
                  ],
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
        Center(
          child: Image.asset(
            "assets/images/Cleanly_Logo.jpg",
            width: 100,
            height: 100,
            alignment: Alignment.center,
          ),
        ),
        SizedBox(height: 5),
        Text(
          LocalizationService().translate("forgotPassword.appName"),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff4A5565),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildForgetPasswordLink() {
    return Text(
      LocalizationService().translate("forgotPassword.title"),
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xff77CCD9),
        fontWeight: FontWeight.w600,
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
              LocalizationService().translate("forgotPassword.email"),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            SizedBox(width: 3),
            Text(
              "*",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFC70036),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w500,
            ),

            decoration: InputDecoration(
              hintText: LocalizationService().translate(
                "forgotPassword.emailPlaceholder",
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF4A5565),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),

              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 45,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF77CCD9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _isLoading ? null : _recoverPassword,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward,
                                color: Colors.black,
                                size: 20,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2C2C),
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          hintText: "-",
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 18),
          contentPadding: EdgeInsets.symmetric(vertical: 5),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isVerifyLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
            LocalizationService().translate("common.submit"),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_isVerifyLoading) ...[
              SizedBox(width: 10),
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  backgroundColor: Color(0xFF06E0FB),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
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
      final response = await http.post(
        url,
        body: {"email": _emailController.text.trim()},
      );

      final data = json.decode(response.body);
      log('Forgot Password Response: $data');

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        if (data['user'] != null && data['user']['phone'] != null) {
          await prefs.setString('phone', data['user']['phone']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ??
                  LocalizationService().translate("forgotPassword.otpSent"),
            ),
          ),
        );

        setState(() {
          _isLoading = false;
          _showOTPFields = true;
        });
      } else {
        String errorMessage = data['message'] ?? 'Failed to send OTP.';
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          errorMessage = errors.values
              .expand((e) => e)
              .map((e) => e.toString())
              .join('\n');
        }

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
      final response = await http.post(
        url,
        body: {"email": _emailController.text.trim(), "code": otp},
      );

      final data = json.decode(response.body);
      debugPrint("Verify Code Response: $data");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Code verified")),
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
          SnackBar(content: Text(data['error'] ?? "Verification failed")),
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
