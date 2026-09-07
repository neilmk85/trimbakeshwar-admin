import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/admin_data_service.dart';
import '../l10n/tr.dart';

enum _PricingMode { perRoom, perPerson }

class AccommodationScreen extends StatefulWidget {
  const AccommodationScreen({super.key});

  @override
  State<AccommodationScreen> createState() => _AccommodationScreenState();
}

class _AccommodationScreenState extends State<AccommodationScreen> {
  final _roomsCtrl = TextEditingController();
  final _personsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  _PricingMode _pricingMode = _PricingMode.perRoom;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AdminDataService.fetchAccommodation();
    if (mounted) {
      setState(() {
        if (s != null) {
          _roomsCtrl.text = s.totalRooms > 0 ? s.totalRooms.toString() : '';
          _personsCtrl.text = s.personsPerRoom.toString();
          if (s.pricePerPerson > 0) {
            _pricingMode = _PricingMode.perPerson;
            _priceCtrl.text = s.pricePerPerson.toString();
          } else {
            _pricingMode = _PricingMode.perRoom;
            _priceCtrl.text =
                s.pricePerRoom > 0 ? s.pricePerRoom.toString() : '';
          }
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final rooms = int.tryParse(_roomsCtrl.text.trim()) ?? 0;
    final persons = int.tryParse(_personsCtrl.text.trim());
    if (persons == null || persons < 1) {
      _snack(tr('Please enter a valid persons per room value',
          'कृपया प्रति कमरा व्यक्तियों की सही संख्या डालें'));
      return;
    }
    final price = rooms > 0 ? (int.tryParse(_priceCtrl.text.trim()) ?? 0) : 0;
    if (rooms > 0 && price == 0) {
      _snack(tr('Please enter a price', 'कृपया कीमत डालें'));
      return;
    }

    setState(() => _saving = true);
    final error = await AdminDataService.updateAccommodation(
      totalRooms: rooms,
      personsPerRoom: persons,
      pricePerRoom:
          rooms > 0 && _pricingMode == _PricingMode.perRoom ? price : 0,
      pricePerPerson:
          rooms > 0 && _pricingMode == _PricingMode.perPerson ? price : 0,
    );
    if (mounted) {
      setState(() => _saving = false);
      _snack(error ?? tr('Accommodation settings saved', 'आवास सेटिंग्स सेव हो गईं'));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _roomsCtrl.dispose();
    _personsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _roomsSet => (int.tryParse(_roomsCtrl.text.trim()) ?? 0) > 0;

  String _ratePreview() {
    final rooms = int.tryParse(_roomsCtrl.text.trim()) ?? 0;
    final persons = int.tryParse(_personsCtrl.text.trim()) ?? 0;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (rooms == 0 || persons == 0 || price == 0) return '';
    final ratePerRoom = _pricingMode == _PricingMode.perRoom
        ? price
        : persons * price;
    final total = ratePerRoom * rooms;
    return tr('₹$ratePerRoom / room / night  ·  ₹$total total / night',
        '₹$ratePerRoom / कमरा / रात  ·  ₹$total कुल / रात');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader(tr('Room Configuration', 'कमरा कॉन्फ़िगरेशन')),
        const SizedBox(height: 12),
        _field(
            _roomsCtrl,
            tr('Total Rooms Available', 'उपलब्ध कुल कमरे'),
            Icons.meeting_room_rounded,
            numeric: true,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 4),
        _hint(tr('Set to 0 to disable accommodation booking.',
            'आवास बुकिंग बंद करने के लिए 0 डालें।')),
        const SizedBox(height: 12),
        _field(_personsCtrl, tr('Persons per Room', 'प्रति कमरा व्यक्ति'),
            Icons.people_rounded,
            numeric: true),
        const SizedBox(height: 4),
        _hint(tr('Maximum occupancy per room.', 'प्रति कमरा अधिकतम व्यक्ति।')),
        const SizedBox(height: 24),

        Opacity(
          opacity: _roomsSet ? 1.0 : 0.4,
          child: AbsorbPointer(
            absorbing: !_roomsSet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(tr('Pricing (per night)', 'कीमत (प्रति रात)')),
                const SizedBox(height: 12),

                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AdminColors.grey300.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _toggleBtn(tr('Per Room', 'प्रति कमरा'),
                          _PricingMode.perRoom, Icons.bed_rounded),
                      _toggleBtn(tr('Per Person', 'प्रति व्यक्ति'),
                          _PricingMode.perPerson, Icons.person_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _field(
                  _priceCtrl,
                  _pricingMode == _PricingMode.perRoom
                      ? tr('Price per Room (₹)', 'प्रति कमरा कीमत (₹)')
                      : tr('Price per Person (₹)', 'प्रति व्यक्ति कीमत (₹)'),
                  _pricingMode == _PricingMode.perRoom
                      ? Icons.bed_rounded
                      : Icons.person_rounded,
                  numeric: true,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (_ratePreview().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AdminColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AdminColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate_rounded,
                    size: 16, color: AdminColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ratePreview(),
                    style: TextStyle(
                        fontSize: 12,
                        color: AdminColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(tr('Save Settings', 'सेटिंग्स सेव करें'),
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _toggleBtn(String label, _PricingMode mode, IconData icon) {
    final selected = _pricingMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _pricingMode = mode;
          _priceCtrl.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? AdminColors.primary : AdminColors.grey500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AdminColors.primary : AdminColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AdminColors.grey600,
            letterSpacing: 0.6),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: TextStyle(fontSize: 11, color: AdminColors.grey500)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool numeric = false,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
            numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AdminColors.primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AdminColors.primary, width: 1.5),
          ),
        ),
      );
}
