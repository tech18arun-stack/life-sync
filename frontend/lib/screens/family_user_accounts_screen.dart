import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';

/// Screen for managing family member user accounts
class FamilyUserAccountsScreen extends StatefulWidget {
  const FamilyUserAccountsScreen({super.key});

  @override
  State<FamilyUserAccountsScreen> createState() =>
      _FamilyUserAccountsScreenState();
}

class _FamilyUserAccountsScreenState extends State<FamilyUserAccountsScreen> {
  List<User> _familyMembers = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => _isLoading = true);
    final members = await _authService.getFamilyMemberUsers();
    setState(() {
      _familyMembers = members;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColor
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Family User Accounts'),
        backgroundColor: isDark
            ? AppTheme.backgroundColor
            : const Color(0xFFF5F5F5),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rotate),
            onPressed: _loadFamilyMembers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _familyMembers.isEmpty
          ? _buildEmptyState(isDark)
          : _buildMembersList(isDark),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_family_user',
        onPressed: () => _showAddMemberDialog(context),
        icon: const FaIcon(FontAwesomeIcons.userPlus),
        label: const Text('Add User'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.userGroup,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Family User Accounts Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add family members with their own login credentials. They\'ll have access to the same data.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondary : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(context),
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('Add First User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _familyMembers.length,
      itemBuilder: (context, index) {
        final member = _familyMembers[index];
        return _buildMemberCard(member, isDark);
      },
    );
  }

  Widget _buildMemberCard(User member, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark
                      ? AppTheme.textPrimary
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: member.isActive
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10,
                  color: member.isActive
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.envelope,
                  size: 12,
                  color: isDark ? AppTheme.textTertiary : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  member.email,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (member.relation != null && member.relation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.heart,
                    size: 12,
                    color: isDark ? AppTheme.textTertiary : Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    member.relation!,
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (member.phone != null && member.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.phone,
                    size: 12,
                    color: isDark ? AppTheme.textTertiary : Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    member.phone!,
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(
            Icons.more_vert,
            color: isDark ? AppTheme.textSecondary : Colors.grey[600],
          ),
          color: isDark ? AppTheme.cardColor : Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.pen,
                    size: 16,
                    color: isDark ? AppTheme.textPrimary : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset-password',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.key,
                    size: 16,
                    color: isDark ? AppTheme.textPrimary : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle-active',
              child: Row(
                children: [
                  FaIcon(
                    member.isActive
                        ? FontAwesomeIcons.userSlash
                        : FontAwesomeIcons.userCheck,
                    size: 16,
                    color: isDark ? AppTheme.textPrimary : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    member.isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.trash,
                    size: 16,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditMemberDialog(context, member);
                break;
              case 'reset-password':
                _showResetPasswordDialog(context, member);
                break;
              case 'toggle-active':
                _toggleMemberActive(member);
                break;
              case 'delete':
                _showDeleteConfirmation(context, member);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditFamilyUserSheet(onSaved: _loadFamilyMembers),
    );
  }

  void _showEditMemberDialog(BuildContext context, User member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddEditFamilyUserSheet(member: member, onSaved: _loadFamilyMembers),
    );
  }

  void _showResetPasswordDialog(BuildContext context, User member) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.cardColor : Colors.white,
        title: Text(
          'Reset Password for ${member.name}',
          style: TextStyle(color: isDark ? AppTheme.textPrimary : null),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  fillColor: isDark ? AppTheme.surfaceColor : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a password';
                  if (value.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  fillColor: isDark ? AppTheme.surfaceColor : Colors.grey[50],
                ),
                validator: (value) {
                  if (value != passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppTheme.textSecondary : null),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final result = await _authService.resetFamilyMemberPassword(
                  memberId: member.id!,
                  newPassword: passwordController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success']
                            ? 'Password reset successfully'
                            : result['error'],
                      ),
                      backgroundColor: result['success']
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMemberActive(User member) async {
    final result = await _authService.updateFamilyMemberUser(
      memberId: member.id!,
      isActive: !member.isActive,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success']
                ? 'Account ${member.isActive ? 'deactivated' : 'activated'}'
                : result['error'],
          ),
          backgroundColor: result['success']
              ? AppTheme.successColor
              : AppTheme.errorColor,
        ),
      );
      if (result['success']) _loadFamilyMembers();
    }
  }

  void _showDeleteConfirmation(BuildContext context, User member) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.cardColor : Colors.white,
        title: Text(
          'Delete User Account',
          style: TextStyle(color: isDark ? AppTheme.textPrimary : null),
        ),
        content: Text(
          'Are you sure you want to delete ${member.name}\'s account? This action cannot be undone.',
          style: TextStyle(color: isDark ? AppTheme.textSecondary : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppTheme.textSecondary : null),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _authService.deleteFamilyMemberUser(
                member.id!,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['success'] ? 'Account deleted' : result['error'],
                    ),
                    backgroundColor: result['success']
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                );
                if (result['success']) _loadFamilyMembers();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Add/Edit Family User Bottom Sheet
class AddEditFamilyUserSheet extends StatefulWidget {
  final User? member;
  final VoidCallback onSaved;

  const AddEditFamilyUserSheet({super.key, this.member, required this.onSaved});

  @override
  State<AddEditFamilyUserSheet> createState() => _AddEditFamilyUserSheetState();
}

class _AddEditFamilyUserSheetState extends State<AddEditFamilyUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _relationController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _relationController = TextEditingController(
      text: widget.member?.relation ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (widget.member == null) {
      // Create new family member user
      result = await _authService.createFamilyMemberUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        relation: _relationController.text.trim().isNotEmpty
            ? _relationController.text.trim()
            : null,
      );
    } else {
      // Update existing family member
      result = await _authService.updateFamilyMemberUser(
        memberId: widget.member!.id!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        relation: _relationController.text.trim().isNotEmpty
            ? _relationController.text.trim()
            : null,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.member == null
                  ? 'Family user account created'
                  : 'Account updated',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'An error occurred'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.member == null
                        ? 'Add Family User Account'
                        : 'Edit Family User',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimary : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppTheme.textSecondary : null,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.circleInfo,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Family members can log in with their own credentials and access all shared family data.',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: const Icon(Icons.person_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.surfaceColor
                            : Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter a name';
                        if (value.length < 2)
                          return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled:
                          widget.member ==
                          null, // Can't change email for existing user
                      style: TextStyle(
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.surfaceColor
                            : Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter an email';
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password fields (only for new user)
                    if (widget.member == null) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimary : null,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.surfaceColor
                              : Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter a password';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimary : null,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.surfaceColor
                              : Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value != _passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Relation Field
                    TextFormField(
                      controller: _relationController,
                      style: TextStyle(
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Relation',
                        hintText: 'e.g., Spouse, Child, Parent',
                        prefixIcon: const Icon(Icons.favorite_border),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.surfaceColor
                            : Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.surfaceColor
                            : Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.member == null
                            ? 'Create Account'
                            : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
