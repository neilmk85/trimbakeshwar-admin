import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../l10n/tr.dart';

class RoomBlocksScreen extends StatefulWidget {
  const RoomBlocksScreen({super.key});

  @override
  State<RoomBlocksScreen> createState() => _RoomBlocksScreenState();
}

class _RoomBlocksScreenState extends State<RoomBlocksScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());
  bool _loadingRooms = true;
  String? _roomsError;
  List<AdminRoom> _rooms = [];
  final Map<int, RoomBlockBoard?> _boards = {};
  final Set<int> _loadingBoards = {};

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    final result = await AdminDataService.getRooms();
    if (!mounted) return;
    setState(() {
      _rooms = result.data;
      _roomsError = result.error;
      _loadingRooms = false;
    });
    await _loadAllBoards();
  }

  Future<void> _loadAllBoards() async {
    await Future.wait(_rooms.map((r) => _loadBoard(r.id)));
  }

  Future<void> _loadBoard(int roomId) async {
    if (!mounted) return;
    setState(() => _loadingBoards.add(roomId));
    final result = await AdminDataService.getRoomBlocks(roomId, _selectedDate);
    if (!mounted) return;
    setState(() {
      _boards[roomId] = result.data;
      _loadingBoards.remove(roomId);
    });
    if (result.error != null && mounted) {
      _showSnack(result.error!, isError: true);
    }
  }

  Future<void> _changeDate(DateTime newDate) async {
    setState(() => _selectedDate = _dateOnly(newDate));
    await _loadAllBoards();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) await _changeDate(picked);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCreateBlockSheet(AdminRoom room, int maxAvailable) async {
    if (maxAvailable <= 0) {
      _showSnack(tr('No rooms available on this date to block.', 'इस तारीख पर ब्लॉक करने के लिए कोई कमरा उपलब्ध नहीं है।'), isError: true);
      return;
    }
    final result = await showModalBottomSheet<_WalkInBlockForm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalkInBlockSheet(room: room, maxAvailable: maxAvailable, date: _selectedDate),
    );
    if (result == null) return;

    final err = await AdminDataService.createRoomBlock(
      room.id,
      checkInDate: _selectedDate,
      numberOfNights: result.numberOfNights,
      numberOfRooms: result.numberOfRooms,
      guestName: result.guestName,
      notes: result.notes,
    );
    if (!mounted) return;
    if (err == null) {
      _showSnack(tr('Room blocked for walk-in guest.', 'वॉक-इन अतिथि के लिए कमरा ब्लॉक किया गया।'));
      await _loadBoard(room.id);
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _confirmRelease(RoomBlock block, int roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('Release this room?', 'यह कमरा रिलीज़ करें?')),
        content: Text(
          tr(
            '${block.guestName.isEmpty ? 'Walk-in guest' : block.guestName} '
            '· ${block.numberOfRooms} room(s) · ${block.numberOfNights} night(s)'
            '${block.notes.isNotEmpty ? '\n\n${block.notes}' : ''}',
            '${block.guestName.isEmpty ? 'वॉक-इन अतिथि' : block.guestName} '
            '· ${block.numberOfRooms} कमरे · ${block.numberOfNights} रातें'
            '${block.notes.isNotEmpty ? '\n\n${block.notes}' : ''}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel', 'रद्द करें'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Release', 'रिलीज़ करें')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await AdminDataService.releaseRoomBlock(block.id);
    if (!mounted) return;
    if (err == null) {
      _showSnack(tr('Room released.', 'कमरा रिलीज़ किया गया।'));
      await _loadBoard(roomId);
    } else {
      _showSnack(err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F6FA),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loadingRooms
            ? const Center(child: CircularProgressIndicator())
            : _roomsError != null && _rooms.isEmpty
                ? _buildError(_roomsError!)
                : _rooms.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildDatePicker(),
                          const SizedBox(height: 16),
                          for (final room in _rooms) ...[
                            _buildRoomCard(room),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
      ),
    );
  }

  Widget _buildError(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: AdminColors.grey400),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: AdminColors.grey600)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(tr('Retry', 'फिर से कोशिश करें'))),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.meeting_room_outlined, size: 56, color: AdminColors.grey400),
              const SizedBox(height: 12),
              Text(tr('No room listings yet.', 'अभी तक कोई कमरा सूचीबद्ध नहीं है।'), style: TextStyle(color: AdminColors.grey600)),
            ],
          ),
        ),
      );

  Widget _buildDatePicker() {
    final isToday = _selectedDate == _dateOnly(DateTime.now());
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: AdminColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isToday ? '${tr('Today', 'आज')} · ${_formatDate(_selectedDate)}' : _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: AdminColors.grey600,
                onPressed: isToday ? null : () => _changeDate(_selectedDate.subtract(const Duration(days: 1))),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: AdminColors.grey600,
                onPressed: () => _changeDate(_selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = [
      tr('Jan', 'जन'),
      tr('Feb', 'फ़र'),
      tr('Mar', 'मार्च'),
      tr('Apr', 'अप्रैल'),
      tr('May', 'मई'),
      tr('Jun', 'जून'),
      tr('Jul', 'जुलाई'),
      tr('Aug', 'अग'),
      tr('Sep', 'सित'),
      tr('Oct', 'अक्टू'),
      tr('Nov', 'नव'),
      tr('Dec', 'दिस'),
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildRoomCard(AdminRoom room) {
    final board = _boards[room.id];
    final loading = _loadingBoards.contains(room.id);
    final totalCount = board?.totalCount ?? room.count;
    final onlineCount = board?.onlineBookedCount ?? 0;
    final walkInBlocks = board?.walkInBlocks ?? [];
    final walkInCount = board?.walkInBlockedCount ?? 0;
    final rawAvailable = totalCount - onlineCount - walkInCount;
    final availableCount = rawAvailable < 0 ? 0 : rawAvailable;
    final overflow = rawAvailable < 0 ? -rawAvailable : 0;

    // Expand walk-in blocks into individual tile slots so each tile maps to one block.
    final walkInTiles = <RoomBlock>[];
    for (final b in walkInBlocks) {
      for (var i = 0; i < b.numberOfRooms; i++) {
        walkInTiles.add(b);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(room.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ),
              if (loading)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Text(tr('$availableCount/$totalCount available', '$availableCount/$totalCount उपलब्ध'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.grey600)),
            ],
          ),
          if (overflow > 0) ...[
            const SizedBox(height: 6),
            Text(
                tr(
                  '⚠ $overflow room(s) over capacity for this date — reduce blocks or check bookings.',
                  '⚠ इस तारीख के लिए $overflow कमरे क्षमता से अधिक हैं — ब्लॉक कम करें या बुकिंग जांचें।',
                ),
                style: TextStyle(fontSize: 11.5, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < onlineCount; i++) _tile(color: const Color(0xFF1565C0), icon: Icons.event_available_rounded),
              for (final block in walkInTiles)
                _tile(
                  color: const Color(0xFFEF6C00),
                  icon: Icons.person_rounded,
                  onTap: () => _confirmRelease(block, room.id),
                ),
              for (var i = 0; i < availableCount; i++)
                _tile(
                  color: Colors.green.shade600,
                  icon: Icons.add_rounded,
                  outlined: true,
                  onTap: () => _openCreateBlockSheet(room, availableCount),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _legend(const Color(0xFF1565C0), tr('Booked Online', 'ऑनलाइन बुक्ड')),
              _legend(const Color(0xFFEF6C00), tr('Walk-in', 'वॉक-इन')),
              _legend(Colors.green.shade600, tr('Available', 'उपलब्ध')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required Color color,
    required IconData icon,
    bool outlined = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: outlined ? color.withValues(alpha: 0.1) : color,
          border: outlined ? Border.all(color: color, width: 1.4) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: outlined ? color : Colors.white),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: AdminColors.grey600)),
        ],
      );
}

class _WalkInBlockForm {
  final String guestName;
  final String notes;
  final int numberOfNights;
  final int numberOfRooms;
  const _WalkInBlockForm({
    required this.guestName,
    required this.notes,
    required this.numberOfNights,
    required this.numberOfRooms,
  });
}

class _WalkInBlockSheet extends StatefulWidget {
  final AdminRoom room;
  final int maxAvailable;
  final DateTime date;
  const _WalkInBlockSheet({required this.room, required this.maxAvailable, required this.date});

  @override
  State<_WalkInBlockSheet> createState() => _WalkInBlockSheetState();
}

class _WalkInBlockSheetState extends State<_WalkInBlockSheet> {
  final _guestController = TextEditingController();
  final _notesController = TextEditingController();
  int _nights = 1;
  int _rooms = 1;

  @override
  void dispose() {
    _guestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AdminColors.grey300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
                tr(
                  'Block ${widget.room.name} for Walk-in',
                  '${widget.room.name} को वॉक-इन के लिए ब्लॉक करें',
                ),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text(
                tr(
                  'Reduces this room\'s online availability from the selected date.',
                  'चुनी गई तारीख से इस कमरे की ऑनलाइन उपलब्धता कम हो जाती है।',
                ),
                style: TextStyle(fontSize: 12.5, color: AdminColors.grey600)),
            const SizedBox(height: 18),
            TextField(
              controller: _guestController,
              decoration: InputDecoration(
                labelText: tr('Guest name (optional)', 'अतिथि का नाम (वैकल्पिक)'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: tr('Notes (optional)', 'नोट्स (वैकल्पिक)'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            _stepperRow(tr('Rooms', 'कमरे'), _rooms, 1, widget.maxAvailable,
                onDec: () => setState(() => _rooms = (_rooms - 1).clamp(1, widget.maxAvailable)),
                onInc: () => setState(() => _rooms = (_rooms + 1).clamp(1, widget.maxAvailable))),
            const SizedBox(height: 10),
            _stepperRow(tr('Nights', 'रातें'), _nights, 1, 30,
                onDec: () => setState(() => _nights = (_nights - 1).clamp(1, 30)),
                onInc: () => setState(() => _nights = (_nights + 1).clamp(1, 30))),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(
                  context,
                  _WalkInBlockForm(
                    guestName: _guestController.text.trim(),
                    notes: _notesController.text.trim(),
                    numberOfNights: _nights,
                    numberOfRooms: _rooms,
                  ),
                ),
                child: Text(tr('Block Room', 'कमरा ब्लॉक करें'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperRow(String label, int value, int min, int max, {required VoidCallback onDec, required VoidCallback onInc}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        _stepBtn(Icons.remove_rounded, value > min ? onDec : null),
        SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        _stepBtn(Icons.add_rounded, value < max ? onInc : null),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => IconButton(
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: AdminColors.grey100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
      );
}
