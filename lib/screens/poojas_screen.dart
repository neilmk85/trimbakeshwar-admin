import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../l10n/tr.dart';
import 'edit_pooja_screen.dart';

// ── Preset colors for new poojas ─────────────────────────────────────────────

const _kColorOptions = [
  // Whites & Greys
  Color(0xFFFFFFFF), Color(0xFFF5F5F5), Color(0xFF9E9E9E), Color(0xFF424242),
  Color(0xFF000000),
  // Primary & Warm
  Color(0xFFF44336), Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7),
  Color(0xFF3F51B5), Color(0xFF2196F3), Color(0xFF03A9F4), Color(0xFF00BCD4),
  // Greens & Teals
  Color(0xFF009688), Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
  // Yellows, Oranges, Browns
  Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFFF5722),
  Color(0xFF795548), Color(0xFF607D8B),
  // Deep tones
  Color(0xFF1565C0), Color(0xFF4527A0), Color(0xFF2E7D32), Color(0xFFC62828),
  Color(0xFF6A1B9A), Color(0xFF00695C),
];

const _kColorHexes = [
  // Whites & Greys
  '#FFFFFF', '#F5F5F5', '#9E9E9E', '#424242', '#000000',
  // Primary & Warm
  '#F44336', '#E91E63', '#9C27B0', '#673AB7',
  '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
  // Greens & Teals
  '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
  // Yellows, Oranges, Browns
  '#FFEB3B', '#FFC107', '#FF9800', '#FF5722',
  '#795548', '#607D8B',
  // Deep tones
  '#1565C0', '#4527A0', '#2E7D32', '#C62828',
  '#6A1B9A', '#00695C',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PoojasScreen extends StatelessWidget {
  const PoojasScreen({super.key});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddPoojaSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E35B1).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: ValueListenableBuilder<AdminData>(
        valueListenable: AdminDataService.dataNotifier,
        builder: (_, data, __) {
          if (data.poojas.isEmpty) {
            return Center(
              child: Text(
                tr('Loading poojas...', 'पूजाएं लोड हो रही हैं...', 'पूजा लोड होत आहेत...'),
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: data.poojas.length,
            itemBuilder: (ctx, i) => _PoojaCard(pooja: data.poojas[i]),
          );
        },
      ),
    );
  }
}

// ── Pooja card ────────────────────────────────────────────────────────────────

class _PoojaCard extends StatelessWidget {
  final AdminPooja pooja;
  const _PoojaCard({required this.pooja});

  @override
  Widget build(BuildContext context) {
    final color = pooja.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: pooja.enabled ? color : AdminColors.grey300,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'ॐ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pooja.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: pooja.enabled ? color : AdminColors.grey500,
                        ),
                      ),
                      Text(
                        tr('₹${pooja.pricePerPerson} per person',
                            '₹${pooja.pricePerPerson} प्रति व्यक्ति',
                            '₹${pooja.pricePerPerson} प्रति व्यक्ती'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pooja.enabled
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: pooja.enabled
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    pooja.enabled
                        ? tr('Active', 'सक्रिय', 'सक्रिय')
                        : tr('Disabled', 'निष्क्रिय', 'निष्क्रिय'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pooja.enabled
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AdminColors.primary,
                  ),
                  tooltip: tr('Edit', 'संपादित करें', 'संपादित करा'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPoojaScreen(pooja: pooja),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Description
          if (pooja.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                pooja.description,
                style: TextStyle(
                  fontSize: 13,
                  color: AdminColors.grey600,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add sheet ─────────────────────────────────────────────────────────────────

class _AddPoojaSheet extends StatefulWidget {
  const _AddPoojaSheet();

  @override
  State<_AddPoojaSheet> createState() => _AddPoojaSheetState();
}

class _AddPoojaSheetState extends State<_AddPoojaSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _displayOrderCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();

  // Dynamic list fields
  final List<TextEditingController> _beforeCtrls = [TextEditingController()];
  final List<TextEditingController> _afterCtrls = [TextEditingController()];
  final List<TextEditingController> _bringCtrls = [TextEditingController()];

  bool _enabled = true;
  int _colorIndex = 0;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _priceCtrl,
      _iconCtrl,
      _durationCtrl,
      _displayOrderCtrl,
      _infoCtrl,
      ..._beforeCtrls,
      ..._afterCtrls,
      ..._bringCtrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _listValues(List<TextEditingController> ctrls) =>
      ctrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty) {
      _snack(tr('Pooja name is required', 'पूजा का नाम आवश्यक है', 'पूजेचे नाव आवश्यक आहे'));
      return;
    }
    if (price == null || price <= 0) {
      _snack(tr('Please enter a valid price', 'कृपया सही राशि दर्ज करें', 'कृपया योग्य रक्कम टाका'));
      return;
    }

    setState(() => _saving = true);
    final error = await AdminDataService.createPooja(
      name: name,
      description: _descCtrl.text.trim(),
      pricePerPerson: price,
      colorHex: _kColorHexes[_colorIndex],
      enabled: _enabled,
      iconName: _iconCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      displayOrder: int.tryParse(_displayOrderCtrl.text.trim()),
      info: _infoCtrl.text.trim(),
      beforeInstructions: _listValues(_beforeCtrls),
      afterInstructions: _listValues(_afterCtrls),
      thingsToBring: _listValues(_bringCtrls),
    );
    if (mounted) {
      setState(() => _saving = false);
      if (error != null) {
        _snack(error);
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('Pooja created successfully',
                  'पूजा सफलतापूर्वक बनाई गई', 'पूजा यशस्वीरित्या तयार झाली'))),
        );
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Fixed header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _handle(),
                const SizedBox(height: 16),
                Text(
                  tr('New Pooja', 'नई पूजा', 'नवीन पूजा'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Divider(height: 24),
              ],
            ),
          ),
          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              children: [
                _sectionHeader(tr('Basic Info', 'बुनियादी जानकारी', 'मूलभूत माहिती')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    tr('Pooja Name *', 'पूजा का नाम *', 'पूजेचे नाव *'),
                    Icons.auto_awesome_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    tr('Short Description', 'संक्षिप्त विवरण', 'संक्षिप्त वर्णन'),
                    Icons.short_text_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          tr('Price per Person (₹) *', 'प्रति व्यक्ति कीमत (₹) *', 'प्रति व्यक्ती किंमत (₹) *'),
                          Icons.currency_rupee_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _displayOrderCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          tr('Display Order', 'प्रदर्शन क्रम', 'प्रदर्शन क्रम'),
                          Icons.sort_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationCtrl,
                        decoration: _inputDecoration(
                          tr('Duration (e.g. 1 Day)', 'अवधि (जैसे 1 दिन)', 'कालावधी (उदा. 1 दिवस)'),
                          Icons.schedule_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _iconCtrl,
                        decoration: _inputDecoration(
                          tr('Icon Name', 'आइकन का नाम', 'आयकनचे नाव'),
                          Icons.insert_emoticon_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _sectionHeader(tr('Color', 'रंग', 'रंग')),
                const SizedBox(height: 12),
                _colorPicker(),
                const SizedBox(height: 20),

                _sectionHeader(tr('Detailed Info', 'विस्तृत जानकारी', 'सविस्तर माहिती')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _infoCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    tr('Full description / info', 'पूरा विवरण / जानकारी', 'संपूर्ण वर्णन / माहिती'),
                    Icons.info_outline_rounded,
                  ),
                ),
                const SizedBox(height: 20),

                _sectionHeader(tr('Before Instructions', 'पहले की सूचनाएं', 'आधीच्या सूचना')),
                const SizedBox(height: 8),
                _dynamicList(
                  _beforeCtrls,
                  hint: tr('e.g. Take a holy bath before arriving',
                      'जैसे आने से पहले पवित्र स्नान करें',
                      'उदा. येण्यापूर्वी पवित्र स्नान करा'),
                ),
                const SizedBox(height: 20),

                _sectionHeader(tr('After Instructions', 'बाद की सूचनाएं', 'नंतरच्या सूचना')),
                const SizedBox(height: 8),
                _dynamicList(
                  _afterCtrls,
                  hint: tr('e.g. Maintain celibacy for 3 days',
                      'जैसे 3 दिन ब्रह्मचर्य का पालन करें',
                      'उदा. 3 दिवस ब्रह्मचर्य पाळा'),
                ),
                const SizedBox(height: 20),

                _sectionHeader(tr('Things to Bring', 'साथ लाने योग्य वस्तुएं', 'सोबत आणायच्या वस्तू')),
                const SizedBox(height: 8),
                _dynamicList(_bringCtrls,
                    hint: tr('e.g. White dhoti and saree',
                        'जैसे सफ़ेद धोती और साड़ी',
                        'उदा. पांढरी धोती आणि साडी')),
                const SizedBox(height: 20),

                _statusToggle(),
                const SizedBox(height: 24),
                _submitButton(tr('Create Pooja', 'पूजा बनाएं', 'पूजा तयार करा'), _saving, _save),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AdminColors.grey600,
      letterSpacing: 0.6,
    ),
  );

  Widget _colorPicker() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: List.generate(_kColorOptions.length, (i) {
      final selected = _colorIndex == i;
      return GestureDetector(
        onTap: () => setState(() => _colorIndex = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kColorOptions[i],
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: _kColorOptions[i].computeLuminance() > 0.6
                        ? Colors.black54
                        : Colors.white,
                    width: 3,
                  )
                : Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kColorOptions[i].withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  color: _kColorOptions[i].computeLuminance() > 0.6
                      ? Colors.black87
                      : Colors.white,
                  size: 18,
                )
              : null,
        ),
      );
    }),
  );

  Widget _dynamicList(
    List<TextEditingController> ctrls, {
    required String hint,
  }) {
    return Column(
      children: [
        ...ctrls.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: e.value,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AdminColors.grey400,
                      ),
                      prefixText: '${e.key + 1}.  ',
                      prefixStyle: TextStyle(
                        fontSize: 13,
                        color: AdminColors.grey500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AdminColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AdminColors.grey300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AdminColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (ctrls.length > 1) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() {
                      e.value.dispose();
                      ctrls.removeAt(e.key);
                    }),
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.red.shade300,
                      size: 22,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => ctrls.add(TextEditingController())),
          icon: Icon(Icons.add_rounded, size: 16, color: AdminColors.primary),
          label: Text(
            tr('Add item', 'आइटम जोड़ें', 'आयटम जोडा'),
            style: TextStyle(
              fontSize: 13,
              color: AdminColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          ),
        ),
      ],
    );
  }

  Widget _statusToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AdminColors.grey100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.power_settings_new_rounded,
          size: 20,
          color: _enabled ? Colors.green.shade600 : AdminColors.grey500,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Pooja Status', 'पूजा की स्थिति', 'पूजेची स्थिती'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                _enabled
                    ? tr('Enabled — visible to users',
                        'सक्रिय — उपयोगकर्ताओं को दिखाई देगी',
                        'सक्रिय — ग्राहकांना दिसेल')
                    : tr('Disabled — hidden from users',
                        'निष्क्रिय — उपयोगकर्ताओं से छिपी रहेगी',
                        'निष्क्रिय — ग्राहकांपासून लपलेली राहील'),
                style: TextStyle(fontSize: 12, color: AdminColors.grey600),
              ),
            ],
          ),
        ),
        Switch(
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
          activeColor: AdminColors.primary,
        ),
      ],
    ),
  );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _handle() => Center(
  child: Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AdminColors.grey300,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
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
        borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
      ),
    );

Widget _submitButton(String label, bool saving, VoidCallback onTap) => SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: saving ? null : onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: saving
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
  ),
);
