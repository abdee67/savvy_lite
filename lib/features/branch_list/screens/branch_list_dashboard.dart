// features/role/screens/role_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:savvy_stock/core/constants/app_routes.dart';
import 'package:savvy_stock/core/utils/ui_helper.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_bloc.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_event.dart';
import 'package:savvy_stock/features/branch_list/blocs/branch_list_state.dart';
import 'package:savvy_stock/features/branch_list/models/branch_list_model.dart';
import 'package:savvy_stock/features/auth/blocs/auth_bloc.dart';

class BranchDashboard extends StatefulWidget {
  final AuthBloc authBloc;
  const BranchDashboard({super.key, required this.authBloc});

  @override
  State<BranchDashboard> createState() => _BranchDashboardState();
}

class _BranchDashboardState extends State<BranchDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Map<int, double> _dragOffset = {};

  @override
  void initState() {
    super.initState();
    context.read<BranchBloc>().add(
      LoadBranchs(widget.authBloc.state.companyId!),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<BranchBloc>().add(SearchBranchs(query));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<BranchBloc>().add(SearchBranchs(''));
  }

  void _toggleBranchSelection(Branch branch, bool selected) {
    context.read<BranchBloc>().add(SelectBranch(branch, selected));
  }

  void _clearSelection() {
    context.read<BranchBloc>().add(ClearSelection());
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _navigateToEditScreen(Branch branch) {
    context.push(AppRoutes.branchEdit, extra: branch);
  }

  void _navigateToAddScreen() {
    context.push(AppRoutes.branchCreation);
  }

  void _safeDelete(BuildContext context, {int? index}) {
    final bloc = context.read<BranchBloc>();
    final state = bloc.state;

    // CASE 1: Multiple users
    if (state.selectedBranchs.isNotEmpty) {
      final branchesToDelete = state.selectedBranchs;

      showDeleteDialog(
        context,
        title: 'Delete selected branches?',
        content:
            'Are you sure you want to delete ${branchesToDelete.length} branches?',
        onConfirm: () {
          final ids = branchesToDelete.map((e) => e.id).toList();
          final deletedIndexes = branchesToDelete
              .map((emp) => state.branchs.indexOf(emp))
              .toList();
          bloc.add(
            DeleteSelectedBranchs(
              selectedBranchs: ids,
              deletedBranchs: branchesToDelete,
              deletedIndexes: deletedIndexes,
            ),
          );
        },
      );
      return;
    }

    // CASE 2: Single branch by index
    if (index == null || index < 0 || index >= state.filteredBranchs.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item. Invalid index.')),
      );
      return;
    }

    final branchToDelete = state.filteredBranchs[index];

    showDeleteDialog(
      context,
      title: 'Delete "${branchToDelete.description}"?',
      content:
          'Are you sure you want to delete "${branchToDelete.description}"?',
      onConfirm: () {
        bloc.add(
          DeleteBranch(
            deletedBranch: branchToDelete,
            deletedIndex: index,
            branchId: branchToDelete.id,
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
    final threshold = screenWidth * 0.3;
    final current = _dragOffset[index] ?? 0;
    if (current.abs() > threshold) {
      // Swipe far enough → delete
      setState(() {
        _dragOffset[index] = -screenWidth;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _safeDelete(context, index: index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Branch Management'),
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<BranchBloc, BranchState>(
        listener: (context, state) {
          if (state.status == BranchStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Operation failed'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == BranchStatus.success &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              _buildActionButtons(state),

              // Role List
              Expanded(child: _buildRoleList(state)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: const Color.fromARGB(255, 28, 66, 146),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButtons(BranchState state) {
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
                  '${state.selectedBranchs.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (state.canDelete)
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: () => _safeDelete(context),
                    tooltip: 'Delete selected',
                  ),
                if (state.canEdit)
                  IconButton(
                    icon: const Icon(
                      Iconsax.edit,
                      color: Color.fromARGB(255, 28, 66, 146),
                    ),
                    onPressed: () {
                      final branch = state.selectedBranchs.first;
                      _navigateToEditScreen(branch);
                    },
                    tooltip: 'Edit branch',
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
          hintText: 'Search by branch description or address...',
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

  Widget _buildRoleList(BranchState state) {
    if (state.status == BranchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == BranchStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message ?? 'Failed to load branches',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<BranchBloc>().add(
                LoadBranchs(widget.authBloc.state.companyId!),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredBranchs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.user_tag, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isEmpty
                  ? 'No roles found'
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
      itemCount: state.filteredBranchs.length,
      itemBuilder: (context, index) {
        final branch = state.filteredBranchs[index];
        final isSelected = state.selectedBranchs.contains(branch);
        final screenWidth = MediaQuery.of(context).size.width;
        final useCompactLayout = screenWidth < 700;

        return _buildBranchListItem(
          branch,
          state,
          isSelected,
          index,
          useCompactLayout,
        );
      },
    );
  }

  Widget _buildBranchListItem(
    Branch branch,
    BranchState state,
    bool isSelected,
    int index,
    bool isCompact,
  ) {
    final offset = _dragOffset[index] ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleBranchSelection(branch, !isSelected);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleBranchSelection(branch, !isSelected);
      },
      onDoubleTap: () => _navigateToEditScreen(branch),
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
                color: Colors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
          ),

          // Role card
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
              leading: _buildBranchAvatar(branch, isSelected, isCompact),
              title: Text(
                branch.description!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: _buildBranchSubtitle(branch),
              trailing: _buildBranchTrailing(branch),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchAvatar(Branch branch, bool isSelected, bool isCompact) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Iconsax.user_tag,
        color: Colors.white,
        size: isCompact ? 20 : 24,
      ),
    );
  }

  Widget _buildBranchSubtitle(Branch branch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          branch.description!,
          style: const TextStyle(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            '${branch.addressLine}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchTrailing(Branch branch) {
    return const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 20);
  }
}
