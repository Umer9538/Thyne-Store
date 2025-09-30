import 'package:flutter/material.dart';
import '../../../utils/theme.dart';
import '../../../services/api_service.dart';

class CustomersManagementScreen extends StatefulWidget {
  const CustomersManagementScreen({super.key});

  @override
  State<CustomersManagementScreen> createState() => _CustomersManagementScreenState();
}

class _CustomersManagementScreenState extends State<CustomersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int _page = 1;
  final int _limit = 20;
  List<dynamic> _users = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool reset = true}) async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> resp;
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        resp = await ApiService.adminSearchUsers(query: query, page: _page, limit: _limit);
      } else {
        resp = await ApiService.adminGetUsers(page: _page, limit: _limit);
      }
      final data = (resp['data'] ?? {}) as Map<String, dynamic>;
      final users = (data['users'] ?? []) as List<dynamic>;
      final pagination = (data['pagination'] ?? {}) as Map<String, dynamic>;
      setState(() {
        if (reset) {
          _users = users;
        } else {
          _users.addAll(users);
        }
        _total = (pagination['total'] ?? _users.length) as int;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(String userId, bool isActive) async {
    setState(() => _isLoading = true);
    try {
      if (isActive) {
        await ApiService.adminDeactivateUser(userId);
      } else {
        await ApiService.adminActivateUser(userId);
      }
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdmin(String userId, bool isAdmin) async {
    setState(() => _isLoading = true);
    try {
      if (isAdmin) {
        await ApiService.adminRemoveUserAdmin(userId);
      } else {
        await ApiService.adminMakeUserAdmin(userId);
      }
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email or phone',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      _page = 1;
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _page = 1;
                    _loadUsers();
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      _page = 1;
                      await _loadUsers();
                    },
                    child: ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = (_users[index] as Map<String, dynamic>);
                        final id = (u['id'] ?? u['_id'] ?? '') as String;
                        final name = (u['name'] ?? '') as String;
                        final email = (u['email'] ?? '') as String;
                        final phone = (u['phone'] ?? '') as String;
                        final isActive = (u['isActive'] ?? true) as bool;
                        final isAdmin = (u['isAdmin'] ?? false) as bool;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                            child: Icon(Icons.person, color: AppTheme.primaryGold),
                          ),
                          title: Text(name.isNotEmpty ? name : email),
                          subtitle: Text([email, phone].where((e) => e.isNotEmpty).join(' • ')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: isActive ? 'Deactivate' : 'Activate',
                                child: IconButton(
                                  icon: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.red : Colors.green),
                                  onPressed: id.isEmpty ? null : () => _toggleActive(id, isActive),
                                ),
                              ),
                              Tooltip(
                                message: isAdmin ? 'Revoke admin' : 'Make admin',
                                child: IconButton(
                                  icon: Icon(Icons.shield, color: isAdmin ? Colors.orange : Colors.grey),
                                  onPressed: id.isEmpty ? null : () => _toggleAdmin(id, isAdmin),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (_users.length < _total)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _page += 1;
                        _loadUsers(reset: false);
                      },
                child: _isLoading ? const CircularProgressIndicator() : const Text('Load more'),
              ),
            ),
        ],
      ),
    );
  }
}


