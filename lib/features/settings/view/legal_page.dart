import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kBorder = Color(0xFF1E3050);
const _kNeonGreen = Color(0xFF00F5A0);
const _kTextPrimary = Color(0xFFE8F4F8);
const _kTextSecondary = Color(0xFF6B8AAB);

/// Displays Privacy Policy or Terms of Service in-app.
///
/// Required by Apple App Store Review for apps that collect user data.
class LegalPage extends StatelessWidget {
  const LegalPage({
    super.key,
    required this.title,
    required this.sections,
  });

  static const privacyPolicyRouteName = '/privacy-policy';
  static const termsOfServiceRouteName = '/terms-of-service';

  final String title;
  final List<LegalSection> sections;

  /// Factory for the Privacy Policy page.
  factory LegalPage.privacyPolicy() {
    return LegalPage(
      title: 'นโยบายความเป็นส่วนตัว',
      sections: _privacyPolicySections,
    );
  }

  /// Factory for the Terms of Service page.
  factory LegalPage.termsOfService() {
    return LegalPage(
      title: 'ข้อกำหนดการใช้งาน',
      sections: _termsOfServiceSections,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length + 1, // +1 for footer
        itemBuilder: (context, index) {
          if (index == sections.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              child: Text(
                'อัปเดตล่าสุด: มีนาคม 2026\n\nหากมีข้อสงสัย ติดต่อ: support@aslanpixel.com',
                style: TextStyle(
                  color: _kTextSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final section = sections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.heading,
                  style: const TextStyle(
                    color: _kNeonGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LegalSection {
  const LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}

// ── Privacy Policy Content ──────────────────────────────────────────────────

const _privacyPolicySections = <LegalSection>[
  LegalSection(
    heading: '1. ข้อมูลที่เราเก็บรวบรวม',
    body:
        'เราเก็บรวบรวมข้อมูลดังต่อไปนี้:\n'
        '- อีเมลและชื่อแสดง: ใช้สำหรับการลงทะเบียนและระบุตัวตนในแอป\n'
        '- ข้อมูลโปรไฟล์: อวาตาร์, ระดับ, เหรียญ, เหรียญตรา\n'
        '- ข้อมูลการใช้งาน: พฤติกรรมการใช้แอป, เวลาที่ใช้, ฟีเจอร์ที่เข้าถึง\n'
        '- ข้อมูลอุปกรณ์: รุ่นอุปกรณ์, ระบบปฏิบัติการ, สำหรับการแก้ไขปัญหา',
  ),
  LegalSection(
    heading: '2. วิธีที่เราใช้ข้อมูล',
    body:
        '- จัดการบัญชีผู้ใช้และการเข้าสู่ระบบ\n'
        '- แสดงเนื้อหาเกมและฟีเจอร์สังคม\n'
        '- ปรับปรุงประสบการณ์ผู้ใช้\n'
        '- ส่งการแจ้งเตือนที่เกี่ยวข้อง (ถ้าผู้ใช้อนุญาต)\n'
        '- วิเคราะห์ข้อผิดพลาดและปรับปรุงแอป',
  ),
  LegalSection(
    heading: '3. การแบ่งปันข้อมูล',
    body:
        'เราไม่ขายหรือแบ่งปันข้อมูลส่วนบุคคลของคุณให้กับบุคคลที่สาม ยกเว้น:\n'
        '- Firebase (Google): สำหรับการยืนยันตัวตน, การจัดเก็บข้อมูล, การวิเคราะห์\n'
        '- เมื่อกฎหมายกำหนด',
  ),
  LegalSection(
    heading: '4. ความปลอดภัยของข้อมูล',
    body:
        'เราใช้มาตรการรักษาความปลอดภัยที่เหมาะสม รวมถึงการเข้ารหัส SSL/TLS '
        'สำหรับการรับส่งข้อมูลทั้งหมด และการรักษาความปลอดภัยของ Firebase',
  ),
  LegalSection(
    heading: '5. สิทธิ์ของผู้ใช้',
    body:
        'คุณมีสิทธิ์:\n'
        '- เข้าถึงข้อมูลส่วนบุคคลของคุณผ่านหน้าโปรไฟล์\n'
        '- แก้ไขข้อมูลโปรไฟล์ได้ตลอดเวลา\n'
        '- ลบบัญชีและข้อมูลทั้งหมดอย่างถาวรผ่านเมนูตั้งค่า\n'
        '- ปิดการแจ้งเตือนได้ตลอดเวลา',
  ),
  LegalSection(
    heading: '6. เหรียญเสมือน (Virtual Currency)',
    body:
        'เหรียญและ XP ในแอปเป็นสกุลเงินเสมือนที่ใช้ในเกมเท่านั้น '
        'ไม่มีมูลค่าเป็นเงินจริง ไม่สามารถแลกเป็นเงินสด '
        'และไม่ใช่สินทรัพย์ดิจิทัลหรือสกุลเงินดิจิทัล',
  ),
  LegalSection(
    heading: '7. ข้อมูลทางการเงิน',
    body:
        'ข้อมูลราคาคริปโตและตลาดหุ้นที่แสดงในแอปมีไว้เพื่อการศึกษาเท่านั้น '
        'ไม่ถือเป็นคำแนะนำในการลงทุน การตัดสินใจลงทุนเป็นความรับผิดชอบ'
        'ของผู้ใช้เอง',
  ),
  LegalSection(
    heading: '8. การเปลี่ยนแปลงนโยบาย',
    body:
        'เราอาจปรับปรุงนโยบายนี้เป็นครั้งคราว '
        'การเปลี่ยนแปลงที่สำคัญจะถูกแจ้งผ่านแอป',
  ),
];

// ── Terms of Service Content ────────────────────────────────────────────────

const _termsOfServiceSections = <LegalSection>[
  LegalSection(
    heading: '1. การยอมรับข้อกำหนด',
    body:
        'การใช้งาน Aslan Pixel หมายความว่าคุณยอมรับข้อกำหนดการใช้งานเหล่านี้ '
        'หากคุณไม่ยอมรับ กรุณาหยุดใช้งานแอป',
  ),
  LegalSection(
    heading: '2. คำอธิบายบริการ',
    body:
        'Aslan Pixel เป็นแอปพลิเคชันเกมการเงินสังคม (Social Financial Game) '
        'ที่รวมระบบ Idle Game, โลกพิกเซล, และฟีเจอร์สังคม '
        'แอปไม่ใช่แพลตฟอร์มซื้อขายหลักทรัพย์หรือสกุลเงินดิจิทัล',
  ),
  LegalSection(
    heading: '3. ข้อจำกัดความรับผิดชอบด้านการเงิน',
    body:
        'ข้อมูลตลาด ราคาคริปโต การพยากรณ์ และข้อมูลเชิงลึก (AI Insights) '
        'ที่แสดงในแอปมีไว้เพื่อวัตถุประสงค์ด้านการศึกษาและความบันเทิงเท่านั้น\n\n'
        'ข้อมูลเหล่านี้ไม่ถือเป็นคำแนะนำในการลงทุน ไม่ว่าในรูปแบบใด '
        'ผู้ใช้ไม่ควรตัดสินใจลงทุนโดยอาศัยข้อมูลจากแอปนี้เพียงอย่างเดียว',
  ),
  LegalSection(
    heading: '4. สกุลเงินเสมือน',
    body:
        'เหรียญ (Coins) และ XP ในแอปเป็นสกุลเงินเสมือนที่ใช้ในเกมเท่านั้น:\n'
        '- ไม่มีมูลค่าเป็นเงินจริง\n'
        '- ไม่สามารถซื้อด้วยเงินจริง (ยกเว้นจะมีระบบ In-App Purchase ในอนาคต)\n'
        '- ไม่สามารถแลกเป็นเงินสดหรือสินค้าจริง\n'
        '- ไม่ใช่สินทรัพย์ดิจิทัลหรือสกุลเงินดิจิทัล',
  ),
  LegalSection(
    heading: '5. บัญชีผู้ใช้',
    body:
        'คุณรับผิดชอบในการรักษาความปลอดภัยของบัญชีของคุณ '
        'ห้ามแบ่งปันรหัสผ่านกับผู้อื่น\n\n'
        'เราขอสงวนสิทธิ์ในการระงับหรือลบบัญชีที่ละเมิดข้อกำหนดเหล่านี้',
  ),
  LegalSection(
    heading: '6. พฤติกรรมผู้ใช้',
    body:
        'ผู้ใช้ต้องไม่:\n'
        '- โพสต์เนื้อหาที่ไม่เหมาะสม ผิดกฎหมาย หรือหมิ่นประมาท\n'
        '- พยายามแฮ็กหรือรบกวนการทำงานของแอป\n'
        '- ใช้บอทหรือเครื่องมืออัตโนมัติเพื่อเล่นเกม\n'
        '- แอบอ้างเป็นผู้ใช้คนอื่น',
  ),
  LegalSection(
    heading: '7. ทรัพย์สินทางปัญญา',
    body:
        'เนื้อหา กราฟิก พิกเซลอาร์ต และซอฟต์แวร์ทั้งหมดใน Aslan Pixel '
        'เป็นทรัพย์สินของ Aslan Pixel หรือผู้อนุญาตให้ใช้สิทธิ์ '
        'ห้ามคัดลอก ดัดแปลง หรือแจกจ่ายโดยไม่ได้รับอนุญาต',
  ),
  LegalSection(
    heading: '8. การยกเลิกบริการ',
    body:
        'คุณสามารถลบบัญชีได้ตลอดเวลาผ่านเมนูตั้งค่า > ลบบัญชี '
        'การลบบัญชีจะลบข้อมูลทั้งหมดอย่างถาวร',
  ),
  LegalSection(
    heading: '9. การเปลี่ยนแปลงข้อกำหนด',
    body:
        'เราขอสงวนสิทธิ์ในการเปลี่ยนแปลงข้อกำหนดเหล่านี้ได้ตลอดเวลา '
        'การเปลี่ยนแปลงที่สำคัญจะถูกแจ้งผ่านแอป',
  ),
];
