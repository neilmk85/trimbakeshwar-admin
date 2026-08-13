import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  List<AdminRoom> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await AdminDataService.getRooms();
    if (mounted) {
      setState(() {
        _rooms = result.data;
        _error = result.error;
        _loading = false;
      });
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoomFormSheet(
        onSaved: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  void _showEditSheet(AdminRoom room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoomFormSheet(
        room: room,
        onSaved: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  Future<void> _toggleAvailability(AdminRoom room) async {
    final err = await AdminDataService.toggleRoomAvailability(
        room.id, !room.available);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      _load();
    }
  }

  Future<void> _delete(AdminRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete "${room.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await AdminDataService.deleteRoom(room.id);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AdminColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Room',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 52, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 13)),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hotel_rounded,
                              size: 52, color: Colors.black26),
                          const SizedBox(height: 12),
                          const Text('No rooms yet. Tap + to add one.',
                              style: TextStyle(
                                  color: Colors.black45, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _rooms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _RoomTile(
                              room: _rooms[i],
                              onEdit: () => _showEditSheet(_rooms[i]),
                              onDelete: () => _delete(_rooms[i]),
                              onToggle: () => _toggleAvailability(_rooms[i]),
                            ),
                      ),
                    ),
    );
  }
}

// ── Room Tile ─────────────────────────────────────────────────────────────────

class _RoomTile extends StatelessWidget {
  final AdminRoom room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _RoomTile({
    required this.room,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = room.available ? AdminColors.primary : Colors.grey;
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hotel_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Row(children: [
                        _typeBadge(room.type),
                        const SizedBox(width: 8),
                        _countBadge(room.id, room.count),
                        const SizedBox(width: 8),
                        Icon(Icons.person_rounded,
                            size: 12, color: AdminColors.grey600),
                        const SizedBox(width: 3),
                        Text(room.capacity,
                            style: TextStyle(
                                fontSize: 12, color: AdminColors.grey600)),
                      ]),
                    ],
                  ),
                ),
                Text('₹${room.pricePerNight}/night',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
            if (room.amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: room.amenities
                    .take(4)
                    .map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(a,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF555555))),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // Available toggle
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: room.available
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          room.available
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 13,
                          color: room.available
                              ? Colors.green.shade700
                              : Colors.red.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          room.available ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: room.available
                                ? Colors.green.shade700
                                : Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Edit
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: AdminColors.primary,
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                const SizedBox(width: 4),
                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.red,
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(int roomId, int totalCount) {
    // Calculate available rooms by subtracting active bookings
    int availableCount = totalCount;
    try {
      for (final booking in AdminDataService.dataNotifier.value.orders) {
        if (booking.roomId == roomId && !booking.cancelled) {
          availableCount -= booking.numberOfRooms;
        }
      }
      availableCount = availableCount < 0 ? 0 : availableCount;
    } catch (_) {
      // If error in calculation, just show total
      availableCount = totalCount;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AdminColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.meeting_room_rounded,
              size: 10, color: AdminColors.primary),
          const SizedBox(width: 2),
          Text('×$totalCount',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.primary)),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: type == 'AC'
              ? const Color(0xFF1565C0).withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(type,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: type == 'AC'
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade700)),
      );
}

// ── Room Form Sheet ───────────────────────────────────────────────────────────

class _RoomFormSheet extends StatefulWidget {
  final AdminRoom? room;
  final VoidCallback onSaved;

  const _RoomFormSheet({this.room, required this.onSaved});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _capacity;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _amenitiesRaw;
  late final TextEditingController _displayOrder;
  late String _type;
  late bool _available;
  late int _count;
  bool _saving = false;
  File? _selectedImageFile;
  bool _uploadingImage = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _name = TextEditingController(text: r?.name ?? '');
    _price = TextEditingController(
        text: r != null ? r.pricePerNight.toString() : '');
    _capacity = TextEditingController(text: r?.capacity ?? '2 Persons');
    _description = TextEditingController(text: r?.description ?? '');
    _imageUrl = TextEditingController(text: r?.imageUrl ?? '');
    _amenitiesRaw = TextEditingController(
        text: r != null ? r.amenities.join(', ') : '');
    _displayOrder = TextEditingController(
        text: r != null ? r.displayOrder.toString() : '0');
    _type = r?.type ?? 'Non-AC';
    _available = r?.available ?? true;
    _count = r?.count ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _capacity.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _amenitiesRaw.dispose();
    _displayOrder.dispose();
    super.dispose();
  }

  void _showPhotoMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Room Photo',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _photoOption(
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF7C3AED),
              label: 'Take Photo',
              subtitle: 'Capture a new photo',
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            const SizedBox(height: 12),
            _photoOption(
              icon: Icons.image_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (_selectedImageFile != null) ...[
              const SizedBox(height: 12),
              _photoOption(
                icon: Icons.delete_rounded,
                iconColor: const Color(0xFFEF4444),
                label: 'Remove Photo',
                subtitle: 'Remove current photo',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImageFile = null;
                    _imageUrl.clear();
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedImageFile = File(result.files.single.path!));
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedImageFile = File(result.files.single.path!));
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;

    if (mounted) {
      setState(() {
        _uploadingImage = true;
        _uploadProgress = 0;
      });
    }

    try {
      print('[Photo Upload] Starting upload for: ${_selectedImageFile!.path}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://app.trimbakeshwarpoojavidhi.in/api/images/upload'),
      );

      final file = await http.MultipartFile.fromPath(
        'image',
        _selectedImageFile!.path,
      );
      request.files.add(file);

      print('[Photo Upload] Sending request...');

      // Simulate realistic progress while uploading
      Future.delayed(Duration.zero, () => _simulateProgress());

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Upload request timed out'),
      );

      print('[Photo Upload] Response received: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      print('[Photo Upload] Response status: ${response.statusCode}');
      print('[Photo Upload] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['filename'] != null) {
            final filename = data['filename'];
            print('[Photo Upload] Upload successful: $filename');

            if (mounted) {
              setState(() {
                _imageUrl.text = 'uploads/images/$filename';
                _uploadProgress = 1.0;
                _uploadingImage = false;
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Photo uploaded successfully'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        } catch (e) {
          print('[Photo Upload] JSON decode error: $e');
        }
      }

      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    } on TimeoutException catch (e) {
      print('[Photo Upload] Timeout error: $e');
      if (mounted) {
        setState(() {
          _selectedImageFile = null;
          _uploadingImage = false;
          _uploadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Upload timed out. Please try again.')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('[Photo Upload] Error: $e');
      if (mounted) {
        setState(() {
          _selectedImageFile = null;
          _uploadingImage = false;
          _uploadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Upload failed: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _simulateProgress() async {
    const steps = 20;
    const interval = Duration(milliseconds: 50);
    for (int i = 0; i < steps; i++) {
      if (!mounted || !_uploadingImage) break;
      await Future.delayed(interval);
      setState(() {
        _uploadProgress = (i + 1) / steps * 0.95;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.room != null;

    // Validate photo requirement: must have a photo (either new or existing)
    if (_selectedImageFile == null && _imageUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Please select a photo for the room')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If a new photo was selected, validate it was uploaded
    if (_selectedImageFile != null && _imageUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Photo upload failed. Please try again.')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final amenities = _amenitiesRaw.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    print('[Room Save] Saving room: ${_name.text}, count=$_count, imageUrl=${_imageUrl.text}');

    String? err;
    if (widget.room == null) {
      err = await AdminDataService.createRoom(
        name: _name.text.trim(),
        type: _type,
        pricePerNight: int.tryParse(_price.text.trim()) ?? 0,
        capacity: _capacity.text.trim(),
        amenities: amenities,
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        available: _available,
        displayOrder: int.tryParse(_displayOrder.text.trim()) ?? 0,
        count: _count,
      );
    } else {
      err = await AdminDataService.updateRoom(
        widget.room!.id,
        name: _name.text.trim(),
        type: _type,
        pricePerNight: int.tryParse(_price.text.trim()) ?? 0,
        capacity: _capacity.text.trim(),
        amenities: amenities,
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        available: _available,
        displayOrder: int.tryParse(_displayOrder.text.trim()) ?? 0,
        count: _count,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(err)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      print('[Room Save] Success! Response count field will be in dataNotifier');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.room == null
                    ? 'Room created successfully'
                    : 'Room updated successfully'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('[Room Save] Calling onSaved to refresh...');
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.room != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 100),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Room' : 'Add New Room',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _field(_name, 'Room Name', required: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_price, 'Price / Night (₹)',
                    keyboardType: TextInputType.number, required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_capacity, 'Capacity (e.g. 2 Persons)')),
              ]),
              const SizedBox(height: 12),
              // Type selector
              Row(children: [
                const Text('Type:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 12),
                _typeChip('Non-AC'),
                const SizedBox(width: 8),
                _typeChip('AC'),
              ]),
              const SizedBox(height: 16),
              // ── Room count stepper ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded,
                        size: 18, color: AdminColors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Number of Rooms',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Total rooms of this type',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    // Stepper
                    Row(
                      children: [
                        _stepBtn(Icons.remove_rounded,
                            _count > 1 ? () => setState(() => _count--) : null),
                        Container(
                          width: 44,
                          alignment: Alignment.center,
                          child: Text('$_count',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        _stepBtn(Icons.add_rounded,
                            _count < 999 ? () => setState(() => _count++) : null),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _field(_amenitiesRaw, 'Amenities (comma-separated)',
                  hint: 'e.g. Fan, Hot water, TV'),
              const SizedBox(height: 12),
              _field(_description, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              // Photo picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Room Photo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  // Photo preview section (both fresh uploads and existing images)
                  if ((_selectedImageFile != null || _imageUrl.text.isNotEmpty) && !_uploadingImage)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImageFile != null
                              ? Image.file(
                                  _selectedImageFile!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  'https://app.trimbakeshwarpoojavidhi.in/${_imageUrl.text}',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 40, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 18, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Upload Complete',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedImageFile != null
                                        ? _selectedImageFile!.path.split('/').last
                                        : _imageUrl.text.split('/').last,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showPhotoMenu(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 16, color: AdminColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Change Photo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  // Upload progress section
                  else if (_uploadingImage)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AdminColors.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: AdminColors.primary.withValues(alpha: 0.08),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Uploading photo...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.primary,
                                ),
                              ),
                              Text(
                                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AdminColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  // Initial state - tap to upload
                  else
                    GestureDetector(
                      onTap: _showPhotoMenu,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                size: 40, color: AdminColors.primary),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to upload photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PNG, JPG or PDF (max. 800x800px)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(_displayOrder, 'Display Order',
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Row(children: [
                  const Text('Available:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AdminColors.primary,
                  ),
                ]),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Save Changes' : 'Add Room',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: onTap != null
                ? AdminColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18,
              color: onTap != null ? AdminColors.primary : Colors.grey.shade400),
        ),
      );

  Widget _typeChip(String label) {
    final selected = _type == label;
    return GestureDetector(
      onTap: () => setState(() => _type = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AdminColors.primary
              : AdminColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AdminColors.primary)),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
