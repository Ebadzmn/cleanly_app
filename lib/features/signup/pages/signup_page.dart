import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/localization_service.dart';
import '../../login/pages/login_page.dart';
import '../controllers/signup_controller.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SignupController controller = Get.put(SignupController());
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
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: _buildForm(controller),
                      ),
                      const SizedBox(height: 24),
                      _buildTermsAndConditions(),
                      const Spacer(),
                      _buildLoginLink(),
                      const SizedBox(height: 40),
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

  Widget _buildHeader() {
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
          child: Image.asset(
            "assets/images/Cleanly_Logo.jpg",
            width: 70,
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          LocalizationService().translate("signup.appName") ?? "Cleanly",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          LocalizationService().translate("signup.title") ?? "Create your account",
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(SignupController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.firstNameController,
                label: LocalizationService().translate("signup.firstName") ?? "First Name",
                hint: LocalizationService().translate("signup.firstNamePlaceholder") ?? "John",
                icon: Icons.person_outline,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.lastNameController,
                label: LocalizationService().translate("signup.lastName") ?? "Last Name",
                hint: LocalizationService().translate("signup.lastNamePlaceholder") ?? "Doe",
                icon: Icons.person_outline,
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: controller.emailController,
          label: LocalizationService().translate("signup.email") ?? "Email Address",
          hint: LocalizationService().translate("signup.emailPlaceholder") ?? "name@company.com",
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: controller.passwordController,
          label: LocalizationService().translate("signup.password") ?? "Password",
          hint: "••••••••",
          obscureText: controller.obscurePassword,
          onToggleVisibility: controller.togglePasswordVisibility,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: controller.reEnterPasswordController,
          label: LocalizationService().translate("signup.reEnterPassword") ?? "Confirm Password",
          hint: "••••••••",
          obscureText: controller.obscureReEnterPassword,
          onToggleVisibility: controller.toggleReEnterPasswordVisibility,
          isRequired: true,
        ),
        const SizedBox(height: 32),
        _buildSignupButton(controller),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
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
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A4D3D),
              ),
            ),
            if (isRequired)
              const Text(
                " *",
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
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, color: Color(0xFF5A4D3D)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA19C93), fontSize: 15),
              prefixIcon: Icon(icon, color: const Color(0xFFA19C93), size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required RxBool obscureText,
    required VoidCallback onToggleVisibility,
    bool isRequired = false,
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
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A4D3D),
              ),
            ),
            if (isRequired)
              const Text(
                " *",
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
          child: Obx(
            () => TextField(
              controller: controller,
              obscureText: obscureText.value,
              style: const TextStyle(fontSize: 16, color: Color(0xFF5A4D3D)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFA19C93), fontSize: 24, letterSpacing: 4),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFA19C93), size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFFA19C93),
                    size: 22,
                  ),
                  onPressed: onToggleVisibility,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton(SignupController controller) {
    return Obx(
      () => Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF4C535),
        ),
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.handleGetStarted,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A4D3D)),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      LocalizationService().translate("signup.getStarted") ?? "Get Started",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A4D3D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Color(0xFF5A4D3D), size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Text(
      LocalizationService().translate("signup.termsAndConditions") ?? "By signing up you agree to our Terms and Conditions",
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF5A4D3D),
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Color(0xFF5A4D3D)),
          children: [
            TextSpan(
              text: LocalizationService().translate("signup.alreadyHaveAnAccount") ?? "Already have an account? ",
            ),
            TextSpan(
              text: LocalizationService().translate("signup.signIn") ?? "Sign In",
              style: const TextStyle(
                color: Color(0xFF266185),
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()..onTap = () => Get.to(() => const LoginPage()),
            ),
          ],
        ),
      ),
    );
  }
}
