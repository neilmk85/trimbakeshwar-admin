import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import 'edit_pooja_screen.dart';

// ── Preset colors for new poojas ─────────────────────────────────────────────

const _kColorOptions = [
  Color(0xFF1565C0),
  Color(0xFF00838F),
  Color(0xFF4527A0),
  Color(0xFF2E7D32),
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFF00695C),
  Color(0xFF283593),
  Color(0xFF558B2F),
];

const _kColorHexes = [
  '#1565C0', '#00838F', '#4527A0', '#2E7D32',
  '#C62828', '#EF6C00', '#6A1B9A', '#00695C',
  '#283593', '#558B2F',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PoojasScreen extends StatelessWidget {
  const PoojasScreen({super.key});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddPoojaSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Pooja',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ValueListenableBuilder<AdminData>(
        valueListenable: AdminDataService.dataNotifier,
        builder: (_, data, __) {
          if (data.poojas.isEmpty) {
            return const Center(
              child: Text('Loading poojas...',
                  style: TextStyle(color: Colors.grey)),
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
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: pooja.enabled ? 0.12 : 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
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
                    child: Text('ॐ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w300)),
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
                        '₹${pooja.pricePerPerson} per person',
                        style: TextStyle(
                            fontSize: 12,
                            color: pooja.enabled
                                ? color.withValues(alpha: 0.8)
                                : AdminColors.grey400),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pooja.enabled
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: pooja.enabled
                            ? Colors.green.shade200
                            : Colors.red.shade200),
                  ),
                  child: Text(
                    pooja.enabled ? 'Active' : 'Disabled',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pooja.enabled
                            ? Colors.green.shade700
                            : Colors.red.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_rounded,
                      size: 18, color: AdminColors.primary),
                  tooltip: 'Edit',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditPoojaScreen(pooja: pooja)),
                  ),
                ),
              ],
            ),
          ),
          // Description
          if (pooja.description.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                pooja.description,
                style: TextStyle(
                    fontSize: 13,
                    color: AdminColors.grey600,
                    height: 1.4),
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
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _iconCtrl,
        _durationCtrl, _displayOrderCtrl, _infoCtrl,
        ..._beforeCtrls, ..._afterCtrls, ..._bringCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _listValues(List<TextEditingController> ctrls) =>
      ctrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty) { _snack('Pooja name is required'); return; }
    if (price == null || price <= 0) { _snack('Please enter a valid price'); return; }

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
          const SnackBar(content: Text('Pooja created successfully')),
        );
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

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
                const Text('New Pooja',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const Divider(height: 24),
              ],
            ),
          ),
          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              children: [
                _sectionHeader('Basic Info'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                      'Pooja Name *', Icons.auto_awesome_rounded),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                      'Short Description', Icons.short_text_rounded),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                          'Price per Person (₹) *',
                          Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _displayOrderCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                          'Display Order', Icons.sort_rounded),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      decoration: _inputDecoration(
                          'Duration (e.g. 1 Day)', Icons.schedule_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _iconCtrl,
                      decoration: _inputDecoration(
                          'Icon Name', Icons.insert_emoticon_rounded),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                _sectionHeader('Color'),
                const SizedBox(height: 12),
                _colorPicker(),
                const SizedBox(height: 20),

                _sectionHeader('Detailed Info'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _infoCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                      'Full description / info', Icons.info_outline_rounded),
                ),
                const SizedBox(height: 20),

                _sectionHeader('Before Instructions'),
                const SizedBox(height: 8),
                _dynamicList(_beforeCtrls,
                    hint: 'e.g. Take a holy bath before arriving'),
                const SizedBox(height: 20),

                _sectionHeader('After Instructions'),
                const SizedBox(height: 8),
                _dynamicList(_afterCtrls,
                    hint: 'e.g. Maintain celibacy for 3 days'),
                const SizedBox(height: 20),

                _sectionHeader('Things to Bring'),
                const SizedBox(height: 8),
                _dynamicList(_bringCtrls,
                    hint: 'e.g. White dhoti and saree'),
                const SizedBox(height: 20),

                _statusToggle(),
                const SizedBox(height: 24),
                _submitButton('Create Pooja', _saving, _save),
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
            letterSpacing: 0.6),
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
                border:
                    selected ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: _kColorOptions[i].withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
      );

  Widget _dynamicList(List<TextEditingController> ctrls,
      {required String hint}) {
    return Column(
      children: [
        ...ctrls.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: e.value,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle:
                            TextStyle(fontSize: 13, color: AdminColors.grey400),
                        prefixText: '${e.key + 1}.  ',
                        prefixStyle: TextStyle(
                            fontSize: 13, color: AdminColors.grey500),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
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
                              color: AdminColors.primary, width: 1.5),
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
                      child: Icon(Icons.remove_circle_outline_rounded,
                          color: Colors.red.shade300, size: 22),
                    ),
                  ],
                ],
              ),
            )),
        TextButton.icon(
          onPressed: () =>
              setState(() => ctrls.add(TextEditingController())),
          icon: Icon(Icons.add_rounded,
              size: 16, color: AdminColors.primary),
          label: Text('Add item',
              style: TextStyle(
                  fontSize: 13,
                  color: AdminColors.primary,
                  fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 0)),
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
            Icon(Icons.power_settings_new_rounded,
                size: 20,
                color:
                    _enabled ? Colors.green.shade600 : AdminColors.grey500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pooja Status',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    _enabled
                        ? 'Enabled — visible to users'
                        : 'Disabled — hidden from users',
                    style:
                        TextStyle(fontSize: 12, color: AdminColors.grey600),
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
            borderRadius: BorderRadius.circular(2)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
