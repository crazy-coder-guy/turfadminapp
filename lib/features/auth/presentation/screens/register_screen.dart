import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';

const _ownerTypes = ['individual', 'partnership', 'company', 'trust'];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _panController = TextEditingController();
  final _gstinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final String _ownerType = _ownerTypes.first;
  bool _acceptedTerms = false;
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _errorMessage;

  static const _totalSteps = 4;
  static const _stepTitles = [
    'Personal Info',
    'Business Details',
    'Security',
    'Review & Finish',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in [
      _fullNameController,
      _phoneController,
      _emailController,
      _businessNameController,
      _panController,
      _gstinController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    final formKey = [_step1Key, _step2Key, _step3Key][_currentStep];
    if (formKey.currentState != null && !formKey.currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) _goToStep(_currentStep + 1);
  }

  void _back() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> _submit() async {
    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Please accept the Terms & Conditions to continue.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final rawDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = '+91$rawDigits';

      await ref.read(authControllerProvider.notifier).register(
            fullName: _fullNameController.text.trim(),
            phoneNumber: formattedPhone,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            profileImageUrl: 'https://api.dicebear.com/7.x/initials/png?seed='
                '${Uri.encodeComponent(_fullNameController.text.trim())}',
            ownerType: _ownerType,
            businessName: _businessNameController.text.trim(),
            panNumber: _panController.text.trim().toUpperCase(),
            gstin: _gstinController.text.trim().isEmpty
                ? null
                : _gstinController.text.trim().toUpperCase(),
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          title: Text(
            'Registration successful',
            style: AppTextStyles.sectionHeader().copyWith(color: const Color(0xFF0F172A)),
          ),
          content: Text(
            'Your admin account has been created. Please sign in to access your portal.',
            style: AppTextStyles.body(color: const Color(0xFF64748B)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go to sign in'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/login');
    } on AppException catch (error) {
      setState(() {
        _errorMessage = error.message;
        if (error.fieldErrors != null && error.fieldErrors!.isNotEmpty) {
          _errorMessage = '${error.message} ${error.fieldErrors!.values.join(' ')}';
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep == 0
            ? IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                onPressed: () => context.go('/login'),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: _back,
              ),
        title: Text(
          'Create Admin Account',
          style: AppTextStyles.appHeader().copyWith(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _CorporateStepIndicator(
              current: _currentStep,
              total: _totalSteps,
              titles: _stepTitles,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall(color: const Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalInfoStep(),
                  _buildBusinessInfoStep(),
                  _buildSecurityStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _currentStep == _totalSteps - 1
                      ? (_isSubmitting ? null : _submit)
                      : _next,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _totalSteps - 1 ? 'Complete Account Creation' : 'Continue',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentStep == _totalSteps - 1
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: AppTextStyles.sectionHeader().copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your full name and Indian mobile number for your admin profile.',
              style: AppTextStyles.body(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: _fullNameController,
              icon: Icons.person_outline_rounded,
              maxLength: 50,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your full name';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                if (v.trim().length > 50) return 'Name cannot exceed 50 characters';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildInputField(
              label: 'Mobile Number',
              hint: '9876543210',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixText: '+91 ',
              icon: Icons.phone_outlined,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                final digits = (v ?? '').trim();
                if (digits.length != 10) return 'Enter a valid 10-digit Indian mobile number';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
                  return 'Indian mobile numbers must start with 6, 7, 8, or 9';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildInputField(
              label: 'Work Email',
              hint: 'admin@company.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.mail_outline_rounded,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid work email' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Details',
              style: AppTextStyles.sectionHeader().copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Provide information about your business entity and tax identifiers.',
              style: AppTextStyles.body(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              label: 'Business / Legal Name',
              hint: 'Turf Sports Management Pvt Ltd',
              controller: _businessNameController,
              icon: Icons.business_outlined,
              maxLength: 60,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
            ),
            const SizedBox(height: 18),
            _buildInputField(
              label: 'PAN Number',
              hint: 'ABCDE1234F',
              controller: _panController,
              icon: Icons.badge_outlined,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                final value = (v ?? '').trim().toUpperCase();
                if (value.isEmpty) return 'PAN number is required';
                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value)) {
                  return 'PAN format must be 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F)';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildInputField(
              label: 'GSTIN (Optional)',
              hint: '22AAAAA0000A1Z5',
              controller: _gstinController,
              icon: Icons.receipt_long_outlined,
              maxLength: 15,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(15),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final value = v.trim().toUpperCase();
                if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(value)) {
                  return 'Enter a valid 15-digit GSTIN (e.g. 22AAAAA0000A1Z5)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security & Password',
              style: AppTextStyles.sectionHeader().copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a secure password to protect your admin dashboard.',
              style: AppTextStyles.body(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              label: 'Password',
              hint: '••••••••••••',
              controller: _passwordController,
              obscureText: _obscurePass,
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) =>
                  (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
            ),
            const SizedBox(height: 18),
            _buildInputField(
              label: 'Confirm Password',
              hint: '••••••••••••',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPass,
              icon: Icons.lock_clock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
              validator: (v) =>
                  v != _passwordController.text ? 'Passwords do not match' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Details',
            style: AppTextStyles.sectionHeader().copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verify all your information before completing your registration.',
            style: AppTextStyles.body(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _reviewItem('Full Name', _fullNameController.text),
                _reviewItem('Mobile', '+91 ${_phoneController.text}'),
                _reviewItem('Work Email', _emailController.text),
                _reviewItem('Business Name', _businessNameController.text),
                _reviewItem('PAN Number', _panController.text.toUpperCase()),
                if (_gstinController.text.trim().isNotEmpty)
                  _reviewItem('GSTIN', _gstinController.text.toUpperCase(), isLast: true)
                else
                  _reviewItem('GSTIN', 'N/A', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: _acceptedTerms,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service, Privacy Policy, and Business Merchant Agreement.',
                  style: AppTextStyles.body(color: const Color(0xFF475569)).copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? prefixText,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label().copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.5),
            prefixIcon: prefixText != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 14),
                      Icon(icon, color: const Color(0xFF64748B), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        prefixText.trim(),
                        style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 8),
                    ],
                  )
                : Icon(icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _reviewItem(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body(color: const Color(0xFF64748B)).copyWith(fontSize: 13.5),
          ),
          Text(
            value,
            style: AppTextStyles.body(color: const Color(0xFF0F172A)).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorporateStepIndicator extends StatelessWidget {
  const _CorporateStepIndicator({
    required this.current,
    required this.total,
    required this.titles,
  });

  final int current;
  final int total;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(total, (index) {
              final isActive = index <= current;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == total - 1 ? 0 : 8),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${current + 1} of $total: ${titles[current]}',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
