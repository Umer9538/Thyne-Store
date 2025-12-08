import 'package:flutter/material.dart';
import 'package:thyne_jewls/utils/theme.dart';
import 'package:thyne_jewls/services/api_service.dart';
import 'package:thyne_jewls/models/user.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _loading = true;
  List<User> _users = [];
  String _searchQuery = '';
  String _roleFilter = 'All'; // All, Admin, Customer
  String _statusFilter = 'All'; // All, Active, Inactive
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  final int _pageSize = 20;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);

    try {
      Map<String, dynamic> response;

      if (_searchQuery.isNotEmpty) {
        response = await ApiService.adminSearchUsers(
          query: _searchQuery,
          page: _currentPage,
          limit: _pageSize,
        );
      } else {
        response = await ApiService.adminGetUsers(
          page: _currentPage,
          limit: _pageSize,
        );
      }

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final usersList = (data['users'] as List?) ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;

        _users = usersList
            .map((u) => User.fromJson(u as Map<String, dynamic>))
            .toList();

        if (pagination != null) {
          _totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
          _totalUsers = (pagination['total'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      // Role filter
      if (_roleFilter == 'Admin' && !user.isAdmin) return false;
      if (_roleFilter == 'Customer' && user.isAdmin) return false;

      // Status filter
      if (_statusFilter == 'Active' && !user.isActive) return false;
      if (_statusFilter == 'Inactive' && user.isActive) return false;

      return true;
    }).toList();
  }

  Future<void> _toggleAdminStatus(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isAdmin ? 'Remove Admin?' : 'Make Admin?'),
        content: Text(
          user.isAdmin
              ? 'Are you sure you want to remove admin privileges from ${user.name}?'
              : 'Are you sure you want to make ${user.name} an admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isAdmin ? Colors.orange : AppTheme.primaryGold,
            ),
            child: Text(user.isAdmin ? 'Remove Admin' : 'Make Admin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        Map<String, dynamic> response;
        if (user.isAdmin) {
          response = await ApiService.adminRemoveUserAdmin(user.id);
        } else {
          response = await ApiService.adminMakeUserAdmin(user.id);
        }

        if (mounted) {
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  user.isAdmin
                      ? 'Admin privileges removed from ${user.name}'
                      : '${user.name} is now an admin',
                ),
                backgroundColor: Colors.green,
              ),
            );
            _loadUsers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response['error']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleActiveStatus(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Deactivate User?' : 'Activate User?'),
        content: Text(
          user.isActive
              ? 'Are you sure you want to deactivate ${user.name}? They will not be able to login.'
              : 'Are you sure you want to activate ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        Map<String, dynamic> response;
        if (user.isActive) {
          response = await ApiService.adminDeactivateUser(user.id);
        } else {
          response = await ApiService.adminActivateUser(user.id);
        }

        if (mounted) {
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  user.isActive
                      ? '${user.name} has been deactivated'
                      : '${user.name} has been activated',
                ),
                backgroundColor: Colors.green,
              ),
            );
            _loadUsers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response['error']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showUserDetails(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // User Avatar and Name
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                            backgroundImage: user.profileImage != null
                                ? NetworkImage(user.profileImage!)
                                : null,
                            child: user.profileImage == null
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (user.isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (user.isAdmin) const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.isActive
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyle(
                                    color: user.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Contact Info
                    _buildDetailRow(Icons.email, 'Email', user.email),
                    _buildDetailRow(Icons.phone, 'Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Member Since',
                      DateFormat('MMM d, yyyy').format(user.createdAt),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Actions
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Admin Button
                    ListTile(
                      leading: Icon(
                        user.isAdmin ? Icons.admin_panel_settings : Icons.person_add,
                        color: user.isAdmin ? Colors.orange : AppTheme.primaryGold,
                      ),
                      title: Text(user.isAdmin ? 'Remove Admin' : 'Make Admin'),
                      subtitle: Text(
                        user.isAdmin
                            ? 'Remove admin privileges from this user'
                            : 'Grant admin access to this user',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _toggleAdminStatus(user);
                      },
                    ),

                    // Toggle Active Button
                    ListTile(
                      leading: Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        color: user.isActive ? Colors.red : Colors.green,
                      ),
                      title: Text(user.isActive ? 'Deactivate User' : 'Activate User'),
                      subtitle: Text(
                        user.isActive
                            ? 'Prevent this user from logging in'
                            : 'Allow this user to login again',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _toggleActiveStatus(user);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name, email, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _currentPage = 1;
                              _loadUsers();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _currentPage = 1;
                    _loadUsers();
                  },
                ),
                const SizedBox(height: 12),

                // Filters
                Row(
                  children: [
                    // Role Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _roleFilter,
                            isExpanded: true,
                            items: ['All', 'Admin', 'Customer']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _roleFilter = value!);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            isExpanded: true,
                            items: ['All', 'Active', 'Inactive']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _statusFilter = value!);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: $_totalUsers users',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Showing ${_filteredUsers.length} users',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) =>
                              _buildUserCard(_filteredUsers[index]),
                        ),
                      ),
          ),

          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                backgroundImage: user.profileImage != null
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: user.isActive ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: user.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(user.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'toggle_admin') {
                    _toggleAdminStatus(user);
                  } else if (value == 'toggle_active') {
                    _toggleActiveStatus(user);
                  } else if (value == 'view') {
                    _showUserDetails(user);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_admin',
                    child: Row(
                      children: [
                        Icon(
                          user.isAdmin
                              ? Icons.remove_moderator
                              : Icons.admin_panel_settings,
                          size: 20,
                          color: user.isAdmin ? Colors.orange : AppTheme.primaryGold,
                        ),
                        const SizedBox(width: 8),
                        Text(user.isAdmin ? 'Remove Admin' : 'Make Admin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_active',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                          color: user.isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(user.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
