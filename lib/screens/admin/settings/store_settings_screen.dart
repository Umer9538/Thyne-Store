import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/store_settings.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../utils/theme.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Tax Settings
  late TextEditingController _gstRateController;
  late TextEditingController _gstNumberController;
  bool _enableGst = true;

  // Shipping Settings
  late TextEditingController _freeShippingThresholdController;
  late TextEditingController _shippingCostController;
  bool _enableFreeShipping = true;

  // COD Settings
  bool _enableCod = true;
  late TextEditingController _codChargeController;
  late TextEditingController _codMaxAmountController;

  // Store Info
  late TextEditingController _storeNameController;
  late TextEditingController _storeEmailController;
  late TextEditingController _storePhoneController;
  late TextEditingController _storeAddressController;
  late TextEditingController _currencyController;
  late TextEditingController _currencySymbolController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _initControllers() {
    _gstRateController = TextEditingController(text: '18');
    _gstNumberController = TextEditingController();
    _freeShippingThresholdController = TextEditingController(text: '1000');
    _shippingCostController = TextEditingController(text: '99');
    _codChargeController = TextEditingController(text: '0');
    _codMaxAmountController = TextEditingController(text: '50000');
    _storeNameController = TextEditingController(text: 'Thyne Jewels');
    _storeEmailController = TextEditingController();
    _storePhoneController = TextEditingController();
    _storeAddressController = TextEditingController();
    _currencyController = TextEditingController(text: 'INR');
    _currencySymbolController = TextEditingController(text: '\u20B9');
  }

  Future<void> _loadSettings() async {
    final provider = context.read<StoreSettingsProvider>();
    await provider.loadSettings();

    if (mounted) {
      final settings = provider.settings;
      setState(() {
        _gstRateController.text = settings.gstRate.toString();
        _gstNumberController.text = settings.gstNumber;
        _enableGst = settings.enableGst;
        _freeShippingThresholdController.text = settings.freeShippingThreshold.toString();
        _shippingCostController.text = settings.shippingCost.toString();
        _enableFreeShipping = settings.enableFreeShipping;
        _enableCod = settings.enableCod;
        _codChargeController.text = settings.codCharge.toString();
        _codMaxAmountController.text = settings.codMaxAmount.toString();
        _storeNameController.text = settings.storeName;
        _storeEmailController.text = settings.storeEmail;
        _storePhoneController.text = settings.storePhone;
        _storeAddressController.text = settings.storeAddress;
        _currencyController.text = settings.currency;
        _currencySymbolController.text = settings.currencySymbol;
      });
    }
  }

  @override
  void dispose() {
    _gstRateController.dispose();
    _gstNumberController.dispose();
    _freeShippingThresholdController.dispose();
    _shippingCostController.dispose();
    _codChargeController.dispose();
    _codMaxAmountController.dispose();
    _storeNameController.dispose();
    _storeEmailController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    _currencyController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final settings = StoreSettings(
      gstRate: double.tryParse(_gstRateController.text) ?? 18.0,
      gstNumber: _gstNumberController.text,
      enableGst: _enableGst,
      freeShippingThreshold: double.tryParse(_freeShippingThresholdController.text) ?? 1000.0,
      shippingCost: double.tryParse(_shippingCostController.text) ?? 99.0,
      enableFreeShipping: _enableFreeShipping,
      enableCod: _enableCod,
      codCharge: double.tryParse(_codChargeController.text) ?? 0.0,
      codMaxAmount: double.tryParse(_codMaxAmountController.text) ?? 50000.0,
      storeName: _storeNameController.text,
      storeEmail: _storeEmailController.text,
      storePhone: _storePhoneController.text,
      storeAddress: _storeAddressController.text,
      currency: _currencyController.text,
      currencySymbol: _currencySymbolController.text,
    );

    final provider = context.read<StoreSettingsProvider>();
    final success = await provider.updateSettings(settings);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Settings saved successfully' : 'Failed to save settings'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Settings'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: Consumer<StoreSettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Tax Settings (GST)', Icons.receipt_long),
                _buildTaxSection(),
                const SizedBox(height: 24),
                _buildSectionHeader('Shipping Settings', Icons.local_shipping),
                _buildShippingSection(),
                const SizedBox(height: 24),
                _buildSectionHeader('Cash on Delivery (COD)', Icons.payments),
                _buildCodSection(),
                const SizedBox(height: 24),
                _buildSectionHeader('Store Information', Icons.store),
                _buildStoreInfoSection(),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveSettings,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable GST'),
              subtitle: const Text('Apply GST on all orders'),
              value: _enableGst,
              onChanged: (value) => setState(() => _enableGst = value),
              activeColor: AppTheme.primaryGold,
            ),
            const Divider(),
            TextFormField(
              controller: _gstRateController,
              decoration: const InputDecoration(
                labelText: 'GST Rate (%)',
                hintText: 'e.g., 18',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_enableGst && (value == null || value.isEmpty)) {
                  return 'Please enter GST rate';
                }
                final rate = double.tryParse(value ?? '');
                if (_enableGst && (rate == null || rate < 0 || rate > 100)) {
                  return 'Enter a valid rate between 0-100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstNumberController,
              decoration: const InputDecoration(
                labelText: 'GST Number (GSTIN)',
                hintText: 'e.g., 22AAAAA0000A1Z5',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Free Shipping'),
              subtitle: const Text('Free shipping above threshold'),
              value: _enableFreeShipping,
              onChanged: (value) => setState(() => _enableFreeShipping = value),
              activeColor: AppTheme.primaryGold,
            ),
            const Divider(),
            TextFormField(
              controller: _freeShippingThresholdController,
              decoration: const InputDecoration(
                labelText: 'Free Shipping Threshold',
                hintText: 'Minimum order for free shipping',
                prefixIcon: Icon(Icons.shopping_cart),
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_enableFreeShipping && (value == null || value.isEmpty)) {
                  return 'Please enter threshold amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shippingCostController,
              decoration: const InputDecoration(
                labelText: 'Standard Shipping Cost',
                hintText: 'Cost when free shipping not applicable',
                prefixIcon: Icon(Icons.delivery_dining),
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter shipping cost';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Cash on Delivery'),
              subtitle: const Text('Allow COD payment option'),
              value: _enableCod,
              onChanged: (value) => setState(() => _enableCod = value),
              activeColor: AppTheme.primaryGold,
            ),
            const Divider(),
            TextFormField(
              controller: _codChargeController,
              decoration: const InputDecoration(
                labelText: 'COD Extra Charge',
                hintText: 'Additional charge for COD (0 for none)',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codMaxAmountController,
              decoration: const InputDecoration(
                labelText: 'COD Maximum Amount',
                hintText: 'Max order value for COD',
                prefixIcon: Icon(Icons.money_off),
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_enableCod && (value == null || value.isEmpty)) {
                  return 'Please enter max COD amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Store Name',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter store name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storeEmailController,
              decoration: const InputDecoration(
                labelText: 'Store Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storePhoneController,
              decoration: const InputDecoration(
                labelText: 'Store Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storeAddressController,
              decoration: const InputDecoration(
                labelText: 'Store Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency Code',
                      hintText: 'e.g., INR, USD',
                      prefixIcon: Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _currencySymbolController,
                    decoration: const InputDecoration(
                      labelText: 'Currency Symbol',
                      hintText: 'e.g., \u20B9, \$',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
