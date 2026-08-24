import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
      itemBuilder: (context, index) => _UserCard(user: sortedUsers[index]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;

  const _UserCard({required this.user});

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: user.phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: user.phone.isNotEmpty ? () => _call(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _avatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? 'Unknown' : user.fullName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.phone.isEmpty ? 'No phone number' : user.phone,
                        style: TextStyle(fontSize: 13.5, color: AdminColors.grey600),
                      ),
                    ],
                  ),
                ),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.call_rounded, color: Colors.black, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AdminColors.appBarGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

}
