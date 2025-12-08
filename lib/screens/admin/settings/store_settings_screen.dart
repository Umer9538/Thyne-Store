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

  // Order ID Settings
  late TextEditingController _orderIdPrefixController;
  late TextEditingController _orderIdCounterController;

  // Product Customization Options
  List<MetalOption> _metalOptions = [];
  List<String> _platingColors = [];
  List<String> _stoneShapes = [];
  late TextEditingController _maxEngravingCharsController;

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
    _orderIdPrefixController = TextEditingController(text: 'TJ');
    _orderIdCounterController = TextEditingController(text: '1000');
    _maxEngravingCharsController = TextEditingController(text: '15');
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
        _orderIdPrefixController.text = settings.orderIdPrefix;
        _orderIdCounterController.text = settings.orderIdCounter.toString();
        _metalOptions = List.from(settings.metalOptions);
        _platingColors = List.from(settings.platingColors);
        _stoneShapes = List.from(settings.stoneShapes);
        _maxEngravingCharsController.text = settings.maxEngravingChars.toString();
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
    _orderIdPrefixController.dispose();
    _orderIdCounterController.dispose();
    _maxEngravingCharsController.dispose();
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
      orderIdPrefix: _orderIdPrefixController.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''),
      orderIdCounter: int.tryParse(_orderIdCounterController.text) ?? 1000,
      metalOptions: _metalOptions,
      platingColors: _platingColors,
      stoneShapes: _stoneShapes,
      maxEngravingChars: int.tryParse(_maxEngravingCharsController.text) ?? 15,
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
                _buildSectionHeader('Order ID Settings', Icons.confirmation_number),
                _buildOrderIdSection(),
                const SizedBox(height: 24),
                _buildSectionHeader('Product Customization Options', Icons.diamond),
                _buildCustomizationSection(),
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

  Widget _buildOrderIdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order IDs will be generated as: PREFIX + NUMBER (e.g., TJ1001)',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderIdPrefixController,
              decoration: const InputDecoration(
                labelText: 'Order ID Prefix',
                hintText: 'e.g., TJ, ORD, INV',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
                helperText: 'Only letters and numbers allowed (2-5 characters)',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a prefix';
                }
                final cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                if (cleaned.length < 2 || cleaned.length > 5) {
                  return 'Prefix must be 2-5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderIdCounterController,
              decoration: const InputDecoration(
                labelText: 'Current Order Counter',
                hintText: 'Next order number',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
                helperText: 'The next order will use this number',
              ),
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing the prefix will NOT reset the counter. This prevents duplicate order IDs.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
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

  Widget _buildCustomizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These options will be available when adding/editing products and shown to customers on product pages.',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metal Options Section
            _buildSubsectionHeader('Metal Types', Icons.colorize),
            const SizedBox(height: 8),
            _buildMetalOptionsEditor(),
            const SizedBox(height: 20),

            // Plating Colors Section
            _buildSubsectionHeader('Plating Colors', Icons.palette),
            const SizedBox(height: 8),
            _buildChipListEditor(
              items: _platingColors,
              hintText: 'Add plating color (e.g., Rose Gold)',
              onAdd: (value) {
                if (value.isNotEmpty && !_platingColors.contains(value)) {
                  setState(() => _platingColors.add(value));
                }
              },
              onRemove: (index) {
                setState(() => _platingColors.removeAt(index));
              },
            ),
            const SizedBox(height: 20),

            // Stone Shapes Section
            _buildSubsectionHeader('Stone Shapes', Icons.diamond),
            const SizedBox(height: 8),
            _buildChipListEditor(
              items: _stoneShapes,
              hintText: 'Add stone shape (e.g., Oval)',
              onAdd: (value) {
                if (value.isNotEmpty && !_stoneShapes.contains(value)) {
                  setState(() => _stoneShapes.add(value));
                }
              },
              onRemove: (index) {
                setState(() => _stoneShapes.removeAt(index));
              },
            ),
            const SizedBox(height: 20),

            // Max Engraving Characters
            _buildSubsectionHeader('Engraving Settings', Icons.edit),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxEngravingCharsController,
              decoration: const InputDecoration(
                labelText: 'Max Engraving Characters',
                hintText: 'Default: 15',
                prefixIcon: Icon(Icons.short_text),
                border: OutlineInputBorder(),
                helperText: 'Maximum characters allowed for product engravings',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final chars = int.tryParse(value ?? '');
                if (chars == null || chars < 1 || chars > 50) {
                  return 'Enter a value between 1-50';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildMetalOptionsEditor() {
    return Column(
      children: [
        // List of metal types
        ..._metalOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final metal = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metal.type,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      onPressed: () {
                        setState(() => _metalOptions.removeAt(index));
                      },
                      tooltip: 'Remove ${metal.type}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...metal.variants.map((variant) => Chip(
                      label: Text(variant, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          final newVariants = List<String>.from(metal.variants);
                          newVariants.remove(variant);
                          if (newVariants.isEmpty) {
                            _metalOptions.removeAt(index);
                          } else {
                            _metalOptions[index] = MetalOption(
                              type: metal.type,
                              variants: newVariants,
                            );
                          }
                        });
                      },
                    )),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Add Variant', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showAddVariantDialog(index),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        // Add new metal type button
        OutlinedButton.icon(
          onPressed: _showAddMetalDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Metal Type'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildChipListEditor({
    required List<String> items,
    required String hintText,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...items.asMap().entries.map((entry) => Chip(
              label: Text(entry.value),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => onRemove(entry.key),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (value) {
                  onAdd(value.trim());
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppTheme.primaryGold,
              onPressed: () {
                onAdd(controller.text.trim());
                controller.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showAddMetalDialog() {
    final typeController = TextEditingController();
    final variantController = TextEditingController();
    List<String> variants = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Metal Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Metal Type',
                  hintText: 'e.g., Gold, Silver, Platinum',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Variants (e.g., 9K, 14K, 22K):', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: variants.map((v) => Chip(
                  label: Text(v),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setDialogState(() => variants.remove(v)),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: variantController,
                      decoration: const InputDecoration(
                        hintText: 'Add variant',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setDialogState(() {
                            variants.add(value.trim());
                            variantController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (variantController.text.trim().isNotEmpty) {
                        setDialogState(() {
                          variants.add(variantController.text.trim());
                          variantController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (typeController.text.trim().isNotEmpty && variants.isNotEmpty) {
                  setState(() {
                    _metalOptions.add(MetalOption(
                      type: typeController.text.trim(),
                      variants: variants,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVariantDialog(int metalIndex) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Variant to ${_metalOptions[metalIndex].type}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Variant',
            hintText: 'e.g., 14K, 18K',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final metal = _metalOptions[metalIndex];
                  final newVariants = List<String>.from(metal.variants);
                  newVariants.add(controller.text.trim());
                  _metalOptions[metalIndex] = MetalOption(
                    type: metal.type,
                    variants: newVariants,
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
