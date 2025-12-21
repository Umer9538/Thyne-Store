import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/cashfree_service.dart';
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
  String _selectedPaymentMethod = 'cashfree';
  Address? _selectedAddress;
  final CashfreeService _cashfreeService = CashfreeService();
  bool _isProcessingPayment = false;

  final _addressFormKey = GlobalKey<FormState>();
  // Detailed address fields
  final _houseNoFloorController = TextEditingController();
  final _buildingBlockController = TextEditingController();
  final _landmarkAreaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _selectedAddressLabel = 'Home';

  @override
  void dispose() {
    _houseNoFloorController.dispose();
    _buildingBlockController.dispose();
    _landmarkAreaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onStepContinue(int currentStep) {
    if (currentStep == 0) {
      // Validate address step
      if (_selectedAddress == null) {
        // Validate using both form validation AND controller values directly
        final formValid = _addressFormKey.currentState?.validate() ?? false;
        final hasValidControllerValues = _houseNoFloorController.text.trim().isNotEmpty &&
            _buildingBlockController.text.trim().isNotEmpty &&
            _landmarkAreaController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _stateController.text.trim().isNotEmpty &&
            _pincodeController.text.trim().length == 6;

        if (formValid && hasValidControllerValues) {
          setState(() {
            _currentStep = currentStep + 1;
          });
        } else if (!hasValidControllerValues) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all address fields correctly'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // If a saved address is selected, proceed to next step
        setState(() {
          _currentStep = currentStep + 1;
        });
      }
    } else {
      // For other steps, proceed normally
      setState(() {
        _currentStep = currentStep + 1;
      });
    }
  }

  void _onStepCancel(int currentStep) {
    if (currentStep > 0) {
      setState(() {
        _currentStep = currentStep - 1;
      });
    }
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
                    onPressed: () => _onStepContinue(details.stepIndex),
                    child: const Text('Continue'),
                  ),
                if (details.stepIndex == 2)
                  ElevatedButton(
                    onPressed: (orderProvider.isLoading || _isProcessingPayment)
                        ? null
                        : () => _placeOrder(context),
                    child: (orderProvider.isLoading || _isProcessingPayment)
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
                        : const Text('Pay & Place Order'),
                  ),
                const SizedBox(width: 8),
                if (details.stepIndex > 0)
                  OutlinedButton(
                    onPressed: () => _onStepCancel(details.stepIndex),
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
              // House No. & Floor
              TextFormField(
                controller: _houseNoFloorController,
                decoration: const InputDecoration(
                  labelText: 'House No. & Floor *',
                  hintText: 'e.g., 12A, 3rd Floor',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter house no. & floor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Building & Block Number
              TextFormField(
                controller: _buildingBlockController,
                decoration: const InputDecoration(
                  labelText: 'Building & Block Number *',
                  hintText: 'e.g., Tower B, Block 5',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter building & block number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Landmark & Area
              TextFormField(
                controller: _landmarkAreaController,
                decoration: const InputDecoration(
                  labelText: 'Landmark & Area *',
                  hintText: 'e.g., Near City Mall, Sector 18',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter landmark & area';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City & State Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pincode & Country Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode *',
                        prefixIcon: Icon(Icons.pin_drop_outlined),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter pincode';
                        }
                        if (value.length != 6) {
                          return 'Invalid pincode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.flag_outlined),
                        enabled: false,
                      ),
                      controller: TextEditingController(text: 'India'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address Label
              DropdownButtonFormField<String>(
                value: _selectedAddressLabel,
                decoration: const InputDecoration(
                  labelText: 'Address Label *',
                  prefixIcon: Icon(Icons.label_outlined),
                ),
                items: ['Home', 'Work', 'Other'].map((label) {
                  return DropdownMenuItem(
                    value: label,
                    child: Row(
                      children: [
                        Icon(
                          label == 'Home'
                              ? Icons.home
                              : label == 'Work'
                                  ? Icons.work
                                  : Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAddressLabel = value ?? 'Home';
                  });
                },
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
                      address.shortAddress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${address.state}, ${address.pincode}',
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
          'cashfree',
          'Card / UPI / Netbanking / Wallets',
          Icons.payment,
          'Pay securely with Cashfree',
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
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
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
            Flexible(
              child: Text(
                'Total',
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
    // Get image URL safely
    final imageUrl = item.product.images.isNotEmpty ? item.product.images.first : '';
    final hasValidImage = imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAbsolutePath == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasValidImage
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.diamond_outlined, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.diamond_outlined, color: Colors.grey),
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
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (item.hasSalePrice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.discountPercent ?? 0}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.totalPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: item.hasSalePrice ? Colors.green.shade700 : null,
                    ),
              ),
              if (item.hasSalePrice)
                Text(
                  '₹${((item.originalPrice ?? item.product.price) * item.quantity).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                ),
            ],
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
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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

    // Validate address - check both form validation and controller values directly
    if (_selectedAddress == null) {
      // Check controller values directly (more reliable than form validation when form is not visible)
      final hasValidAddress = _houseNoFloorController.text.trim().isNotEmpty &&
          _buildingBlockController.text.trim().isNotEmpty &&
          _landmarkAreaController.text.trim().isNotEmpty &&
          _cityController.text.trim().isNotEmpty &&
          _stateController.text.trim().isNotEmpty &&
          _pincodeController.text.trim().length == 6;

      if (!hasValidAddress) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all address fields correctly'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _currentStep = 0;
        });
        return;
      }
    }

    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Convert address label string to enum
      AddressLabel addressLabel;
      switch (_selectedAddressLabel) {
        case 'Home':
          addressLabel = AddressLabel.home;
          break;
        case 'Work':
          addressLabel = AddressLabel.work;
          break;
        default:
          addressLabel = AddressLabel.other;
      }

      final shippingAddress = _selectedAddress ??
          Address(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            houseNoFloor: _houseNoFloorController.text.trim(),
            buildingBlock: _buildingBlockController.text.trim(),
            landmarkArea: _landmarkAreaController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            country: 'India',
            label: addressLabel,
          );

      // Ensure user is authenticated before placing order
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to place an order'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessingPayment = false;
        });
        return;
      }

      // Step 1: Create order in backend (status: pending)
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

      final order = orderProvider.currentOrder;
      if (order == null) {
        throw Exception('Failed to create order');
      }

      // Step 2: Create Cashfree payment order
      // Add timestamp to make order ID unique (Cashfree requires unique order IDs)
      final paymentOrderId = '${order.id}_${DateTime.now().millisecondsSinceEpoch}';
      final cashfreeOrder = await _cashfreeService.createPaymentOrder(
        orderId: paymentOrderId,
        amount: cartProvider.total,
        customerPhone: authProvider.user!.phone ?? '9999999999',
        customerEmail: authProvider.user!.email,
        customerName: authProvider.user!.name,
      );

      if (cashfreeOrder == null) {
        throw Exception('Failed to create payment order');
      }

      // Step 3: Get environment (SANDBOX or PRODUCTION)
      final environment = await _cashfreeService.getEnvironment();

      // Step 4: Start Cashfree payment
      if (!mounted) return;

      // Use browser-based checkout for development (bypasses Play Store trust check)
      final browserLaunched = await _cashfreeService.startPaymentInBrowser(
        paymentSessionId: cashfreeOrder.paymentSessionId,
        environment: environment,
      );

      if (browserLaunched && mounted) {
        // Show dialog to verify payment after user returns from browser
        final shouldVerify = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Complete Payment'),
            content: const Text(
              'Complete your payment in the browser.\n\n'
              'After payment, tap "Verify Payment" to confirm your order.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Verify Payment'),
              ),
            ],
          ),
        );

        if (shouldVerify == true && mounted) {
          // Verify payment
          final verifyResponse = await _cashfreeService.verifyPayment(cashfreeOrder.orderId);

          if (verifyResponse?.success == true) {
            // Payment successful - clear cart and navigate
            cartProvider.clearCart();

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderSuccessScreen(
                    order: order,
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(verifyResponse?.message ?? 'Payment not completed or verification failed'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
        }
      } else {
        // Browser launch failed, try SDK as fallback
        await _cashfreeService.startPayment(
          context: context,
          orderId: cashfreeOrder.orderId,
          paymentSessionId: cashfreeOrder.paymentSessionId,
          environment: environment,
          onSuccess: (paymentOrderId) async {
            final verifyResponse = await _cashfreeService.verifyPayment(paymentOrderId);

            if (verifyResponse?.success == true) {
              cartProvider.clearCart();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderSuccessScreen(
                      order: order,
                    ),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(verifyResponse?.message ?? 'Payment verification failed'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }

            if (mounted) {
              setState(() {
                _isProcessingPayment = false;
              });
            }
          },
          onFailure: (CFErrorResponse error, String orderId) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment failed: ${error.getMessage()}'),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
              setState(() {
                _isProcessingPayment = false;
              });
            }
          },
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
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }
}