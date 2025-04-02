// watchlist_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../auth/auth_services.dart';
import '../models/watchlist_model.dart';
import '../services/watchlist_service.dart';

class WatchlistManagementScreen extends StatefulWidget {
  const WatchlistManagementScreen({super.key});

  @override
  State<WatchlistManagementScreen> createState() => _WatchlistManagementScreenState();
}

class _WatchlistManagementScreenState extends State<WatchlistManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final watchlistService = context.watch<WatchlistService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Watchlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateWatchlistDialog(context, user),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: watchlistService.getWatchlists(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No watchlists found'));
          }

          final watchlists = snapshot.data!.docs;

          return ListView.builder(
            itemCount: watchlists.length,
            itemBuilder: (context, index) {
              final watchlist = Watchlist.fromFirestore(watchlists[index]);
              return _buildWatchlistTile(watchlist, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildWatchlistTile(Watchlist watchlist, User? user) {
    return ListTile(
      title: Text(watchlist.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditWatchlistDialog(context, watchlist, user),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteWatchlist(watchlist.id, user?.uid),
          ),
        ],
      ),
    );
  }

  void _showCreateWatchlistDialog(BuildContext context, User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Watchlist'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Watchlist Name'),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance
                    .collection('users/${user?.uid}/watchlists')
                    .add({
                  'name': _nameController.text,
                  'items': [],
                  'sortOrder': 'manual',
                  'createdAt': FieldValue.serverTimestamp()
                });
                _nameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditWatchlistDialog(BuildContext context, Watchlist watchlist, User? user) {
    _nameController.text = watchlist.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Watchlist'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'New Name'),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance
                    .collection('users/${user?.uid}/watchlists')
                    .doc(watchlist.id)
                    .update({'name': _nameController.text});
                _nameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWatchlist(String watchlistId, String? userId) async {
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users/$userId/watchlists')
        .doc(watchlistId)
        .delete();
  }
}