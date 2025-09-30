import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_bloc.dart';
import 'package:savvy_stock/features/admin/role/blocs/role_event.dart';
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
  UserModel? _selectedUser;
  bool _userDetail = false;

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

  void _showUserDetail(UserModel user) {
    context.read<UserBloc>().add(ClearSelection());
    setState(() {
      _selectedUser = user;
      _userDetail = true;
    });
    context.read<RoleBloc>().add(LoadRoles(widget.authBloc.state.companyId!));
  }

  void _hideUserDetail() {
    context.read<UserBloc>().add(ClearSelection());
    setState(() {
      _userDetail = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _selectedUser = null;
          });
        }
      });
    });
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

  void _callUser(String phone) {
    // Implement phone call functionality
    print('Calling: $phone');
  }

  void _emailUser(String? email) {
    if (email != null) {
      // Implement email functionality
      print('Emailing: $email');
    }
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
              .map((emp) => state.user.indexOf(emp))
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
    // Navigate to edit user screen
    context.push(AppRoutes.userEdit, extra: user);
  }

  UserWithRole _safeFindUserWithRole(UserState state, UserModel user) {
    try {
      return state.usersRole.firstWhere(
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
          if (state.user.isNotEmpty && !_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          } else if (state.user.isEmpty && _isSelectionMode) {
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

              // Detail Panel
              if (_userDetail && _selectedUser != null)
                _buildDetailPanel(_selectedUser!),
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
              final user = state.user.first;
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
        } else {
          // Single tap shows detail when not in selection mode
          _showUserDetail(user);
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
      onDoubleTap: () => _showUserDetail(user),
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

  Widget _buildDetailPanel(UserModel user) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.success && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Builder(
            builder: (context) {
              final size = MediaQuery.of(context).size;
              final screenWidth = size.width;
              final screenHeight = size.height;
              final panelHeight = screenHeight * 0.4; // finite height
              final useHorizontalLayout = screenWidth > 500;
              final useCompactLayout = screenWidth < 500;

              final userWithRole = _safeFindUserWithRole(state, user);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                height: panelHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey[50]!],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Section
                    _buildDetailHeader(
                      user,
                      state,
                      userWithRole,
                      useHorizontalLayout,
                      useCompactLayout,
                    ),

                    // Content Section
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(useCompactLayout ? 12 : 20),
                        child: _buildContentSection(
                          user,
                          state,
                          useHorizontalLayout,
                          useCompactLayout,
                        ),
                      ),
                    ),

                    // Footer Actions
                    // if (!state.isRoleManagementMode)
                    //  _buildDetailFooter(user, useCompactLayout),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Add this new method:
  Widget _buildContentSection(
    UserModel user,
    UserState state,
    bool useHorizontal,
    bool isCompact,
  ) {
    // Show basic user info for all users
    return _builduserInfoView(user, state, useHorizontal, isCompact);
  }

  Widget _buildDetailHeader(
    UserModel user,
    UserState state,
    UserWithRole? userWithRole,
    bool isUser,
    bool isCompact,
  ) {
    // Safe role names extraction
    final roleNames =
        userWithRole?.roles.map((r) => r.name).join(', ') ??
        'No roles assigned';

    // Safe user name with null check
    final String safeUserName = user.userName ?? 'Unknown User';
    final String displayInitials = safeUserName.length > 2
        ? safeUserName.substring(0, 2).toUpperCase()
        : safeUserName.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: isCompact ? 40 : 60,
            height: 4,
            margin: EdgeInsets.only(bottom: isCompact ? 4 : 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Row(
            children: [
              // Avatar and basic info
              Expanded(
                child: Row(
                  children: [
                    // Avatar with user status indicator
                    Stack(
                      children: [
                        Container(
                          width: isCompact ? 40 : 50,
                          height: isCompact ? 40 : 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isUser
                                  ? [Color(0xFF10b981), Color(0xFF059669)]
                                  : [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              displayInitials,
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: isCompact ? 12 : 16,
                            height: isCompact ? 12 : 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.check,
                              size: isCompact ? 8 : 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: isCompact ? 8 : 12),

                    // Name and user status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safeUserName,
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            roleNames,
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action button - ONLY show role management for users
              _buildMainActionButton(user, isCompact, context),

              SizedBox(width: 8),

              // Close button
              Container(
                width: isCompact ? 32 : 36,
                height: isCompact ? 32 : 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close, size: isCompact ? 16 : 18),
                  onPressed: _hideUserDetail,
                  padding: EdgeInsets.zero,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Separate method for main action button
  Widget _buildMainActionButton(
    UserModel user,
    bool isCompact,
    BuildContext context,
  ) {
    return ElevatedButton(
      onPressed: () =>
          context.push(AppRoutes.userManagement, extra: {'user': user}),

      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 8,
        ),
      ),
      child: Text('Edit User', style: TextStyle(fontSize: isCompact ? 12 : 14)),
    );
  }
}

Widget _builduserInfoView(
  UserModel user,
  UserState state,
  bool useHorizontal,
  bool isCompact,
) {
  // Safe values with null checks
  final String safeUserName = user.userName ?? 'No username';
  final String safeUserEmail = user.userEmail ?? 'No email';
  final String safeUserId = user.id.toString();

  if (useHorizontal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information
        Expanded(
          child: _buildInfoSection(
            title: 'Personal Information',
            icon: Iconsax.profile_circle,
            color: Color(0xFF667eea),
            isCompact: isCompact,
            children: [
              _buildInfoItem('User ID', safeUserId, Iconsax.card, isCompact),
              _buildInfoItem(
                'User Name',
                safeUserName,
                Iconsax.user,
                isCompact,
              ),
              _buildInfoItem('Email', safeUserEmail, Iconsax.user, isCompact),
            ],
          ),
        ),
        SizedBox(width: isCompact ? 12 : 20),
      ],
    );
  } else {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoSection(
            title: 'Personal Information',
            icon: Iconsax.profile_circle,
            color: Color(0xFF667eea),
            isCompact: isCompact,
            children: [
              _buildInfoItem('User ID', safeUserId, Iconsax.card, isCompact),
              _buildInfoItem(
                'User Name',
                safeUserName,
                Iconsax.user,
                isCompact,
              ),
              _buildInfoItem('Email', safeUserEmail, Iconsax.user, isCompact),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildInfoSection({
  required String title,
  required IconData icon,
  required Color color,
  required bool isCompact,
  required List<Widget> children,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey[100]!, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        // Section content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

Widget _buildInfoItem(
  String label,
  String value,
  IconData icon,
  bool isCompact,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
