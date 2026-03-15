import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

const _kColorOptions = [
  Color(0xFF1565C0), Color(0xFF00838F), Color(0xFF4527A0), Color(0xFF2E7D32),
  Color(0xFFC62828), Color(0xFFEF6C00), Color(0xFF6A1B9A), Color(0xFF00695C),
  Color(0xFF283593), Color(0xFF558B2F),
];

const _kColorHexes = [
  '#1565C0', '#00838F', '#4527A0', '#2E7D32',
  '#C62828', '#EF6C00', '#6A1B9A', '#00695C',
  '#283593', '#558B2F',
];

class EditPoojaScreen extends StatefulWidget {
  final AdminPooja pooja;
  const EditPoojaScreen({super.key, required this.pooja});

  @override
  State<EditPoojaScreen> createState() => _EditPoojaScreenState();
}

class _EditPoojaScreenState extends State<EditPoojaScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _displayOrderCtrl;
  late final TextEditingController _infoCtrl;
  late List<TextEditingController> _beforeCtrls;
  late List<TextEditingController> _afterCtrls;
  late List<TextEditingController> _bringCtrls;
  late bool _enabled;
  late int _colorIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pooja;
    _nameCtrl = TextEditingController(text: p.name);
    _descCtrl = TextEditingController(text: p.description);
    _priceCtrl = TextEditingController(text: p.pricePerPerson.toString());
    _iconCtrl = TextEditingController(text: p.iconName);
    _durationCtrl = TextEditingController(text: p.duration);
    _displayOrderCtrl = TextEditingController(
        text: p.displayOrder?.toString() ?? '');
    _infoCtrl = TextEditingController(text: p.info);
    _beforeCtrls = _initList(p.beforeInstructions);
    _afterCtrls = _initList(p.afterInstructions);
    _bringCtrls = _initList(p.thingsToBring);
    _enabled = p.enabled;
    _colorIndex = _kColorHexes.indexOf(p.colorHex);
    if (_colorIndex < 0) _colorIndex = 0;
  }

  List<TextEditingController> _initList(List<String> items) {
    if (items.isEmpty) return [TextEditingController()];
    return items.map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _priceCtrl, _iconCtrl,
      _durationCtrl, _displayOrderCtrl, _infoCtrl,
      ..._beforeCtrls, ..._afterCtrls, ..._bringCtrls,
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
    if (name.isEmpty) { _snack('Pooja name is required'); return; }
    if (price == null || price <= 0) { _snack('Please enter a valid price'); return; }

    setState(() => _saving = true);
    final error = await AdminDataService.updatePooja(
      widget.pooja.id,
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
          const SnackBar(content: Text('Pooja updated successfully')),
        );
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pooja.name),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AdminColors.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 20),
              label: const Text('Save',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _sectionHeader('Basic Info'),
          const SizedBox(height: 12),
          _field(_nameCtrl, 'Pooja Name *', Icons.auto_awesome_rounded),
          const SizedBox(height: 12),
          _field(_descCtrl, 'Short Description', Icons.short_text_rounded,
              maxLines: 2),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 3,
              child: _field(_priceCtrl, 'Price per Person (₹) *',
                  Icons.currency_rupee_rounded,
                  numeric: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _field(_displayOrderCtrl, 'Display Order',
                  Icons.sort_rounded,
                  numeric: true),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _field(_durationCtrl, 'Duration (e.g. 1 Day)',
                  Icons.schedule_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(_iconCtrl, 'Icon Name',
                  Icons.insert_emoticon_rounded),
            ),
          ]),
          const SizedBox(height: 24),

          _sectionHeader('Color'),
          const SizedBox(height: 12),
          _colorPicker(),
          const SizedBox(height: 24),

          _sectionHeader('Status'),
          const SizedBox(height: 12),
          _statusToggle(),
          const SizedBox(height: 24),

          _sectionHeader('Detailed Info'),
          const SizedBox(height: 12),
          _field(_infoCtrl, 'Full description / info',
              Icons.info_outline_rounded,
              maxLines: 4),
          const SizedBox(height: 24),

          _sectionHeader('Before Instructions'),
          const SizedBox(height: 8),
          _dynamicList(_beforeCtrls,
              hint: 'e.g. Take a holy bath before arriving'),
          const SizedBox(height: 24),

          _sectionHeader('After Instructions'),
          const SizedBox(height: 8),
          _dynamicList(_afterCtrls,
              hint: 'e.g. Maintain celibacy for 3 days'),
          const SizedBox(height: 24),

          _sectionHeader('Things to Bring'),
          const SizedBox(height: 8),
          _dynamicList(_bringCtrls, hint: 'e.g. White dhoti and saree'),
          const SizedBox(height: 32),

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
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool numeric = false,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
            numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        textCapitalization: numeric
            ? TextCapitalization.none
            : TextCapitalization.sentences,
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

  Widget _colorPicker() => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(_kColorOptions.length, (i) {
          final selected = _colorIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _colorIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kColorOptions[i],
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: _kColorOptions[i].withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                  : null,
            ),
          );
        }),
      );

  Widget _statusToggle() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.grey300),
        ),
        child: Row(
          children: [
            Icon(Icons.power_settings_new_rounded,
                size: 22,
                color: _enabled
                    ? Colors.green.shade600
                    : AdminColors.grey500),
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
                    style: TextStyle(
                        fontSize: 12, color: AdminColors.grey600),
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
                        hintStyle: TextStyle(
                            fontSize: 13, color: AdminColors.grey400),
                        prefixText: '${e.key + 1}.  ',
                        prefixStyle: TextStyle(
                            fontSize: 13, color: AdminColors.grey500),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AdminColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AdminColors.grey300),
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
              padding: EdgeInsets.zero),
        ),
      ],
    );
  }
}
