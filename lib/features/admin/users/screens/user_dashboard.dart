import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart'
    hide ClearSelection;
import 'package:savvy_stock/features/admin/users/blocs/user_bloc.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_event.dart';
import 'package:savvy_stock/features/admin/users/blocs/user_state.dart';
import 'package:savvy_stock/features/admin/users/models/user_model.dart';
import 'package:savvy_stock/features/admin/users/models/user_with_role.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class UserDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  final UserBloc userBloc;
  const UserDashboard({
    super.key,
    required this.authBloc,
    required this.userBloc,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadUsers(widget.authBloc.state.companyId!));
    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<UserBloc>().add(SearchUsers(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<UserBloc>().add(SearchUsers(''));
  }

  void _clearSelection() {
    context.read<UserBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _toggleUserSelection(UserModel user, bool selected) {
    context.read<UserBloc>().add(SelectUser(user, selected));
  }

  void _exportUser(UserModel user) {
    context.read<UserBloc>().add(ExportSingleUser(user));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User data exported')));
  }

  void _safeDeleteUser(BuildContext context, {int? index}) {
    final bloc = context.read<UserBloc>();
    final state = bloc.state;

    // CASE 1: Multiple users
    if (state.selectedUsers.isNotEmpty) {
      final usersToDelete = state.selectedUsers;

      showDeleteDialog(
        context,
        title: 'Delete selected users?',
        content:
            'Are you sure you want to delete ${usersToDelete.length} users?',
        onConfirm: () {
          final ids = usersToDelete.map((e) => e.id).toList();
          final deletedIndexes = usersToDelete
              .map((emp) => state.users.indexOf(emp))
              .toList();
          bloc.add(
            DeleteSelectedUsers(
              selectedUsers: ids,
              deletedUsers: usersToDelete,
              deletedIndexes: deletedIndexes,
            ),
          );
        },
      );
      return;
    }

    // CASE 2: Single user by index
    if (index == null || index < 0 || index >= state.filteredUsers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final userToDelete = state.filteredUsers[index];

    showDeleteDialog(
      context,
      title: 'Delete "${userToDelete.userName}"?',
      content: 'Are you sure you want to delete "${userToDelete.userName}"?',
      onConfirm: () {
        bloc.add(
          DeleteUser(
            deletedUser: userToDelete,
            deletedIndex: index,
            userId: userToDelete.id,
          ),
        );
      },
    );
  }

  void _onHorizontalDragUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final current = _dragOffset[index] ?? 0;
      var newOffset = current + details.delta.dx;

      // only allow left swipe
      if (newOffset > 0) newOffset = 0;
      _dragOffset[index] = newOffset;
    });
  }

  void _onHorizontalDragEnd(
    BuildContext context,
    int index,
    DragEndDetails details,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3; // ✅ 30% of screen width
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -screenWidth; // slide fully left
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _safeDeleteUser(context, index: index);
        setState(() {
          _dragOffset.remove(index);
        });
      });
    } else {
      // Not far enough → snap back
      setState(() {
        _dragOffset[index] = 0.0;
      });
    }
  }

  void _navigateToAddScreen() {
    // Navigate to add user screen
    context.push(AppRoutes.userCreation);
  }

  void _navigateToEditScreen(UserModel user) {
    // You need to get the UserWithRole from your state
    final userState = context.read<UserBloc>().state;
    final userWithRole = userState.getUserWithRole(
      user.id,
    ); // Use the safe method we added

    if (userWithRole != null) {
      context.push(AppRoutes.userEdit, extra: userWithRole);
    } else {
      // Fallback: create a basic UserWithRole
      final fallbackUserWithRole = UserWithRole(user: user, roles: []);
      context.push(AppRoutes.userEdit, extra: fallbackUserWithRole);
    }
  }

  UserWithRole _safeFindUserWithRole(UserState state, UserModel user) {
    try {
      return state.usersWithRole.firstWhere(
        (userWithRole) => userWithRole.user.id == user.id,
      );
    } catch (e) {
      // Return a default UserWithRole if not found
      return UserWithRole(user: user, roles: []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('User List')),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state.usersWithRole.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.usersWithRole.isEmpty && _isSelectionMode) {
            setState(() {
              _isSelectionMode = false;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  // Header with Search and Actions
                  _buildSearchBar(),
                  _buildActionButtons(state),
                  // user List
                  Expanded(child: _buildUserList(state)),
                ],
              ),
            ],
          );
        },
      ),

      // Floating Action Button for Add
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _handleSearch,
      ),
    );
  }

  Widget _buildActionButtons(UserState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: state.hasSelection ? 60 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: state.hasSelection
          ? Row(
              children: [
                Text(
                  '${state.selectedUsers.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (state.canDelete)
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: () => _safeDeleteUser(context),
                    tooltip: 'Delete selected',
                  ),
                if (state.canEdit)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final user = state.selectedUsers.first;
                      _navigateToEditScreen(user);
                    },
                    tooltip: 'Edit user',
                  ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => _clearSelection(),
                  tooltip: 'Clear selection',
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return FloatingActionButton(
          onPressed: () {
            if (state.canEdit) {
              // Navigate to edit screen with selected user
              final user = state.selectedUsers.first;
              _navigateToEditScreen(user);
            } else {
              // Navigate to add screen
              _navigateToAddScreen();
            }
          },
          backgroundColor: Color.fromARGB(255, 28, 66, 146),
          child: Icon(
            state.canEdit ? Icons.edit : Icons.add,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildUserList(UserState state) {
    if (state.status == UserStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == UserStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Failed to load users',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<UserBloc>().add(
                LoadUsers(widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.people, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No users found'
                  : 'No results for "${state.searchQuery}"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredUsers.length,
      itemBuilder: (context, index) {
        final user = state.filteredUsers[index];
        final isSelected = state.selectedUsers.contains(user);
        final screenWidth = MediaQuery.of(context).size.width;
        final useCompactLayout = screenWidth < 700;

        return _buildUserListItem(
          user,
          isSelected,
          state,
          index,
          useCompactLayout,
        );
      },
    );
  }

  Widget _buildUserListItem(
    UserModel user,
    bool isSelected,
    UserState state,
    int index,
    bool isCompact,
  ) {
    final offset = _dragOffset[index] ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleUserSelection(user, !isSelected);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleUserSelection(user, !isSelected);
      },
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(index, details),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(context, index, details),
      child: Stack(
        children: [
          // Background (delete indicator)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.amber, // Changed to red for delete action
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
          ),

          // user card
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(offset, 0, 0),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isSelected
                    ? const Color.fromARGB(255, 28, 66, 146)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildUserAvatar(user, isSelected, isCompact),
              title: Text(
                '${user.userName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: _buildUserSubtitle(user),
              trailing: _buildUserTrailing(isSelected),
            ),
          ),
        ],
      ),
    );
  }

  // Separate method for user avatar
  Widget _buildUserAvatar(UserModel user, bool isSelected, bool isCompact) {
    // Define colors based on user status
    final Color backgroundColor;
    final Color iconColor;

    if (isSelected) {
      backgroundColor = const Color.fromARGB(255, 28, 66, 146);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.grey[200]!;
      iconColor = Colors.grey[600]!;
    }

    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.profile_circle,
            color: iconColor,
            size: isCompact ? 20 : 24,
          ),
        ),
        // User status badge
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.verify, size: 12, color: Colors.green),
          ),
        ),
      ],
    );
  }

  // Separate method for user subtitle
  Widget _buildUserSubtitle(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show position/title if available
        if (user.usercol != null && user.usercol!.isNotEmpty)
          Text(
            user.usercol!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        Text(
          user.id.toString(),
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),

        // Contact information
        Text(
          '📧 ${user.userEmail}',
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),

        // User status badge
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Text(
            'System User',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Separate method for trailing widget
  Widget _buildUserTrailing(bool isSelected) {
    if (isSelected) {
      return const Icon(
        Iconsax.tick_circle,
        color: Color.fromARGB(255, 28, 66, 146),
      );
    }

    // Show user type indicator when not selected
    return Icon(Iconsax.user, color: Colors.green, size: 20);
  }
}
