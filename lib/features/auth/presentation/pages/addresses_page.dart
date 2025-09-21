import 'package:flutter/material.dart';
import 'package:sumi/features/auth/models/address_model.dart';
import 'package:sumi/features/auth/services/address_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.profile_my_addresses ?? 'My Addresses'),
        backgroundColor: const Color(0xFF9A46D7),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressForm(context),
        backgroundColor: const Color(0xFF9A46D7),
        tooltip: isRtl ? 'إضافة عنوان' : 'Add Address',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<AddressModel>>(
        stream: AddressService().streamAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Color(0xFF9A46D7), size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRtl ? 'لا توجد عناوين بعد' : 'No addresses yet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1D2833)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRtl ? 'أضف عنوانًا لتسريع عملية الدفع' : 'Add an address to speed up checkout',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF909AA3)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = addresses[index];
              final addressLine = _formatAddress(a);
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          a.isDefault ? Icons.check_circle : Icons.location_on_outlined,
                          color: a.isDefault ? Colors.green : const Color(0xFF9A46D7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.fullName.isNotEmpty ? a.fullName : (isRtl ? 'بدون اسم' : 'No name'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D2833)),
                                  ),
                                ),
                                if (a.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isRtl ? 'افتراضي' : 'Default',
                                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              addressLine,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4C5D6B), height: 1.3),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF909AA3)),
                                const SizedBox(width: 6),
                                Text(a.phoneNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF909AA3))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: isRtl ? 'تعديل' : 'Edit',
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF9A46D7)),
                            onPressed: () => _showAddressForm(context, address: a),
                          ),
                          IconButton(
                            tooltip: a.isDefault ? (isRtl ? 'افتراضي' : 'Default') : (isRtl ? 'تعيين كافتراضي' : 'Set default'),
                            icon: Icon(
                              a.isDefault ? Icons.star : Icons.star_border,
                              color: a.isDefault ? Colors.amber : const Color(0xFF9A46D7),
                            ),
                            onPressed: a.isDefault ? null : () => AddressService().setDefault(a.id),
                          ),
                          IconButton(
                            tooltip: isRtl ? 'حذف' : 'Delete',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(isRtl ? 'حذف العنوان' : 'Delete Address'),
                                  content: Text(isRtl ? 'هل أنت متأكد من حذف هذا العنوان؟' : 'Are you sure you want to delete this address?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isRtl ? 'إلغاء' : 'Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text(isRtl ? 'حذف' : 'Delete')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await AddressService().deleteAddress(a.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddressForm(BuildContext context, {AddressModel? address}) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final fullName = TextEditingController(text: address?.fullName ?? '');
    final phone = TextEditingController(text: address?.phoneNumber ?? '');
    final line1 = TextEditingController(text: address?.addressLine1 ?? '');
    final line2 = TextEditingController(text: address?.addressLine2 ?? '');
    final city = TextEditingController(text: address?.city ?? '');
    final state = TextEditingController(text: address?.state ?? '');
    final postal = TextEditingController(text: address?.postalCode ?? '');
    final country = TextEditingController(text: address?.country ?? '');
    final formKey = GlobalKey<FormState>();
    bool setAsDefault = address?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E9EC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  address == null ? (isRtl ? 'إضافة عنوان' : 'Add Address') : (isRtl ? 'تعديل العنوان' : 'Edit Address'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D2833)),
                ),
                const SizedBox(height: 16),
                _field(isRtl, isRtl ? 'الاسم الكامل' : 'Full name', fullName),
                _field(isRtl, isRtl ? 'رقم الهاتف' : 'Phone', phone, keyboardType: TextInputType.phone),
                _field(isRtl, isRtl ? 'العنوان' : 'Address line 1', line1),
                _field(isRtl, isRtl ? 'العنوان 2 (اختياري)' : 'Address line 2 (optional)', line2, requiredField: false),
                Row(
                  children: [
                    Expanded(child: _field(isRtl, isRtl ? 'المدينة' : 'City', city)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(isRtl, isRtl ? 'المحافظة/الولاية (اختياري)' : 'State/Province (optional)', state, requiredField: false)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _field(isRtl, isRtl ? 'الرمز البريدي (اختياري)' : 'Postal code (optional)', postal, requiredField: false)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(isRtl, isRtl ? 'الدولة' : 'Country', country)),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 24),
                Row(
                  children: [
                    Switch(
                      value: setAsDefault,
                      activeColor: const Color(0xFF9A46D7),
                      onChanged: (v) {
                        setAsDefault = v;
                        // using StatefulBuilder would be overkill; this flag read on save
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRtl ? 'تعيين كعنوان افتراضي' : 'Set as default address',
                        style: const TextStyle(color: Color(0xFF4C5D6B)),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF9A46D7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final model = AddressModel(
                            id: address?.id ?? '',
                            fullName: fullName.text.trim(),
                            phoneNumber: phone.text.trim(),
                            addressLine1: line1.text.trim(),
                            addressLine2: line2.text.trim().isEmpty ? null : line2.text.trim(),
                            city: city.text.trim(),
                            state: state.text.trim().isEmpty ? null : state.text.trim(),
                            postalCode: postal.text.trim().isEmpty ? null : postal.text.trim(),
                            country: country.text.trim(),
                            isDefault: setAsDefault,
                            createdAt: address?.createdAt ?? DateTime.now(),
                          );
                          if (address == null) {
                            final id = await AddressService().addAddress(model);
                            if (setAsDefault && id != null) {
                              await AddressService().setDefault(id);
                            }
                          } else {
                            await AddressService().updateAddress(model);
                            if (setAsDefault) {
                              await AddressService().setDefault(address.id);
                            }
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        },
                        child: Text(isRtl ? 'حفظ' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFE6E9EC)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(isRtl ? 'إلغاء' : 'Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(bool isRtl, String label, TextEditingController c, {TextInputType? keyboardType, bool requiredField = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        validator: requiredField
            ? (v) => (v == null || v.trim().isEmpty)
                ? (isRtl ? 'الحقل مطلوب' : 'Required')
                : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _formatAddress(AddressModel a) {
    final parts = <String>[
      a.addressLine1,
      if ((a.addressLine2 ?? '').isNotEmpty) a.addressLine2!,
      a.city,
      if ((a.state ?? '').isNotEmpty) a.state!,
      if ((a.postalCode ?? '').isNotEmpty) a.postalCode!,
      a.country,
    ];
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }
}


