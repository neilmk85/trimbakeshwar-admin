import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../l10n/tr.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

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
  late final TextEditingController _stayRateCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _displayOrderCtrl;
  late final TextEditingController _infoCtrl;
  late List<TextEditingController> _beforeCtrls;
  late List<TextEditingController> _afterCtrls;
  late List<TextEditingController> _bringCtrls;
  late bool _enabled;
  late int _colorIndex;
  late List<DateTime> _muhurtaDates;
  late DateTime _calendarMonth;
  late bool _privatePooja;
  late TextEditingController _privatePoojaRateCtrl;
  late TextEditingController _gurujiDefaultRateCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pooja;
    _nameCtrl = TextEditingController(text: p.name);
    _descCtrl = TextEditingController(text: p.description);
    _priceCtrl = TextEditingController(text: p.pricePerPerson.toString());
    _stayRateCtrl = TextEditingController(
      text: p.stayRatePerNight > 0 ? p.stayRatePerNight.toString() : '',
    );
    _iconCtrl = TextEditingController(text: p.iconName);
    _durationCtrl = TextEditingController(text: p.duration);
    _displayOrderCtrl = TextEditingController(
      text: p.displayOrder?.toString() ?? '',
    );
    _infoCtrl = TextEditingController(text: p.info);
    _beforeCtrls = _initList(p.beforeInstructions);
    _afterCtrls = _initList(p.afterInstructions);
    _bringCtrls = _initList(p.thingsToBring);
    _enabled = p.enabled;
    _colorIndex = _kColorHexes.indexOf(p.colorHex);
    if (_colorIndex < 0) _colorIndex = 0;
    _muhurtaDates = List.from(p.muhurtaDates);
    final now = DateTime.now();
    if (_muhurtaDates.isNotEmpty) {
      // Land on the earliest selected date's month instead of today's month —
      // otherwise a pooja whose dates are all in other months opens showing
      // an empty grid while the summary count still says "N selected", which
      // reads as a contradiction.
      final earliest = _muhurtaDates.reduce((a, b) => a.isBefore(b) ? a : b);
      _calendarMonth = DateTime(earliest.year, earliest.month);
    } else {
      _calendarMonth = DateTime(now.year, now.month);
    }
    _privatePooja = p.privatePooja;
    _privatePoojaRateCtrl = TextEditingController(
      text: p.privatePoojaRate > 0 ? p.privatePoojaRate.toString() : '',
    );
    _gurujiDefaultRateCtrl = TextEditingController(
      text: p.gurujiDefaultRate > 0 ? p.gurujiDefaultRate.toString() : '',
    );
  }

  List<TextEditingController> _initList(List<String> items) {
    if (items.isEmpty) return [TextEditingController()];
    return items.map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _priceCtrl,
      _stayRateCtrl,
      _iconCtrl,
      _durationCtrl,
      _displayOrderCtrl,
      _infoCtrl,
      _privatePoojaRateCtrl,
      _gurujiDefaultRateCtrl,
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
      _snack(
        tr('Pooja name is required', 'पूजा का नाम आवश्यक है', 'पूजेचे नाव आवश्यक आहे'),
      );
      return;
    }
    if (price == null || price <= 0) {
      _snack(
        tr(
          'Please enter a valid price',
          'कृपया सही कीमत डालें',
          'कृपया योग्य किंमत टाका',
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final error = await AdminDataService.updatePooja(
      widget.pooja.id,
      name: name,
      description: _descCtrl.text.trim(),
      pricePerPerson: price,
      stayRatePerNight: int.tryParse(_stayRateCtrl.text.trim()) ?? 0,
      colorHex: _kColorHexes[_colorIndex],
      enabled: _enabled,
      iconName: _iconCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      displayOrder: int.tryParse(_displayOrderCtrl.text.trim()),
      info: _infoCtrl.text.trim(),
      beforeInstructions: _listValues(_beforeCtrls),
      afterInstructions: _listValues(_afterCtrls),
      thingsToBring: _listValues(_bringCtrls),
      muhurtaDates: _muhurtaDates,
      privatePooja: _privatePooja,
      privatePoojaRate: int.tryParse(_privatePoojaRateCtrl.text.trim()) ?? 0,
      gurujiDefaultRate: int.tryParse(_gurujiDefaultRateCtrl.text.trim()) ?? 0,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (error != null) {
        _snack(error);
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'Pooja updated successfully',
                'पूजा सफलतापूर्वक अपडेट की गई',
                'पूजा यशस्वीरित्या अपडेट झाली',
              ),
            ),
          ),
        );
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                tr('Save', 'सेव करें', 'जतन करा'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _sectionHeader(tr('Basic Info', 'बुनियादी जानकारी', 'मूलभूत माहिती')),
          const SizedBox(height: 12),
          _field(
            _nameCtrl,
            tr('Pooja Name *', 'पूजा का नाम *', 'पूजेचे नाव *'),
            Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 12),
          _field(
            _descCtrl,
            tr('Short Description', 'संक्षिप्त विवरण', 'थोडक्यात माहिती'),
            Icons.short_text_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _field(
                  _priceCtrl,
                  tr(
                    'Price per Person (₹) *',
                    'प्रति व्यक्ति कीमत (₹) *',
                    'प्रति व्यक्ती किंमत (₹) *',
                  ),
                  Icons.currency_rupee_rounded,
                  numeric: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _field(
                  _displayOrderCtrl,
                  tr('Display Order', 'डिस्प्ले क्रम', 'डिस्प्ले क्रम'),
                  Icons.sort_rounded,
                  numeric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            _stayRateCtrl,
            tr(
              'Stay Rate per Night (₹)',
              'प्रति रात ठहरने की दर (₹)',
              'प्रति रात्र निवासाचा दर (₹)',
            ),
            Icons.hotel_rounded,
            numeric: true,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              tr(
                'Set to 0 to disable stay booking for this pooja.',
                'इस पूजा के लिए ठहरने की बुकिंग बंद करने हेतु 0 डालें।',
                'या पूजेसाठी निवास बुकिंग बंद करण्यासाठी 0 टाका.',
              ),
              style: TextStyle(fontSize: 11, color: AdminColors.grey500),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _field(
                  _durationCtrl,
                  tr(
                    'Duration (e.g. 1 Day)',
                    'अवधि (जैसे 1 दिन)',
                    'कालावधी (उदा. 1 दिवस)',
                  ),
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _iconCtrl,
                  tr('Icon Name', 'आइकन का नाम', 'आयकनचे नाव'),
                  Icons.insert_emoticon_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _sectionHeader(tr('Color', 'रंग', 'रंग')),
          const SizedBox(height: 12),
          _colorPicker(),
          const SizedBox(height: 24),

          _sectionHeader(tr('Status', 'स्थिति', 'स्थिती')),
          const SizedBox(height: 12),
          _statusToggle(),
          const SizedBox(height: 24),

          _sectionHeader(
            tr('Private / Separate Pooja', 'निजी / अलग पूजा', 'खाजगी / वेगळी पूजा'),
          ),
          const SizedBox(height: 12),
          _privatePoojaToggle(),
          const SizedBox(height: 24),

          _sectionHeader(tr('Guruji Rate', 'गुरुजी की दर', 'गुरुजींचा दर')),
          const SizedBox(height: 4),
          Text(
            tr(
              'Default payout for this pooja, shown against every Guruji unless overridden individually.',
              'इस पूजा के लिए डिफ़ॉल्ट भुगतान, जब तक अलग से बदला न जाए तब तक हर गुरुजी के सामने यही दिखाया जाता है।',
              'या पूजेसाठीचा डिफॉल्ट भुगतान, वेगळा बदल केला नसेल तर प्रत्येक गुरुजींसमोर हाच दाखवला जातो.',
            ),
            style: TextStyle(fontSize: 12, color: AdminColors.grey600),
          ),
          const SizedBox(height: 12),
          _field(
            _gurujiDefaultRateCtrl,
            tr(
              'Default Guruji Rate (₹)',
              'डिफ़ॉल्ट गुरुजी दर (₹)',
              'डिफॉल्ट गुरुजी दर (₹)',
            ),
            Icons.currency_rupee_rounded,
            numeric: true,
          ),
          const SizedBox(height: 24),

          _sectionHeader(tr('Muhurta Dates', 'मुहूर्त तिथियां', 'मुहूर्त तारखा')),
          const SizedBox(height: 12),
          _muhurtaCalendar(),
          const SizedBox(height: 24),

          _sectionHeader(tr('Detailed Info', 'विस्तृत जानकारी', 'सविस्तर माहिती')),
          const SizedBox(height: 12),
          _field(
            _infoCtrl,
            tr(
              'Full description / info',
              'पूरा विवरण / जानकारी',
              'संपूर्ण माहिती / वर्णन',
            ),
            Icons.info_outline_rounded,
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          _sectionHeader(
            tr('Before Instructions', 'पहले के निर्देश', 'आधीच्या सूचना'),
          ),
          const SizedBox(height: 8),
          _dynamicList(
            _beforeCtrls,
            hint: tr(
              'e.g. Take a holy bath before arriving',
              'जैसे आने से पहले पवित्र स्नान करें',
              'उदा. येण्यापूर्वी पवित्र स्नान करा',
            ),
          ),
          const SizedBox(height: 24),

          _sectionHeader(
            tr('After Instructions', 'बाद के निर्देश', 'नंतरच्या सूचना'),
          ),
          const SizedBox(height: 8),
          _dynamicList(
            _afterCtrls,
            hint: tr(
              'e.g. Maintain celibacy for 3 days',
              'जैसे 3 दिन ब्रह्मचर्य का पालन करें',
              'उदा. 3 दिवस ब्रह्मचर्य पाळा',
            ),
          ),
          const SizedBox(height: 24),

          _sectionHeader(
            tr('Things to Bring', 'साथ लाने योग्य चीज़ें', 'सोबत आणायच्या वस्तू'),
          ),
          const SizedBox(height: 8),
          _dynamicList(
            _bringCtrls,
            hint: tr(
              'e.g. White dhoti and saree',
              'जैसे सफेद धोती और साड़ी',
              'उदा. पांढरे धोतर आणि साडी',
            ),
          ),
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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      tr('Save Changes', 'बदलाव सेव करें', 'बदल जतन करा'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool numeric = false,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
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
        borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
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
                      blurRadius: 10,
                      spreadRadius: 2,
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
                  size: 20,
                )
              : null,
        ),
      );
    }),
  );

  Widget _privatePoojaToggle() => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _privatePooja
                ? const Color(0xFF6A1B9A).withValues(alpha: 0.4)
                : AdminColors.grey300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_person_rounded,
              size: 22,
              color: _privatePooja
                  ? const Color(0xFF6A1B9A)
                  : AdminColors.grey500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      'Separate / Private Pooja',
                      'अलग / निजी पूजा',
                      'वेगळी / खाजगी पूजा',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _privatePooja
                        ? tr(
                            'Enabled — users can book a private session',
                            'सक्षम — उपयोगकर्ता निजी सत्र बुक कर सकते हैं',
                            'सुरू — वापरकर्ते खाजगी सत्र बुक करू शकतात',
                          )
                        : tr(
                            'Disabled — group pooja only',
                            'अक्षम — केवल सामूहिक पूजा',
                            'बंद — फक्त सामूहिक पूजा',
                          ),
                    style: TextStyle(fontSize: 12, color: AdminColors.grey600),
                  ),
                ],
              ),
            ),
            Switch(
              value: _privatePooja,
              onChanged: (v) => setState(() => _privatePooja = v),
              activeColor: const Color(0xFF6A1B9A),
            ),
          ],
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: _privatePooja
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _field(
                  _privatePoojaRateCtrl,
                  tr(
                    'Private Pooja Rate (₹)',
                    'निजी पूजा दर (₹)',
                    'खाजगी पूजा दर (₹)',
                  ),
                  Icons.currency_rupee_rounded,
                  numeric: true,
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );

  Widget _statusToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AdminColors.grey300),
    ),
    child: Row(
      children: [
        Icon(
          Icons.power_settings_new_rounded,
          size: 22,
          color: _enabled ? Colors.green.shade600 : AdminColors.grey500,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Pooja Status', 'पूजा की स्थिति', 'पूजेची स्थिती'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _enabled
                    ? tr(
                        'Enabled — visible to users',
                        'सक्षम — उपयोगकर्ताओं को दिखेगी',
                        'सुरू — वापरकर्त्यांना दिसेल',
                      )
                    : tr(
                        'Disabled — hidden from users',
                        'अक्षम — उपयोगकर्ताओं से छिपी रहेगी',
                        'बंद — वापरकर्त्यांपासून लपलेली राहील',
                      ),
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

  // ── Multi-date inline calendar ─────────────────────────────────────────────

  bool _isMuhurta(DateTime d) => _muhurtaDates.any(
    (m) => m.year == d.year && m.month == d.month && m.day == d.day,
  );

  void _toggleDate(DateTime d) {
    setState(() {
      final idx = _muhurtaDates.indexWhere(
        (m) => m.year == d.year && m.month == d.month && m.day == d.day,
      );
      if (idx >= 0) {
        _muhurtaDates.removeAt(idx);
      } else {
        _muhurtaDates.add(d);
      }
    });
  }

  static List<String> get _weekLabels => [
        tr('Su', 'रवि', 'रवि'),
        tr('Mo', 'सोम', 'सोम'),
        tr('Tu', 'मंगल', 'मंगळ'),
        tr('We', 'बुध', 'बुध'),
        tr('Th', 'गुरु', 'गुरु'),
        tr('Fr', 'शुक्र', 'शुक्र'),
        tr('Sa', 'शनि', 'शनि'),
      ];
  static List<String> get _monthNames => [
        '',
        tr('January', 'जनवरी', 'जानेवारी'),
        tr('February', 'फ़रवरी', 'फेब्रुवारी'),
        tr('March', 'मार्च', 'मार्च'),
        tr('April', 'अप्रैल', 'एप्रिल'),
        tr('May', 'मई', 'मे'),
        tr('June', 'जून', 'जून'),
        tr('July', 'जुलाई', 'जुलै'),
        tr('August', 'अगस्त', 'ऑगस्ट'),
        tr('September', 'सितंबर', 'सप्टेंबर'),
        tr('October', 'अक्टूबर', 'ऑक्टोबर'),
        tr('November', 'नवंबर', 'नोव्हेंबर'),
        tr('December', 'दिसंबर', 'डिसेंबर'),
      ];

  Widget _muhurtaCalendar() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // weekday: Mon=1 … Sun=7; we want Sun=0 offset
    final startOffset = (firstDay.weekday % 7);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    // Dates selected in the current view month
    final monthSelected =
        _muhurtaDates.where((d) => d.year == year && d.month == month).toList()
          ..sort((a, b) => a.day.compareTo(b.day));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.grey300),
      ),
      child: Column(
        children: [
          // ── Month navigation header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _calendarMonth = DateTime(year, month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  color: AdminColors.grey600,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[month]} $year',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _calendarMonth = DateTime(year, month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  color: AdminColors.grey600,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ── Day-of-week labels ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _weekLabels
                  .map(
                    (lbl) => Expanded(
                      child: Center(
                        child: Text(
                          lbl,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.grey500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ── Calendar grid ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              children: List.generate(rows, (row) {
                return Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    final day = cellIndex - startOffset + 1;
                    if (day < 1 || day > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 38));
                    }
                    final date = DateTime(year, month, day);
                    final selected = _isMuhurta(date);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleDate(date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.all(2),
                          height: 34,
                          decoration: BoxDecoration(
                            color: selected
                                ? AdminColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: selected
                                    ? Colors.white
                                    : AdminColors.grey600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),

          // ── Summary strip ────────────────────────────────────────────────
          if (_muhurtaDates.isNotEmpty) ...[
            Divider(height: 1, color: AdminColors.grey300),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 15,
                    color: AdminColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      monthSelected.length == _muhurtaDates.length
                          ? (_muhurtaDates.length == 1
                                ? tr(
                                    '1 muhurta date selected',
                                    '1 मुहूर्त तिथि चुनी गई',
                                    '1 मुहूर्त तारीख निवडली',
                                  )
                                : tr(
                                    '${_muhurtaDates.length} muhurta dates selected',
                                    '${_muhurtaDates.length} मुहूर्त तिथियां चुनी गईं',
                                    '${_muhurtaDates.length} मुहूर्त तारखा निवडल्या',
                                  ))
                          : tr(
                              '${monthSelected.length} this month · '
                                  '${_muhurtaDates.length} selected across all months',
                              '${monthSelected.length} इस महीने · '
                                  '${_muhurtaDates.length} सभी महीनों में चुनी गईं',
                              '${monthSelected.length} या महिन्यात · '
                                  '${_muhurtaDates.length} सर्व महिन्यांत निवडलेल्या',
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (monthSelected.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(
                        () => _muhurtaDates.removeWhere(
                          (d) => d.year == year && d.month == month,
                        ),
                      ),
                      child: Text(
                        tr('Clear month', 'महीना साफ़ करें', 'महिना रिकामा करा'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
                        ),
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
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }
}
