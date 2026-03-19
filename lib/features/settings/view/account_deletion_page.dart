import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kSurface = Color(0xFF0F2040);
const _kBorder = Color(0xFF1E3050);
const _kNeonGreen = Color(0xFF00F5A0);
const _kTextPrimary = Color(0xFFE8F4F8);
const _kTextSecondary = Color(0xFF6B8AAB);
const _kErrorRed = Color(0xFFFF4D4F);

/// Page that lets the user permanently delete their account and all data.
///
/// Deletes: Firestore user document + sub-collections, Firebase Storage
/// user folder, and the Firebase Auth account.
///
/// Required by Apple App Store Review (since June 2022).
class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  static const routeName = '/account-deletion';

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  bool _confirmed = false;
  bool _isDeleting = false;
  String? _error;

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      // 1. Delete Firestore sub-collections
      final subCollections = [
        'economy',
        'badges',
        'agents',
        'quests',
        'inventory',
        'notifications',
        'predictions',
        'feed_posts',
      ];

      for (final sub in subCollections) {
        try {
          final snapshots = await firestore
              .collection('users')
              .doc(uid)
              .collection(sub)
              .get();
          for (final doc in snapshots.docs) {
            await doc.reference.delete();
          }
        } catch (_) {
          // Sub-collection may not exist — continue
        }
      }

      // 2. Delete user document
      try {
        await firestore.collection('users').doc(uid).delete();
      } catch (_) {}

      // 3. Delete user's Storage folder
      try {
        final storageRef = storage.ref().child('users/$uid');
        final listResult = await storageRef.listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
        for (final prefix in listResult.prefixes) {
          final subItems = await prefix.listAll();
          for (final item in subItems.items) {
            await item.delete();
          }
        }
      } catch (_) {
        // Storage folder may not exist — continue
      }

      // 4. Delete Firebase Auth account
      await user.delete();

      if (!mounted) return;
      // Navigate to sign-in page
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() {
          _isDeleting = false;
          _error =
              'กรุณาออกจากระบบและเข้าสู่ระบบใหม่ก่อนลบบัญชี (ต้องยืนยันตัวตนอีกครั้ง)';
        });
      } else {
        setState(() {
          _isDeleting = false;
          _error = 'เกิดข้อผิดพลาด: ${e.message ?? e.code}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        title: const Text(
          'ลบบัญชี',
          style: TextStyle(
            color: _kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _kBorder, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kErrorRed.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: _kErrorRed,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Center(
                  child: Text(
                    'คุณแน่ใจหรือไม่?',
                    style: TextStyle(
                      color: _kErrorRed,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การลบบัญชีจะดำเนินการดังนี้:',
                        style: TextStyle(
                          color: _kTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      _DeletionItem('ลบข้อมูลโปรไฟล์ทั้งหมด'),
                      _DeletionItem('ลบเหรียญ, XP, และไอเทมทั้งหมด'),
                      _DeletionItem('ลบเอเจนต์และเควสท์ทั้งหมด'),
                      _DeletionItem('ลบโพสต์และการพยากรณ์ทั้งหมด'),
                      _DeletionItem('ลบงานพิกเซลอาร์ตที่บันทึกไว้'),
                      _DeletionItem('ลบบัญชีผู้ใช้อย่างถาวร'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'การดำเนินการนี้ไม่สามารถย้อนกลับได้ ข้อมูลทั้งหมดจะถูกลบอย่างถาวร',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Confirmation checkbox
                GestureDetector(
                  onTap: () => setState(() => _confirmed = !_confirmed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _confirmed,
                          onChanged: (v) =>
                              setState(() => _confirmed = v ?? false),
                          activeColor: _kErrorRed,
                          checkColor: Colors.white,
                          side: const BorderSide(color: _kTextSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'ฉันเข้าใจว่าข้อมูลทั้งหมดจะถูกลบอย่างถาวรและไม่สามารถกู้คืนได้',
                          style: TextStyle(
                            color: _kTextPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kErrorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _kErrorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: _kErrorRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Delete button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirmed && !_isDeleting
                        ? _deleteAccount
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kErrorRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kErrorRed.withValues(alpha: 0.3),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ลบบัญชีของฉัน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kNeonGreen,
                      side: const BorderSide(color: _kNeonGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingAnimationWidget.staggeredDotsWave(
                      color: _kErrorRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'กำลังลบบัญชี...',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeletionItem extends StatelessWidget {
  const _DeletionItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close, color: _kErrorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _kTextSecondary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
