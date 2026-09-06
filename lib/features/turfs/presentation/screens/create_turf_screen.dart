import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/amenity.dart';
import '../../../../shared/models/turf_location.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../master_data/domain/master_data_providers.dart';
import '../../domain/turf_providers.dart';

class CreateTurfScreen extends ConsumerStatefulWidget {
  const CreateTurfScreen({super.key, this.turfId});

  final String? turfId;

  @override
  ConsumerState<CreateTurfScreen> createState() => _CreateTurfScreenState();
}

class _CreateTurfScreenState extends ConsumerState<CreateTurfScreen> {
  final _pageController = PageController();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _localityController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final Set<String> _selectedAmenityIds = {};

  List<String> _cityOptions = [];
  List<String> _stateOptions = [];
  String? _selectedCity;
  String? _selectedState;
  bool _isLookingUpPincode = false;
  String? _pincodeLookupError;
  Timer? _pincodeDebounce;

  bool _isFetchingLocation = false;

  int _currentStep = 0;
  bool _isLoadingExisting = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  static const _totalSteps = 4;

  static const List<String> _stepTitles = [
    'BASIC DETAILS',
    'LOCATION',
    'AMENITIES',
    'REVIEW & SAVE',
  ];

  bool get _isEditMode => widget.turfId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoadingExisting = true);
    try {
      final turf = await ref.read(turfRepositoryProvider).getTurf(widget.turfId!);
      _nameController.text = turf.name;
      _descriptionController.text = turf.description ?? '';
      _phoneController.text = turf.contactPhone.replaceFirst(RegExp(r'^\+91\s*'), '');
      _emailController.text = turf.contactEmail ?? '';
      final location = turf.location;
      if (location != null) {
        _addressLine1Controller.text = location.addressLine1;
        _addressLine2Controller.text = location.addressLine2 ?? '';
        _localityController.text = location.locality ?? '';
        _districtController.text = location.district ?? '';
        _pincodeController.text = location.pincode;
        _latController.text = location.latitude.toString();
        _lngController.text = location.longitude.toString();
        _selectedCity = location.city.isNotEmpty ? location.city : null;
        _selectedState = location.state.isNotEmpty ? location.state : null;
        _cityOptions = _selectedCity != null ? [_selectedCity!] : [];
        _stateOptions = _selectedState != null ? [_selectedState!] : [];
      }
      _selectedAmenityIds
        ..clear()
        ..addAll(turf.amenities.map((a) => a.id));
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _pageController.dispose();
    for (final controller in [
      _nameController,
      _descriptionController,
      _phoneController,
      _emailController,
      _addressLine1Controller,
      _addressLine2Controller,
      _localityController,
      _districtController,
      _pincodeController,
      _latController,
      _lngController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPincodeChanged(String value) {
    _pincodeDebounce?.cancel();
    final digits = value.trim();
    if (digits.length != 6 || int.tryParse(digits) == null) {
      setState(() {
        _pincodeLookupError = null;
        _cityOptions = [];
        _stateOptions = [];
        _selectedCity = null;
        _selectedState = null;
      });
      return;
    }
    _pincodeDebounce = Timer(const Duration(milliseconds: 400), () => _lookupPincode(digits));
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() {
      _isLookingUpPincode = true;
      _pincodeLookupError = null;
    });
    try {
      final response = await Dio().get<List<dynamic>>('https://api.postalpincode.in/pincode/$pincode');
      final results = response.data ?? const [];
      final first = results.isNotEmpty ? results.first as Map<String, dynamic> : null;
      final postOffices = (first?['PostOffice'] as List<dynamic>?) ?? const [];

      if (first?['Status'] != 'Success' || postOffices.isEmpty) {
        setState(() {
          _cityOptions = [];
          _stateOptions = [];
          _selectedCity = null;
          _selectedState = null;
          _pincodeLookupError = 'Pincode not found. Please check and try again.';
        });
        return;
      }

      final cities = postOffices
          .map((po) => ((po as Map<String, dynamic>)['District'] ?? '') as String)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      final states = postOffices
          .map((po) => ((po as Map<String, dynamic>)['State'] ?? '') as String)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _cityOptions = cities;
        _stateOptions = states;
        _selectedCity = cities.length == 1 ? cities.first : null;
        _selectedState = states.length == 1 ? states.first : null;
      });
    } catch (_) {
      setState(() {
        _cityOptions = [];
        _stateOptions = [];
        _selectedCity = null;
        _selectedState = null;
        _pincodeLookupError = 'Could not look up pincode. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isLookingUpPincode = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Turn on location services and try again.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission is required to fetch your current position.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error is String ? error : 'Could not fetch your current location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
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
    final formKey = _currentStep == 0 ? _step1Key : (_currentStep == 1 ? _step2Key : null);
    if (formKey != null && !(formKey.currentState?.validate() ?? true)) return;
    if (_currentStep < _totalSteps - 1) _goToStep(_currentStep + 1);
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      context.pop();
    }
  }

  TurfLocation? get _location {
    if (_addressLine1Controller.text.trim().isEmpty) return null;
    return TurfLocation(
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      locality: _localityController.text.trim(),
      city: _selectedCity ?? '',
      district: _districtController.text.trim(),
      state: _selectedState ?? '',
      pincode: _pincodeController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 0,
      longitude: double.tryParse(_lngController.text.trim()) ?? 0,
    );
  }

  String get _formattedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('91') && digits.length > 10
        ? '+$digits'
        : '+91$digits';
  }

  Future<void> _save() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(turfRepositoryProvider);
      final turfId = widget.turfId;
      if (turfId == null) {
        final turf = await repository.createTurf(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          contactPhone: _formattedPhone,
          contactEmail: _emailController.text.trim(),
          location: _location,
          amenityIds: _selectedAmenityIds.toList(),
        );
        ref.invalidate(turfListProvider);
        if (mounted) context.go('/turfs/${turf.id}');
      } else {
        await repository.updateTurf(
          turfId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          contactPhone: _formattedPhone,
          contactEmail: _emailController.text.trim(),
          location: _location,
          amenityIds: _selectedAmenityIds.toList(),
        );
        ref.invalidate(turfDetailProvider(turfId));
        ref.invalidate(turfListProvider);
        if (mounted) context.go('/turfs/$turfId');
      }
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: _back,
        ),
        title: Text(
          _isEditMode ? 'Edit Turf' : 'Create New Turf',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF $_totalSteps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        _stepTitles[_currentStep],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_totalSteps, (index) {
                      final isActive = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 6),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
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
                  _buildBasicDetailsStep(),
                  _buildLocationStep(),
                  _buildAmenitiesStep(),
                  _buildReviewStep(),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 76),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : (_currentStep == _totalSteps - 1 ? _save : _next),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? (_isEditMode ? 'Save Changes' : 'Create Turf')
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Turf Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter the essential information for your sports facility.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            AppTextField(
              label: 'Turf Name',
              hint: 'e.g. Arena Turf Sports Club',
              controller: _nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Turf name is required' : null,
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Description',
              hint: 'Brief description of facility, pitch size, opening hours...',
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Contact Phone Number',
              prefixText: '+91 ',
              hint: '9876543210',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
                if (!RegExp(r'^[6-9]').hasMatch(digits)) return 'Number must start with 6, 7, 8 or 9';
                return null;
              },
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Contact Email (Optional)',
              hint: 'contact@yourturf.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location & Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Help players locate your turf easily on the map.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            AppTextField(
              label: 'Address Line 1',
              hint: 'Building name, street address',
              controller: _addressLine1Controller,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
            ),
            const SizedBox(height: 18),

            AppTextField(
              label: 'Address Line 2 (Optional)',
              hint: 'Landmark, suite or floor',
              controller: _addressLine2Controller,
            ),
            const SizedBox(height: 18),

            AppTextField(
              label: 'Area / Locality',
              hint: 'e.g. Koramangala',
              controller: _localityController,
            ),
            const SizedBox(height: 18),

            AppTextField(
              label: 'Pincode',
              hint: '560095',
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              onChanged: _onPincodeChanged,
              suffixIcon: _isLookingUpPincode
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              validator: (v) => (v == null || v.trim().length != 6) ? '6-digit pincode' : null,
            ),
            if (_pincodeLookupError != null) ...[
              const SizedBox(height: 6),
              Text(
                _pincodeLookupError!,
                style: AppTextStyles.bodySmall(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'City',
                    hint: 'Enter pincode first',
                    value: _selectedCity,
                    options: _cityOptions,
                    onChanged: (value) => setState(() => _selectedCity = value),
                    validator: (v) => (v == null || v.isEmpty) ? 'City is required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DropdownField(
                    label: 'State',
                    hint: 'Enter pincode first',
                    value: _selectedState,
                    options: _stateOptions,
                    onChanged: (value) => setState(() => _selectedState = value),
                    validator: (v) => (v == null || v.isEmpty) ? 'State is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            AppTextField(
              label: 'District (Optional)',
              hint: 'District name',
              controller: _districtController,
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined, size: 18),
                label: const Text('Use current location'),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Latitude',
                    hint: '12.9716',
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTextField(
                    label: 'Longitude',
                    hint: '77.5946',
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesStep() {
    final amenitiesAsync = ref.watch(amenitiesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Turf Amenities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select all facilities available for players at this turf.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: amenitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorStateView(
                message: 'Unable to load amenities.',
                onRetry: () => ref.invalidate(amenitiesProvider),
              ),
              data: (amenities) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedAmenityIds.isNotEmpty) ...[
                    _buildSelectedAmenitiesSummary(amenities),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: amenities.where((a) => a.isActive).map((amenity) {
                          final selected = _selectedAmenityIds.contains(amenity.id);
                          return FilterChip(
                            label: Text(
                              amenity.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                color: selected ? AppColors.primary : const Color(0xFF334155),
                              ),
                            ),
                            selected: selected,
                            showCheckmark: true,
                            selectedColor: const Color(0xFFEFF8FF),
                            backgroundColor: const Color(0xFFF8FAFC),
                            side: BorderSide(
                              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                              width: selected ? 1.5 : 1.0,
                            ),
                            checkmarkColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  _selectedAmenityIds.add(amenity.id);
                                } else {
                                  _selectedAmenityIds.remove(amenity.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAmenitiesSummary(List<Amenity> amenities) {
    final selected = amenities.where((a) => _selectedAmenityIds.contains(a.id)).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9E6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected (${selected.length})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selected.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final amenity = selected[index];
                return Chip(
                  label: Text(
                    amenity.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                  onDeleted: () => setState(() => _selectedAmenityIds.remove(amenity.id)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Save',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Double-check details before saving your turf.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          _ReviewItem(label: 'Turf Name', value: _nameController.text),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _ReviewItem(
            label: 'Description',
            value: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'No description provided',
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _ReviewItem(label: 'Contact Phone', value: _formattedPhone),
          if (_emailController.text.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _ReviewItem(label: 'Contact Email', value: _emailController.text),
          ],
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (_addressLine1Controller.text.isNotEmpty)
            _ReviewItem(
              label: 'Address',
              value: '${_addressLine1Controller.text}, ${_selectedCity ?? ''}, ${_selectedState ?? ''} ${_pincodeController.text}',
            ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _ReviewItem(
            label: 'Selected Amenities',
            value: '${_selectedAmenityIds.length} amenities selected',
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB9E6FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? 'Save changes. You can manage courts and photos directly from the turf detail screen.'
                        : 'Your turf will be created as a draft. You can add courts, set pricing, upload photos, and submit for review next.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF175CD3),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label()),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint, overflow: TextOverflow.ellipsis),
          items: options
              .map((option) => DropdownMenuItem(value: option, child: Text(option, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: options.isEmpty ? null : onChanged,
          validator: validator,
          decoration: const InputDecoration(filled: true, fillColor: AppColors.surface),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
