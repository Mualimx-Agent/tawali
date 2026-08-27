import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  const CheckoutScreen({super.key, required this.restaurantId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final List<UserAddress> _addresses = [
    UserAddress(
      id: 'a1', label: 'منزل', street: 'شارع النيل',
      district: 'الرياض', city: 'الخرطوم',
      lat: 15.5007, lng: 32.5599, isDefault: true,
    ),
  ];

  int _selectedAddressIndex = 0;
  String _paymentMethod = AppConstants.paymentCOD;
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromo;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رمز ترويجي')),
      );
      return;
    }
    setState(() {
      _appliedPromo = code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.promoApplied)),
    );
  }

  void _placeOrder() async {
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة عنوان التوصيل')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
      );
      return;
    }

    if (cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة')),
      );
      return;
    }

    final addr = _addresses[_selectedAddressIndex];
    final now = DateTime.now();

    final order = OrderModel(
      id: '',
      orderNumber: 'TW-${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}-${now.millisecondsSinceEpoch.toString().substring(7)}',
      userId: user.id,
      restaurantId: widget.restaurantId,
      items: cartProvider.cartItems.map((ci) => OrderItem(
        menuItemId: ci.item.id,
        nameAr: ci.item.nameAr,
        quantity: ci.quantity,
        price: ci.item.price,
        subtotal: ci.item.price * ci.quantity,
      )).toList(),
      subtotal: cartProvider.subtotal,
      deliveryFee: cartProvider.deliveryFee,
      serviceFee: 0,
      total: cartProvider.subtotal + cartProvider.deliveryFee,
      paymentMethod: _paymentMethod,
      paymentStatus: 'pending',
      orderStatus: 'pending',
      deliveryAddress: OrderAddress(
        street: addr.street,
        district: addr.district,
        city: addr.city,
        lat: addr.lat,
        lng: addr.lng,
        notes: '',
      ),
      customerPhone: user.phone,
      customerName: user.name,
    );

    final savedOrder = await orderProvider.placeOrder(order);
    if (savedOrder != null && mounted) {
      cartProvider.clear();
      context.go('/order_tracking', extra: {
        'orderId': savedOrder.id,
        'orderNumber': savedOrder.orderNumber,
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error ?? 'Fehler beim Aufgeben der Bestellung')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkout)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAddressSection(),
            const SizedBox(height: 16),
            _buildPaymentSection(),
            const SizedBox(height: 16),
            _buildPromoSection(),
            const SizedBox(height: 16),
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildPlaceOrderButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- Address section ----
  Widget _buildAddressSection() {
    return _SectionCard(
      title: AppStrings.deliveryAddress,
      child: Column(
        children: [
          if (_addresses.isNotEmpty)
            ...List.generate(_addresses.length, (index) {
              final addr = _addresses[index];
              return _AddressTile(
                address: addr,
                isSelected: _selectedAddressIndex == index,
                onTap: () => setState(() => _selectedAddressIndex = index),
              );
            }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/add_address'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.addAddress),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Payment section ----
  Widget _buildPaymentSection() {
    return _SectionCard(
      title: AppStrings.paymentMethod,
      child: Column(
        children: [
          _PaymentTile(
            icon: Icons.money,
            title: AppStrings.cashOnDelivery,
            isSelected: _paymentMethod == AppConstants.paymentCOD,
            onTap: () => setState(() => _paymentMethod = AppConstants.paymentCOD),
          ),
          const SizedBox(height: 8),
          _PaymentTile(
            icon: Icons.phone_android,
            title: AppStrings.mobileMoney,
            isSelected: _paymentMethod == AppConstants.paymentMobileMoney,
            onTap: () => setState(() => _paymentMethod = AppConstants.paymentMobileMoney),
          ),
        ],
      ),
    );
  }

  // ---- Promo section ----
  Widget _buildPromoSection() {
    return _SectionCard(
      title: AppStrings.promoCode,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: const InputDecoration(
                    hintText: 'أدخل الرمز الترويجي',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _appliedPromo == null ? _applyPromo : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                  ),
                  child: Text(
                    AppStrings.apply,
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          if (_appliedPromo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '$_appliedPromo - خصم 2.0 ج.س',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Order summary ----
  Widget _buildOrderSummary() {
    final cart = context.watch<CartProvider>();
    return _SectionCard(
      title: 'ملخص الطلب',
      child: Column(
        children: [
          _SummaryRow(AppStrings.subtotal, cart.subtotal),
          const SizedBox(height: 6),
          _SummaryRow(AppStrings.deliveryFee, cart.deliveryFee),
          if (_appliedPromo != null) ...[
            const SizedBox(height: 6),
            _SummaryRow('خصم', 2.0, isDiscount: true),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _SummaryRow(AppStrings.total, cart.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    final orderProvider = context.watch<OrderProvider>();
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: orderProvider.isLoading ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: orderProvider.isLoading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(
                AppStrings.placeOrder,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

// ---- Reusable widgets ----

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final UserAddress address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              address.label == 'منزل' ? Icons.home : Icons.business,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${address.street}، ${address.district}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.radio_button_checked, size: 20, color: AppColors.primary)
            else
              const Icon(Icons.radio_button_off, size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isDiscount;

  const _SummaryRow(this.label, this.value, {this.isTotal = false, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '${value.abs().toStringAsFixed(1)} ${AppConstants.defaultCurrencySymbol}',
          style: GoogleFonts.cairo(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDiscount
                ? AppColors.success
                : isTotal
                    ? AppColors.primary
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}