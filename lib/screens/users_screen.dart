import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminData>(
      valueListenable: AdminDataService.dataNotifier,
      builder: (_, data, __) {
        // Check for error state
        return ValueListenableBuilder<String?>(
          valueListenable: AdminDataService.errorNotifier,
          builder: (_, error, __) {
            if (error != null && data.users.isEmpty) {
              return _buildEmptyState(error);
            }
            if (data.users.isEmpty) {
              return _buildEmptyState('No registered users yet.');
            }
            return _buildUserList(data.users);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 72, color: AdminColors.grey400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AdminColors.grey500,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<AdminUser> users) {
    // Sort by latest registered first
    final sortedUsers = [...users]..sort((a, b) {
      final dateA = a.createdAt ?? DateTime(1970);
      final dateB = b.createdAt ?? DateTime(1970);
      return dateB.compareTo(dateA); // Descending order (latest first)
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) => _UserCard(user: sortedUsers[index], index: index),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final int index;

  const _UserCard({required this.user, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(),
            const SizedBox(width: 14),
            Expanded(child: _details()),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: AdminColors.appBarGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.fullName.isEmpty ? 'Unknown' : user.fullName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _infoRow(Icons.phone_rounded, user.phone),
        if (user.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          _infoRow(Icons.email_outlined, user.email),
        ],
        const SizedBox(height: 4),
        _infoRow(
          Icons.location_on_outlined,
          [
            if (user.city.isNotEmpty) user.city,
            if (user.pinCode.isNotEmpty) user.pinCode,
            if (user.country.isNotEmpty) user.country,
          ].join(', '),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    if (text.isEmpty || text == ', ') return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AdminColors.grey500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 13, color: AdminColors.grey700, height: 1.3),
          ),
        ),
      ],
    );
  }
}
