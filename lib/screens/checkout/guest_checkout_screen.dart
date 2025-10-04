import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/guest_session_provider.dart';
import '../../utils/theme.dart';
import '../../models/user.dart';
import '../orders/order_success_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class GuestCheckoutScreen extends StatefulWidget {
  const GuestCheckoutScreen({super.key});

  @override
  State<GuestCheckoutScreen> createState() => _GuestCheckoutScreenState();
}

class _GuestCheckoutScreenState extends State<GuestCheckoutScreen> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'razorpay';
  String _checkoutOption = 'guest'; // 'guest', 'login', 'register'

  // Guest info form
  final _guestFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  // Address form
  final _addressFormKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register form
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
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
            if (step <= _getMaxAccessibleStep()) {
              setState(() {
                _currentStep = step;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: () => _onStepContinue(_currentStep),
                    child: const Text('Continue'),
                  ),
                if (_currentStep == 2)
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
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => _onStepCancel(_currentStep),
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Account Options'),
              content: _buildAccountOptionsStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Shipping & Payment'),
              content: _buildShippingPaymentStep(),
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

  int _getMaxAccessibleStep() {
    if (_checkoutOption == 'guest' && _guestFormKey.currentState?.validate() == true) {
      return 2;
    } else if ((_checkoutOption == 'login' || _checkoutOption == 'register') &&
        Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
      return 2;
    }
    return _currentStep;
  }

  void _onStepContinue(int currentStep) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (currentStep == 0) {
      // Validate account options step
      if (_checkoutOption == 'guest') {
        if (_guestFormKey.currentState?.validate() ?? false) {
          setState(() {
            _currentStep = currentStep + 1;
          });
        }
      } else if (_checkoutOption == 'login') {
        if (_loginFormKey.currentState?.validate() ?? false) {
          // Perform login logic here if needed
          setState(() {
            _currentStep = currentStep + 1;
          });
        }
      } else if (_checkoutOption == 'register') {
        if (_registerFormKey.currentState?.validate() ?? false) {
          // Perform registration logic here if needed
          setState(() {
            _currentStep = currentStep + 1;
          });
        }
      } else if (authProvider.isAuthenticated) {
        setState(() {
          _currentStep = currentStep + 1;
        });
      }
    } else if (currentStep == 1) {
      // Validate shipping & payment step
      if (_addressFormKey.currentState?.validate() ?? false) {
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

  Widget _buildAccountOptionsStep() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to checkout?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        // Guest Checkout Option
        Card(
          elevation: _checkoutOption == 'guest' ? 3 : 1,
          color: _checkoutOption == 'guest'
              ? AppTheme.primaryGold.withOpacity(0.1)
              : null,
          child: RadioListTile<String>(
            value: 'guest',
            groupValue: _checkoutOption,
            onChanged: (value) {
              setState(() {
                _checkoutOption = value!;
              });
            },
            activeColor: AppTheme.primaryGold,
            title: const Text('Continue as Guest'),
            subtitle: const Text('Quick checkout without creating an account'),
          ),
        ),

        if (_checkoutOption == 'guest') ...[
          const SizedBox(height: 16),
          Form(
            key: _guestFormKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can create an account after placing your order to track future purchases',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Login Option
        Card(
          elevation: _checkoutOption == 'login' ? 3 : 1,
          color: _checkoutOption == 'login'
              ? AppTheme.primaryGold.withOpacity(0.1)
              : null,
          child: RadioListTile<String>(
            value: 'login',
            groupValue: _checkoutOption,
            onChanged: (value) {
              setState(() {
                _checkoutOption = value!;
              });
            },
            activeColor: AppTheme.primaryGold,
            title: const Text('Login to Existing Account'),
            subtitle: const Text('Use saved addresses and track orders'),
          ),
        ),

        if (_checkoutOption == 'login') ...[
          const SizedBox(height: 16),
          Form(
            key: _loginFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            if (_loginFormKey.currentState!.validate()) {
                              await authProvider.loginFromGuest(
                                _loginEmailController.text,
                                _loginPasswordController.text,
                              );
                              if (authProvider.isAuthenticated) {
                                setState(() {
                                  _currentStep = 1;
                                });
                              }
                            }
                          },
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Register Option
        Card(
          elevation: _checkoutOption == 'register' ? 3 : 1,
          color: _checkoutOption == 'register'
              ? AppTheme.primaryGold.withOpacity(0.1)
              : null,
          child: RadioListTile<String>(
            value: 'register',
            groupValue: _checkoutOption,
            onChanged: (value) {
              setState(() {
                _checkoutOption = value!;
              });
            },
            activeColor: AppTheme.primaryGold,
            title: const Text('Create New Account'),
            subtitle: const Text('Save details for faster future checkouts'),
          ),
        ),

        if (_checkoutOption == 'register') ...[
          const SizedBox(height: 16),
          Form(
            key: _registerFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _registerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _registerEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _registerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _registerPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            if (_registerFormKey.currentState!.validate()) {
                              await authProvider.register(
                                name: _registerNameController.text,
                                email: _registerEmailController.text,
                                phone: _registerPhoneController.text,
                                password: _registerPasswordController.text,
                              );
                              if (authProvider.isAuthenticated) {
                                setState(() {
                                  _currentStep = 1;
                                });
                              }
                            }
                          },
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (authProvider.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              authProvider.error!,
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShippingPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Address',
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
                      decoration: InputDecoration(
                        labelText: 'Country',
                        enabled: false,
                      ),
                      controller: _countryController,
                     ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
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
    final guestSessionProvider = Provider.of<GuestSessionProvider>(context, listen: false);

    // Validate forms based on checkout option
    if (_checkoutOption == 'guest') {
      if (!_guestFormKey.currentState!.validate() ||
          !_addressFormKey.currentState!.validate()) {
        setState(() {
          _currentStep = _checkoutOption == 'guest' ? 0 : 1;
        });
        return;
      }

      // Update guest session with order info
      await guestSessionProvider.updateGuestInfo(
        email: _emailController.text,
        phone: _phoneController.text,
        name: _nameController.text,
      );
    } else if (!authProvider.isAuthenticated) {
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    if (!_addressFormKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
      return;
    }

    try {
      final shippingAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        country: 'India',
      );

      String userId;
      if (authProvider.isAuthenticated) {
        userId = authProvider.user!.id;
      } else {
        // Guest order
        userId = guestSessionProvider.guestUser?.sessionId ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      }

      await orderProvider.placeOrder(
        userId: userId,
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