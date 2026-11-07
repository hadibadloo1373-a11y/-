import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MadreseJadooyiApp());

const _pink = Color(0xFFFFD9EC);
const _purple = Color(0xFFE9DDFB);
const _ink = Color(0xFF633F75);

class Lesson {
  final int number;
  final String signs;
  final String section;
  const Lesson(this.number, this.signs, this.section);
}

// Sequence transcribed from the proposed teaching schedules in the uploaded
// 1405 Persian and Negارش textbooks. Lesson-specific word lists are not
// invented here; they will be added after page-by-page review.
const lessons = <Lesson>[
  Lesson(1, 'آ ، ب', 'آموزش نشانه‌ها (۱)'),
  Lesson(2, 'اَ ، د', 'آموزش نشانه‌ها (۱)'),
  Lesson(3, 'م ، س', 'آموزش نشانه‌ها (۱)'),
  Lesson(4, 'او ، ت', 'آموزش نشانه‌ها (۱)'),
  Lesson(5, 'ر ، ن', 'آموزش نشانه‌ها (۱)'),
  Lesson(6, 'ای ، ی ، ز', 'آموزش نشانه‌ها (۱)'),
  Lesson(7, 'اِ ، ه ، ش', 'آموزش نشانه‌ها (۱)'),
  Lesson(8, 'ی ، اُ', 'آموزش نشانه‌ها (۱)'),
  Lesson(9, 'ک ، و', 'آموزش نشانه‌ها (۱)'),
  Lesson(10, 'پ ، گ', 'آموزش نشانه‌ها (۱)'),
  Lesson(11, 'ف ، خ', 'آموزش نشانه‌ها (۱)'),
  Lesson(12, 'ق ، ل', 'آموزش نشانه‌ها (۱)'),
  Lesson(13, 'ج و استثنا', 'آموزش نشانه‌ها (۱)'),
  Lesson(14, 'ه ، چ', 'آموزش نشانه‌ها (۱)'),
  Lesson(15, 'ژ ، خوا', 'آموزش نشانه‌ها (۱)'),
  Lesson(16, 'تشدید', 'آموزش نشانه‌ها (۲)'),
  Lesson(17, 'ص ، ذ', 'آموزش نشانه‌ها (۲)'),
  Lesson(18, 'ع ، ث', 'آموزش نشانه‌ها (۲)'),
  Lesson(19, 'ح', 'آموزش نشانه‌ها (۲)'),
  Lesson(20, 'ض ، ط', 'آموزش نشانه‌ها (۲)'),
  Lesson(21, 'غ و درس آزاد', 'آموزش نشانه‌ها (۲)'),
  Lesson(22, 'ظ', 'آموزش نشانه‌ها (۲)'),
];

class ChildProfile {
  final String id;
  String name;
  String avatar;
  int stars;
  Set<int> completed;
  ChildProfile({required this.id, required this.name, required this.avatar,
    this.stars = 0, Set<int>? completed}) : completed = completed ?? <int>{};
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'avatar': avatar, 'stars': stars,
    'completed': completed.toList(),
  };
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
    id: j['id'], name: j['name'], avatar: j['avatar'] ?? '👧🏻',
    stars: j['stars'] ?? 0,
    completed: Set<int>.from((j['completed'] ?? []).map((e) => e as int)),
  );
}

class MadreseJadooyiApp extends StatefulWidget {
  const MadreseJadooyiApp({super.key});
  @override
  State<MadreseJadooyiApp> createState() => _MadreseJadooyiAppState();
}

class _MadreseJadooyiAppState extends State<MadreseJadooyiApp> {
  List<ChildProfile> profiles = [];
  String? activeId;
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('profiles_v1');
    if (raw != null) {
      profiles = (jsonDecode(raw) as List).map((e) => ChildProfile.fromJson(e)).toList();
    }
    activeId = p.getString('active_profile');
    if (activeId != null && !profiles.any((e) => e.id == activeId)) activeId = null;
    setState(() => loading = false);
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('profiles_v1', jsonEncode(profiles.map((e) => e.toJson()).toList()));
    if (activeId == null) { await p.remove('active_profile'); }
    else { await p.setString('active_profile', activeId!); }
  }
  ChildProfile? get active {
    for (final p in profiles) { if (p.id == activeId) return p; }
    return null;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'مدرسه جادویی من',
    theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto', colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD77EB5)), scaffoldBackgroundColor: const Color(0xFFFFF7FC)),
    home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) :
      active == null ? ProfileScreen(profiles: profiles, onSelect: (id) async { setState(() => activeId = id); await _save(); }, onChange: (p) async { setState(() => profiles = p); await _save(); }) :
      HomeScreen(profile: active!, onBack: () async { setState(() => activeId = null); await _save(); }, onUpdate: (profile) async { setState(() {}); await _save(); }),
  );
}

class ProfileScreen extends StatefulWidget {
  final List<ChildProfile> profiles;
  final ValueChanged<String> onSelect;
  final ValueChanged<List<ChildProfile>> onChange;
  const ProfileScreen({super.key, required this.profiles, required this.onSelect, required this.onChange});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  final avatars = ['👧🏻','👸🏻','🧚🏻‍♀️','🦄','🐰','🐱','🌷','🦋'];
  Future<void> addProfile() async {
    final c = TextEditingController(); String avatar = avatars[0];
    final name = await showDialog<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('ساخت پروفایل کوچولو 🌸', textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, autofocus: true, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'اسم کودک را بنویس')),
        const SizedBox(height: 14), Wrap(spacing: 8, children: avatars.map((a) => ChoiceChip(label: Text(a, style: const TextStyle(fontSize: 24)), selected: avatar == a, onSelected: (_) => setD(() => avatar = a))).toList()),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) Navigator.pop(ctx, '${c.text.trim()}|$avatar'); }, child: const Text('بساز'))],
    )));
    if (name != null) { final parts = name.split('|'); final list = [...widget.profiles, ChildProfile(id: DateTime.now().microsecondsSinceEpoch.toString(), name: parts[0], avatar: parts[1])]; widget.onChange(list); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Stack(children: [
    const FlowerBackdrop(),
    Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 24), const Text('🌈 مدرسه جادویی من', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _ink)),
      const Text('هر کوچولو، یک دنیای یادگیری جداگانه 💗', style: TextStyle(color: _ink)),
      const SizedBox(height: 26),
      Expanded(child: widget.profiles.isEmpty ? const Center(child: Text('هنوز پروفایلی نساختی!\nاولین دانش‌آموز جادویی را اضافه کن 🌷', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: _ink))) : ListView(children: widget.profiles.map((p) => Card(color: Colors.white.withOpacity(.94), child: ListTile(leading: Text(p.avatar, style: const TextStyle(fontSize: 38)), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _ink)), subtitle: Text('⭐ ${p.stars} ستاره  •  ${p.completed.length} درس تکمیل‌شده'), trailing: const Icon(Icons.arrow_forward_ios_rounded, color: _ink), onTap: () => widget.onSelect(p.id), onLongPress: () => _manage(p)))).toList())),
      FilledButton.icon(onPressed: addProfile, icon: const Icon(Icons.add), label: const Text('افزودن دانش‌آموز جدید'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: const Color(0xFFCB82B5))),
      const SizedBox(height: 8), const Text('پروفایل‌ها روی همین دستگاه جداگانه ذخیره می‌شوند.', style: TextStyle(fontSize: 11, color: _ink)),
    ])),
  ])));
  Future<void> _manage(ChildProfile p) async {
    final action = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.edit), title: const Text('تغییر نام'), onTap: () => Navigator.pop(ctx, 'edit')), ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('حذف پروفایل'), onTap: () => Navigator.pop(ctx, 'delete'))])));
    if (action == 'delete') { widget.onChange(widget.profiles.where((e) => e.id != p.id).toList()); }
    if (action == 'edit') { final c = TextEditingController(text: p.name); final n = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('تغییر نام'), content: TextField(controller: c), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')), TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('ذخیره'))])); if (n != null && n.isNotEmpty) { p.name = n; widget.onChange([...widget.profiles]); } }
  }
}

class HomeScreen extends StatelessWidget {
  final ChildProfile profile; final VoidCallback onBack; final VoidCallback onUpdate;
  const HomeScreen({super.key, required this.profile, required this.onBack, required this.onUpdate});
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Stack(children: [const FlowerBackdrop(), CustomScrollView(slivers: [
    SliverPadding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), sliver: SliverList(delegate: SliverChildListDelegate([
      Row(children: [IconButton(onPressed: onBack, icon: const Icon(Icons.switch_account_rounded, color: _ink)), const Spacer(), Text('${profile.avatar} ${profile.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _ink)), const SizedBox(width: 10), _pill('⭐ ${profile.stars}')]),
      const SizedBox(height: 10), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFDCEC), Color(0xFFE9DDFB)]), borderRadius: BorderRadius.circular(28)), child: const Column(children: [Text('🏰 🌈 🧸 🌷', style: TextStyle(fontSize: 34)), Text('به مدرسه جادویی خوش اومدی!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink), textAlign: TextAlign.center), Text('امروز با هم یک چیز تازه یاد می‌گیریم ✨', style: TextStyle(color: _ink))])),
      const SizedBox(height: 18), const Text('بخش‌های مدرسه', textAlign: TextAlign.right, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ink)), const SizedBox(height: 10),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55, children: [
        _menu(context, 'آموزش نشانه‌ها', '🔤', const Color(0xFFFFE0EF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(profile: profile, onUpdate: onUpdate)))),
        _menu(context, 'گوش کن و بخوان', '🎧', const Color(0xFFE7DDFB), () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(profile: profile, onUpdate: onUpdate)))),
        _menu(context, 'بنویس', '✏️', const Color(0xFFDDF1FF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(profile: profile, onUpdate: onUpdate)))),
        _menu(context, 'دیکته', '📝', const Color(0xFFFFF0C9), () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(profile: profile, onUpdate: onUpdate)))),
        _menu(context, 'بازی و سرگرمی', '🧩', const Color(0xFFE0F6E9), () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(profile: profile, onUpdate: onUpdate)))),
        _menu(context, 'ستاره‌های من', '🏆', const Color(0xFFFFE7D8), () => _showAwards(context)),
      ]),
      const SizedBox(height: 18), const Text('🌼 دوست داری از کجا شروع کنیم؟', style: TextStyle(color: _ink, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ]))),
  ]))])));
  static Widget _pill(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)), child: Text(t, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold)));
  static Widget _menu(BuildContext c, String title, String emoji, Color color, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(22), child: Container decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white, width: 2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 31)), const SizedBox(height: 5), Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.bold))])));
  void _showAwards(BuildContext c) => showDialog(context: c, builder: (_) => AlertDialog(title: const Text('گنجینه جایزه‌ها 🌷'), content: Text('آفرین ${profile.name}!\nتا حالا ${profile.stars} ستاره گرفتی.\nهر درس که تمرینش را کامل کنی، یک ستاره می‌گیری ⭐'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('ادامه'))]));
}

class LessonListScreen extends StatelessWidget {
  final ChildProfile profile; final VoidCallback onUpdate;
  const LessonListScreen({super.key, required this.profile, required this.onUpdate});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('باغ نشانه‌ها 🌸'), backgroundColor: Colors.transparent), body: Stack(children: [const FlowerBackdrop(), ListView(padding: const EdgeInsets.all(16), children: [
    const Text('اول نگاره‌ها، بعد درس‌های نشانه‌ها', textAlign: TextAlign.center, style: TextStyle(color: _ink, fontWeight: FontWeight.bold)),
    Card(color: const Color(0xFFFFE8F3), child: ListTile(leading: const Text('🖼️', style: TextStyle(fontSize: 30)), title: const Text('۱۰ نگاره آغازین'), subtitle: const Text('آشنایی دیداری و شنیداری'), trailing: const Icon(Icons.lock_clock), onTap: () => _info(context))),
    const SizedBox(height: 8), ...lessons.map((l) => Card(color: Colors.white.withOpacity(.95), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFF6D8EB), child: Text('${l.number}', style: const TextStyle(color: _ink, fontWeight: FontWeight.bold))), title: Text('درس ${l.number}  •  ${l.signs}', textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, color: _ink)), subtitle: Text(l.section), trailing: profile.completed.contains(l.number) ? const Text('⭐', style: TextStyle(fontSize: 22)) : const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: l, profile: profile, onUpdate: onUpdate))))),
    const Padding(padding: EdgeInsets.all(12), child: Text('توجه: واژه‌ها و جمله‌های تمرینی هر درس پس از تطبیق صفحه‌به‌صفحه با کتاب اضافه می‌شوند؛ در این نسخه محتوای کتاب حدس زده نشده است.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _ink))),
  ])]));
  void _info(BuildContext c) => showDialog(context: c, builder: (_) => AlertDialog(title: const Text('نگاره‌ها'), content: const Text('بخش نگاره‌ها در ساختار کتاب پیش از درس اول قرار دارد. محتوای تعاملی آن در مرحله بعد، پس از بازبینی صفحه‌ها افزوده می‌شود.'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('باشه'))]));
}

class LessonScreen extends StatefulWidget {
  final Lesson lesson; final ChildProfile profile; final VoidCallback onUpdate;
  const LessonScreen({super.key, required this.lesson, required this.profile, required this.onUpdate});
  @override State<LessonScreen> createState() => _LessonScreenState();
}
class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  late TabController tabs; final FlutterTts tts = FlutterTts(); bool gotStar = false;
  @override void initState() { super.initState(); tabs = TabController(length: 3, vsync: this); tts.setLanguage('fa-IR'); tts.setSpeechRate(.38); }
  @override void dispose() { tabs.dispose(); tts.stop(); super.dispose(); }
  Future<void> speak(String text) async { try { await tts.speak(text); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صدای فارسی در این دستگاه در دسترس نیست.'))); } }
  void complete() { if (gotStar) return; gotStar = true; widget.profile.stars++; widget.profile.completed.add(widget.lesson.number); widget.onUpdate(); setState(() {}); showDialog(context: context, builder: (_) => AlertDialog(title: const Text('آفرین ستاره‌ی من! 🌟'), content: const Text('یک ستاره جادویی گرفتی!'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('هورا!'))])); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('درس ${widget.lesson.number} 🌷'), backgroundColor: Colors.transparent), body: Stack(children: [const FlowerBackdrop(), Column(children: [Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [const Text('🧸 🌸 🦋', style: TextStyle(fontSize: 28)), Text(widget.lesson.signs, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 42, color: _ink, fontWeight: FontWeight.w900)), const Text('نشانه‌های این درس', style: TextStyle(color: _ink))])), TabBar(controller: tabs, labelColor: _ink, tabs: const [Tab(text: 'گوش کن'), Tab(text: 'بخوان'), Tab(text: 'بنویس')]), Expanded(child: TabBarView(controller: tabs, children: [
    _listenTab(), _readTab(), _writeTab(),
  ])), Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: complete, icon: const Icon(Icons.star), label: Text(gotStar ? 'این درس ستاره دارد' : 'تمرین کردم؛ یک ستاره بگیر!'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: const Color(0xFFCB82B5))))]))]));
  Widget _listenTab() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('روی نشانه بزن تا صدایش را بشنوی', style: TextStyle(color: _ink, fontSize: 17)), const SizedBox(height: 20), Wrap(spacing: 14, children: widget.lesson.signs.split('،').map((s) => ElevatedButton(onPressed: () => speak(s.trim()), style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: _ink, padding: const EdgeInsets.all(20)), child: Text(s.trim(), style: const TextStyle(fontSize: 30)))).toList()), const SizedBox(height: 18), OutlinedButton.icon(onPressed: () => speak(widget.lesson.signs), icon: const Icon(Icons.volume_up), label: const Text('گوش کن'))])));
  Widget _readTab() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('نشانه‌ها را با صدای بلند بخوان', style: TextStyle(color: _ink, fontSize: 18)), const SizedBox(height: 18), Text(widget.lesson.signs, style: const TextStyle(fontSize: 40, color: _ink, fontWeight: FontWeight.bold)), const SizedBox(height: 18), const Text('تمرین خواندن کلمه و جمله پس از بازبینی متن همین درس اضافه می‌شود.', textAlign: TextAlign.center, style: TextStyle(color: _ink)), const SizedBox(height: 18), FilledButton.icon(onPressed: () => speak(widget.lesson.signs), icon: const Icon(Icons.volume_up), label: const Text('شنیدن نشانه‌ها'))])));
  Widget _writeTab() => const WritingPad();
}

class WritingPad extends StatefulWidget { const WritingPad({super.key}); @override State<WritingPad> createState() => _WritingPadState(); }
class _WritingPadState extends State<WritingPad> {
  final List<Offset?> points = [];
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(18), child: Column(children: [const Text('با انگشتت روی کاغذ تمرین کن ✏️', style: TextStyle(color: _ink, fontSize: 17)), const SizedBox(height: 12), Expanded(child: GestureDetector(onPanUpdate: (d) { setState(() => points.add(d.localPosition)); }, onPanEnd: (_) => points.add(null), child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7C9E0), width: 2)), child: CustomPaint(painter: _LinePainter(points))))), const SizedBox(height: 10), OutlinedButton.icon(onPressed: () => setState(points.clear), icon: const Icon(Icons.refresh), label: const Text('پاک کن و دوباره بنویس'))]));
}
class _LinePainter extends CustomPainter { final List<Offset?> points; _LinePainter(this.points); @override void paint(Canvas canvas, Size size) { final p = Paint()..color = const Color(0xFF9C6CB1)..strokeWidth = 5..strokeCap = StrokeCap.round; for (int i=0;i<points.length-1;i++) { if (points[i] != null && points[i+1] != null) canvas.drawLine(points[i]!, points[i+1]!, p); } } @override bool shouldRepaint(covariant _LinePainter old) => old.points != points; }

class FlowerBackdrop extends StatelessWidget { const FlowerBackdrop({super.key}); @override Widget build(BuildContext context) => IgnorePointer(child: Stack(children: [Positioned(top: 12, left: 12, child: _bubble('🌷')), Positioned(top: 100, right: 10, child: _bubble('🌼')), Positioned(bottom: 45, left: 8, child: _bubble('🦋')), Positioned(bottom: 120, right: 12, child: _bubble('🌸')), Positioned(top: 230, left: 5, child: _bubble('🎀'))])); Widget _bubble(String s) => Opacity(opacity: .30, child: Text(s, style: const TextStyle(fontSize: 28))); }
