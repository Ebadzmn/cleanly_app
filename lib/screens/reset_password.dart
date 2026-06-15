import "dart:convert";

import "package:flutter/material.dart";

import "../config/api_config.dart";
import "../services/localization_service.dart";
import "../services/network_caller.dart";
import "../features/login/pages/login_page.dart";

class ResetPassword extends StatefulWidget {
  final String email;

  const ResetPassword({super.key, required this.email});


  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _resetPassword() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate("resetPassword.fillAllFields"),
          ),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate("resetPassword.passwordsDoNotMatch"),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(ApiConfig.buildUrl('/reset-password'));

    try {
      final response = await NetworkCaller.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          "email": widget.email,
          "password": _passwordController.text,
          "confirm_password": _confirmPasswordController.text,
        }),
      );

      final data = response.data;
      debugPrint("Reset Password Response: $data");

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data?['message'] ?? "Password reset successful"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Reset password failed")),
        );
      }
    } catch (e) {
      debugPrint("Error resetting password: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translateWithParams(
              "resetPassword.errorOccurred",
              {"error": e.toString()},
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();

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

                    _buildWelcomeMessage(),

                    const SizedBox(height: 40),

                    _buildFormFields(),

                    const SizedBox(height: 80),

                    _buildGetStartedButton(),

                    const SizedBox(height: 20),
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
          child: Image
              .asset(
            "assets/images/Cleanly_Logo.jpg",
            width: 100,
            height: 100,
            alignment: Alignment.center,
          ),
        ),
        SizedBox(height:5),
        Text(
          LocalizationService().translate("resetPassword.appName"),
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

  Widget _buildWelcomeMessage() {
    return Text(
      LocalizationService().translate("resetPassword.title"),
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xff77CCD9),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildInputField(
          label: LocalizationService().translate("resetPassword.password"),
          controller: _passwordController,
          placeholder: LocalizationService().translate("resetPassword.passwordPlaceholder"),
          isPassword: true,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: LocalizationService().translate("resetPassword.confirmPassword"),
          controller: _confirmPasswordController,
          placeholder: LocalizationService().translate("resetPassword.confirmPasswordPlaceholder"),
          isPassword: true,
          isReEnterPassword: true,
        ),

      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isReEnterPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            SizedBox(width:3),
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
            controller: controller,
            keyboardType: keyboardType,
            obscureText:
            isPassword
                ? (isReEnterPassword
                ? _obscureConfirmPassword
                : _obscurePassword)
                : false,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2C2C2C),                fontWeight:FontWeight.w500),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF4A5565),
                fontSize: 14,
                fontWeight:FontWeight.w400,

              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon:
              isPassword
                  ? IconButton(
                icon: Icon(
                  (isReEnterPassword
                      ? _obscureConfirmPassword
                      : _obscurePassword)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: const Color(0xFF6B7280),
                ),
                onPressed: () {
                  setState(() {
                    if (isReEnterPassword) {
                      _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment:MainAxisAlignment.center,
          crossAxisAlignment:CrossAxisAlignment.center,
          children: [
            Text(
              LocalizationService().translate("common.submit"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if(_isLoading)...[
              SizedBox(width:10),
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  backgroundColor: Color(0xFF06E0FB),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _handleGetStarted() {
    if (
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty
      ) {
      _showErrorDialog(LocalizationService().translate("resetPassword.fillAllFields"));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(LocalizationService().translate("resetPassword.passwordsDoNotMatch"));
      return;
    }

    _showSuccessDialog(LocalizationService().translate("resetPassword.passwordUpdatedSuccessfully"));
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              child: Text(LocalizationService().translate("common.ok")),
            ),
          ],
        );
      },
    );
  }
}

