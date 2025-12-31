import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/address_provider.dart';
import '../../../data/models/user.dart';
import '../../../utils/theme.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // New address field controllers
  final _houseNoFloorController = TextEditingController();
  final _buildingBlockController = TextEditingController();
  final _landmarkAreaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();

  AddressLabel _selectedLabel = AddressLabel.home;
  bool _isDefault = false;
  bool _isLoading = false;

  // Indian states list
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _houseNoFloorController.text = widget.address!.houseNoFloor;
      _buildingBlockController.text = widget.address!.buildingBlock;
      _landmarkAreaController.text = widget.address!.landmarkArea;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _pincodeController.text = widget.address!.pincode;
      _recipientNameController.text = widget.address!.recipientName ?? '';
      _recipientPhoneController.text = widget.address!.recipientPhone ?? '';
      _selectedLabel = widget.address!.label;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _houseNoFloorController.dispose();
    _buildingBlockController.dispose();
    _landmarkAreaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Address Label Selection
            _buildSectionHeader('Address Type', Icons.label_outline),
            const SizedBox(height: 8),
            _buildAddressLabelSelector(),
            const SizedBox(height: 24),

            // Address Details Section
            _buildSectionHeader('Address Details', Icons.location_on_outlined),
            const SizedBox(height: 12),

            // House No. & Floor
            _buildTextField(
              controller: _houseNoFloorController,
              label: 'House No. & Floor *',
              hint: 'e.g., Flat 302, 3rd Floor',
              prefixIcon: Icons.home_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'House no. & floor is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Building & Block
            _buildTextField(
              controller: _buildingBlockController,
              label: 'Building & Block Number *',
              hint: 'e.g., Tower A, Block 5, Green Valley Apartments',
              prefixIcon: Icons.apartment_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Building & block number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Landmark & Area
            _buildTextField(
              controller: _landmarkAreaController,
              label: 'Landmark & Area *',
              hint: 'e.g., Near Central Mall, Sector 15',
              prefixIcon: Icons.place_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Landmark & area is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City & State Row
            Row(
              children: [
                // City
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City *',
                    hint: 'e.g., Mumbai',
                    prefixIcon: Icons.location_city_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // State Dropdown
                Expanded(
                  child: _buildStateDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pincode
            _buildTextField(
              controller: _pincodeController,
              label: 'Pincode *',
              hint: '6-digit pincode',
              prefixIcon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pincode is required';
                }
                if (value.trim().length != 6) {
                  return 'Pincode must be 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Recipient Details Section (Optional)
            _buildSectionHeader('Recipient Details (Optional)', Icons.person_outline),
            const SizedBox(height: 12),

            // Recipient Name
            _buildTextField(
              controller: _recipientNameController,
              label: 'Recipient Name',
              hint: 'Name of person at this address',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            // Recipient Phone
            _buildTextField(
              controller: _recipientPhoneController,
              label: 'Recipient Phone',
              hint: '10-digit mobile number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length != 10) {
                  return 'Phone must be 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Set as Default Toggle
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: const Text('Set as Default Address'),
                subtitle: const Text('Use this address as your primary delivery address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                activeColor: AppTheme.primaryGold,
                secondary: Icon(
                  _isDefault ? Icons.star : Icons.star_border,
                  color: _isDefault ? AppTheme.primaryGold : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Address Preview
            if (_hasAddressData()) ...[
              _buildAddressPreview(),
              const SizedBox(height: 24),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Address' : 'Save Address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressLabelSelector() {
    return Row(
      children: AddressLabel.values.map((label) {
        final isSelected = _selectedLabel == label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: label != AddressLabel.other ? 8 : 0,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedLabel = label;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGold : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getLabelIcon(label),
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getLabelIcon(AddressLabel label) {
    switch (label) {
      case AddressLabel.home:
        return Icons.home_outlined;
      case AddressLabel.work:
        return Icons.business_outlined;
      case AddressLabel.other:
        return Icons.location_on_outlined;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: (_) => setState(() {}), // Refresh preview
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _stateController.text.isEmpty ? null : _stateController.text,
      decoration: InputDecoration(
        labelText: 'State *',
        prefixIcon: const Icon(Icons.map_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
        ),
      ),
      items: _indianStates.map((state) {
        return DropdownMenuItem(
          value: state,
          child: Text(state, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _stateController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'State is required';
        }
        return null;
      },
      isExpanded: true,
    );
  }

  bool _hasAddressData() {
    return _houseNoFloorController.text.isNotEmpty ||
           _buildingBlockController.text.isNotEmpty ||
           _landmarkAreaController.text.isNotEmpty ||
           _cityController.text.isNotEmpty;
  }

  Widget _buildAddressPreview() {
    final parts = <String>[
      _houseNoFloorController.text,
      _buildingBlockController.text,
      _landmarkAreaController.text,
      _cityController.text,
      _stateController.text,
      _pincodeController.text,
    ].where((s) => s.trim().isNotEmpty).toList();

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview_outlined, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Address Preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLabelIcon(_selectedLabel),
                        size: 14,
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedLabel.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              parts.join(', '),
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (_recipientNameController.text.isNotEmpty ||
                _recipientPhoneController.text.isNotEmpty) ...[
              const Divider(height: 16),
              if (_recipientNameController.text.isNotEmpty)
                Text(
                  'Recipient: ${_recipientNameController.text}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              if (_recipientPhoneController.text.isNotEmpty)
                Text(
                  'Phone: ${_recipientPhoneController.text}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final addressProvider = context.read<AddressProvider>();
    bool success;

    if (isEditing) {
      success = await addressProvider.updateAddress(
        addressId: widget.address!.id,
        houseNoFloor: _houseNoFloorController.text.trim(),
        buildingBlock: _buildingBlockController.text.trim(),
        landmarkArea: _landmarkAreaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        label: _selectedLabel.name,
        recipientName: _recipientNameController.text.trim().isNotEmpty
            ? _recipientNameController.text.trim()
            : null,
        recipientPhone: _recipientPhoneController.text.trim().isNotEmpty
            ? _recipientPhoneController.text.trim()
            : null,
        isDefault: _isDefault,
      );
    } else {
      success = await addressProvider.addAddress(
        houseNoFloor: _houseNoFloorController.text.trim(),
        buildingBlock: _buildingBlockController.text.trim(),
        landmarkArea: _landmarkAreaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        label: _selectedLabel.name,
        recipientName: _recipientNameController.text.trim().isNotEmpty
            ? _recipientNameController.text.trim()
            : null,
        recipientPhone: _recipientPhoneController.text.trim().isNotEmpty
            ? _recipientPhoneController.text.trim()
            : null,
        isDefault: _isDefault,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Address updated successfully' : 'Address added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addressProvider.error ?? 'Failed to save address'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}
