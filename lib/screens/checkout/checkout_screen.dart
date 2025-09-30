import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/theme.dart';
import '../../models/user.dart';
import '../orders/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'razorpay';
  Address? _selectedAddress;

  final _addressFormKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primaryGold,
              ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                if (details.stepIndex < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continue'),
                  ),
                if (details.stepIndex == 2)
                  ElevatedButton(
                    onPressed: orderProvider.isLoading
                        ? null
                        : () => _placeOrder(context),
                    child: orderProvider.isLoading
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
                        : const Text('Place Order'),
                  ),
                const SizedBox(width: 8),
                if (details.stepIndex > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Shipping Address'),
              content: _buildAddressStep(authProvider),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Payment Method'),
              content: _buildPaymentStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Order Review'),
              content: _buildReviewStep(cartProvider),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressStep(AuthProvider authProvider) {
    final user = authProvider.user;
    final addresses = user?.addresses ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (addresses.isNotEmpty) ...[
          Text(
            'Saved Addresses',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...addresses.map((address) => _buildAddressCard(address)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
        Text(
          'Add New Address',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _addressFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter ZIP code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        enabled: false,
                      ),
                      controller: TextEditingController(text: 'India'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddress?.id == address.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppTheme.primaryGold.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = address;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.primaryGold : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${address.street}, ${address.city}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${address.state}, ${address.zipCode}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (address.isDefault)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        _buildPaymentOption(
          'razorpay',
          'Credit/Debit Card',
          Icons.credit_card,
          'Secure payment via Razorpay',
        ),
        _buildPaymentOption(
          'upi',
          'UPI Payment',
          Icons.phone_android,
          'Pay using UPI apps',
        ),
        _buildPaymentOption(
          'wallet',
          'Digital Wallet',
          Icons.account_balance_wallet,
          'PayTM, PhonePe, Google Pay',
        ),
        _buildPaymentOption(
          'cod',
          'Cash on Delivery',
          Icons.local_shipping,
          'Pay when you receive',
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppTheme.primaryGold.withOpacity(0.1) : null,
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
          });
        },
        activeColor: AppTheme.primaryGold,
        title: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGold : Colors.grey),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildReviewStep(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ...cartProvider.items.map((item) => _buildOrderItem(item)),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildSummaryRow('Subtotal', '₹${cartProvider.subtotal.toStringAsFixed(0)}'),
        if (cartProvider.discount > 0)
          _buildSummaryRow(
            'Discount',
            '-₹${cartProvider.discount.toStringAsFixed(0)}',
            color: AppTheme.successGreen,
          ),
        _buildSummaryRow('Tax (GST)', '₹${cartProvider.tax.toStringAsFixed(0)}'),
        _buildSummaryRow('Shipping', cartProvider.shipping == 0
            ? 'FREE'
            : '₹${cartProvider.shipping.toStringAsFixed(0)}'),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '₹${cartProvider.total.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItem(item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.images.first,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (_selectedAddress == null && !_addressFormKey.currentState!.validate()) {
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    try {
      final shippingAddress = _selectedAddress ??
          Address(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            street: _streetController.text,
            city: _cityController.text,
            state: _stateController.text,
            zipCode: _zipController.text,
            country: 'India',
          );

      await orderProvider.placeOrder(
        userId: authProvider.user!.id,
        items: cartProvider.items,
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
        subtotal: cartProvider.subtotal,
        tax: cartProvider.tax,
        shipping: cartProvider.shipping,
        discount: cartProvider.discount,
        total: cartProvider.total,
      );

      cartProvider.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(
              order: orderProvider.currentOrder!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}