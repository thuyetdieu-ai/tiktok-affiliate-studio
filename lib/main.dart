import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StudioStore();
  await store.load();
  runApp(StudioApp(store: store));
}

String uid() => DateTime.now().microsecondsSinceEpoch.toString();
String money(num value) => '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';

class Scene {
  String id, visual, overlay;
  int seconds;
  Scene({required this.id, required this.visual, required this.overlay, this.seconds = 10});
  factory Scene.fromJson(Map<String, dynamic> j) => Scene(id: '${j['id']}', visual: '${j['visual'] ?? ''}', overlay: '${j['overlay'] ?? ''}', seconds: (j['seconds'] as num?)?.toInt() ?? 10);
  Map<String, dynamic> toJson() => {'id': id, 'visual': visual, 'overlay': overlay, 'seconds': seconds};
}

class Product {
  String id, name, category, hook, affiliateUrl, productImage, characterImage, backgroundImage, notes;
  double price, commissionRate;
  List<Scene> scenes;
  Product({required this.id, required this.name, required this.category, required this.hook, required this.scenes, this.affiliateUrl = '', this.productImage = '', this.characterImage = '', this.backgroundImage = '', this.notes = '', this.price = 0, this.commissionRate = 0});
  factory Product.fromJson(Map<String, dynamic> j) => Product(id: '${j['id']}', name: '${j['name'] ?? ''}', category: '${j['category'] ?? 'Khác'}', hook: '${j['hook'] ?? ''}', affiliateUrl: '${j['affiliateUrl'] ?? ''}', productImage: '${j['productImage'] ?? ''}', characterImage: '${j['characterImage'] ?? ''}', backgroundImage: '${j['backgroundImage'] ?? ''}', notes: '${j['notes'] ?? ''}', price: (j['price'] as num?)?.toDouble() ?? 0, commissionRate: (j['commissionRate'] as num?)?.toDouble() ?? 0, scenes: ((j['scenes'] as List?) ?? []).map((e) => Scene.fromJson(Map<String, dynamic>.from(e as Map))).toList());
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'hook': hook, 'affiliateUrl': affiliateUrl, 'productImage': productImage, 'characterImage': characterImage, 'backgroundImage': backgroundImage, 'notes': notes, 'price': price, 'commissionRate': commissionRate, 'scenes': scenes.map((s) => s.toJson()).toList()};
}

class VideoRecord {
  String id, productId, title, status, date;
  int views, clicks, orders;
  double revenue, commission;
  VideoRecord({required this.id, required this.productId, required this.title, required this.status, required this.date, this.views = 0, this.clicks = 0, this.orders = 0, this.revenue = 0, this.commission = 0});
  factory VideoRecord.fromJson(Map<String, dynamic> j) => VideoRecord(id: '${j['id']}', productId: '${j['productId']}', title: '${j['title'] ?? ''}', status: '${j['status'] ?? 'Ý tưởng'}', date: '${j['date'] ?? ''}', views: (j['views'] as num?)?.toInt() ?? 0, clicks: (j['clicks'] as num?)?.toInt() ?? 0, orders: (j['orders'] as num?)?.toInt() ?? 0, revenue: (j['revenue'] as num?)?.toDouble() ?? 0, commission: (j['commission'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> toJson() => {'id': id, 'productId': productId, 'title': title, 'status': status, 'date': date, 'views': views, 'clicks': clicks, 'orders': orders, 'revenue': revenue, 'commission': commission};
}

List<Product> seedProducts() {
  final rows = <List<String>>[
    ['Thùng 6 bịch khăn giấy rút đáy', 'Gia dụng', 'Nhà bạn có đang dùng khăn giấy kiểu này chưa?', 'Đang nấu ăn, người dùng cần khăn giấy nhưng giấy đặt xa.', 'Khăn giấy để xa, dùng thật bất tiện!', 'Đặt bịch giấy ở vị trí thuận tiện, quay cận thao tác rút giấy đúng mẫu.', 'Thiết kế rút đáy tiện cho sinh hoạt.', 'Sắp xếp sáu bịch giấy trên bàn, quay rõ bao bì.', 'Xem số lượng và giá combo ở giỏ hàng.'],
    ['Combo 2 nước giặt OMO Matic Pure', 'Gia dụng', 'Một combo nước giặt cho những ngày bận rộn!', 'Người dùng chuẩn bị giặt đồ, giỏ quần áo cạnh máy giặt.', 'Đến giờ giặt đồ rồi!', 'Quay cận hai sản phẩm, đọc nhãn và đong đúng lượng theo hướng dẫn.', 'Dùng đúng liều lượng trên bao bì.', 'Đặt combo trên kệ giặt, quần áo được phơi gọn gàng.', 'Xem thông tin combo và ưu đãi.'],
    ['Thùng 5 bịch khăn giấy Tiểu Hạ TOP GIA', 'Gia dụng', 'Mua giấy theo thùng có tiện hơn không?', 'Bàn ăn hết khăn giấy, người dùng tìm bịch thay thế.', 'Hết giấy đúng lúc cần!', 'Mở thùng và đặt năm bịch cạnh nhau, quay rõ số lượng.', 'Một thùng gồm 5 bịch giấy.', 'Sắp xếp giấy ở phòng khách, bàn ăn và kệ dự trữ.', 'Kiểm tra giá mỗi bịch tại giỏ hàng.'],
    ['Quần jeans nam ống suông xám bạc', 'Thời trang', 'Một chiếc quần, ba cách phối đồ!', 'Người mẫu nam mặc jeans xám bạc với áo thun trơn.', 'Phối đồ đi chơi đơn giản.', 'Giữ nguyên quần và người mẫu, thay áo sơ mi; quay cận đường may.', 'Đổi áo, đổi phong cách.', 'Người mẫu thêm áo khoác, quay góc trước và sau.', 'Xem bảng size trước khi đặt.'],
    ['Quần jeans nữ denim lụa', 'Thời trang', 'Một chiếc quần jeans phối được bao nhiêu kiểu?', 'Người mẫu mặc jeans cùng áo thun cơ bản trong studio sáng.', 'Phối đồ thường ngày.', 'Chuyển sang áo sơ mi, quay chất liệu và phom quần theo ảnh thật.', 'Thử phối cùng áo sơ mi.', 'Kết hợp áo khoác nhẹ, hiển thị ba bộ trang phục.', 'Chọn màu và size phù hợp.'],
    ['Set bộ tole đùi viền bèo baby doll', 'Thời trang', 'Gợi ý một set đồ mặc ở nhà thật xinh!', 'Người mẫu giới thiệu set đồ trong phòng khách sáng.', 'Set đồ mặc nhà dễ phối.', 'Quay cận viền bèo, cổ áo và họa tiết theo ảnh tham chiếu.', 'Cận cảnh thiết kế và chi tiết.', 'Người mẫu di chuyển tự nhiên, giới thiệu màu có sẵn.', 'Xem bảng size và màu tại giỏ hàng.'],
    ['Bộ kem chống nắng Lubylab', 'Mỹ phẩm', 'Trước khi ra ngoài, bạn chuẩn bị gì?', 'Bàn trang điểm cạnh cửa sổ, người dùng chuẩn bị ra ngoài.', 'Chuẩn bị cho một ngày mới.', 'Quay cận bộ sản phẩm và hướng dẫn sử dụng trên bao bì.', 'Đọc hướng dẫn sử dụng trên nhãn.', 'Đặt sản phẩm vào túi, hiển thị bộ sản phẩm trên nền sạch.', 'Xem thông tin bộ sản phẩm.'],
    ['Combo 2 kem dưỡng OLAY Total Effects', 'Mỹ phẩm', 'Một bước chăm sóc da trong thói quen hằng ngày!', 'Người dùng sắp xếp bàn chăm sóc da buổi sáng.', 'Bắt đầu thói quen chăm sóc da.', 'Quay cận hai hộp, dung tích và kết cấu nếu có ảnh thật.', 'Tìm hiểu kết cấu và cách dùng.', 'Đặt combo trên bàn trang điểm, quay bao bì rõ nét.', 'Xem combo và hướng dẫn sử dụng.'],
    ['Combo 5 sữa tắm gội hương nước hoa', 'Mỹ phẩm', 'Một combo có đến năm sản phẩm!', 'Kệ phòng tắm gọn gàng, camera tiến vào combo.', 'Khám phá combo chăm sóc cá nhân.', 'Quay lần lượt năm chai, nhãn và dung tích.', 'Xem từng sản phẩm trong combo.', 'Sắp xếp năm chai trên kệ sạch, quay rõ bao bì.', 'Kiểm tra dung tích và ưu đãi.'],
  ];
  return List.generate(rows.length, (i) { final r = rows[i]; return Product(id: 'seed_${i + 1}', name: r[0], category: r[1], hook: r[2], scenes: List.generate(3, (j) => Scene(id: 's_$j', visual: r[3 + j * 2], overlay: r[4 + j * 2]))); });
}

class StudioStore extends ChangeNotifier {
  List<Product> products = [];
  List<VideoRecord> videos = [];
  late SharedPreferences prefs;
  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    try {
      final p = prefs.getString('studio_products_v1');
      products = p == null ? seedProducts() : (jsonDecode(p) as List).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final v = prefs.getString('studio_videos_v1');
      videos = v == null ? [] : (jsonDecode(v) as List).map((e) => VideoRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) { products = seedProducts(); videos = []; }
    notifyListeners();
  }
  Future<void> save() async {
    await prefs.setString('studio_products_v1', jsonEncode(products.map((p) => p.toJson()).toList()));
    await prefs.setString('studio_videos_v1', jsonEncode(videos.map((v) => v.toJson()).toList()));
    notifyListeners();
  }
  Product? product(String id) { for (final p in products) { if (p.id == id) return p; } return null; }
  Future<String?> importImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return null;
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/references');
    await dir.create(recursive: true);
    final ext = picked.path.split('.').last.toLowerCase();
    final suffix = ['jpg','jpeg','png','webp'].contains(ext) ? ext : 'jpg';
    return (await File(picked.path).copy('${dir.path}/${uid()}.$suffix')).path;
  }
  String prompt(Product p) {
    final buffer = StringBuffer('VIDEO AFFILIATE: ${p.name}\nNgành: ${p.category}\nĐịnh dạng: 9:16, 1080p, 30FPS. Video UGC chân thực, không thoại, không âm thanh meme.\nHOOK: ${p.hook}\n');
    buffer.writeln('Ảnh sản phẩm: ${p.productImage.isEmpty ? 'Chưa có' : p.productImage}');
    buffer.writeln('Ảnh KOC: ${p.characterImage.isEmpty ? 'Chưa có' : p.characterImage}');
    buffer.writeln('Ảnh bối cảnh: ${p.backgroundImage.isEmpty ? 'Chưa có' : p.backgroundImage}');
    for (var i = 0; i < p.scenes.length; i++) { final s = p.scenes[i]; buffer.writeln('\nCẢNH ${i + 1} (${s.seconds} giây):\nHình ảnh: ${s.visual}\nChữ trên video: ${s.overlay}'); }
    buffer.writeln('\nGiữ nguyên nhân vật, trang phục chính, bao bì, màu sắc và bối cảnh giữa các cảnh. Chỉ dùng đặc điểm, công dụng được xác minh. Không mô phỏng kết quả thử nghiệm như thật. Không tự thêm giá hay ưu đãi.');
    return buffer.toString();
  }
}

class StudioApp extends StatelessWidget {
  final StudioStore store;
  const StudioApp({super.key, required this.store});
  @override Widget build(BuildContext context) => MaterialApp(title: 'TikTok Affiliate Studio', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF5A55E8), scaffoldBackgroundColor: const Color(0xFFF7F7FB), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F7FB))), home: Home(store: store));
}

class Home extends StatefulWidget {
  final StudioStore store;
  const Home({super.key, required this.store});
  @override State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final pages = [Dashboard(store: widget.store), ProductsPage(store: widget.store), VideosPage(store: widget.store), StatsPage(store: widget.store)];
    return AnimatedBuilder(animation: widget.store, builder: (context, _) => Scaffold(appBar: AppBar(title: Text(['Tổng quan', 'Sản phẩm & kịch bản', 'Lịch sử video', 'Thống kê'][tab]), actions: [IconButton(tooltip: 'Giới thiệu', icon: const Icon(Icons.info_outline), onPressed: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('TikTok Affiliate Studio'), content: Text('Dữ liệu được lưu trên thiết bị. Không đồng bộ TikTok Shop. Giá và hoa hồng do bạn nhập. Ảnh tham chiếu được lưu trong bộ nhớ ứng dụng.'))))]), body: pages[tab], bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Sản phẩm'), NavigationDestination(icon: Icon(Icons.movie_outlined), label: 'Video'), NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Thống kê')]))) ;
  }
}

Widget metric(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Colors.deepPurple), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(color: Colors.black54))])));
class Dashboard extends StatelessWidget {
  final StudioStore store;
  const Dashboard({super.key, required this.store});
  @override Widget build(BuildContext context) {
    final revenue = store.videos.fold<double>(0, (a, b) => a + b.revenue);
    final commission = store.videos.fold<double>(0, (a, b) => a + b.commission);
    return ListView(padding: const EdgeInsets.all(16), children: [const Text('Xin chào! 👋', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), const Text('Quản lý chiến dịch TikTok Affiliate của bạn.'), const SizedBox(height: 16), GridView.count(crossAxisCount: 2, childAspectRatio: 1.35, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [metric('Sản phẩm', '${store.products.length}', Icons.inventory), metric('Video', '${store.videos.length}', Icons.video_library), metric('Doanh thu', money(revenue), Icons.payments_outlined), metric('Hoa hồng', money(commission), Icons.savings_outlined)]), const SizedBox(height: 16), const Text('Quy trình đề xuất', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const ListTile(leading: Icon(Icons.looks_one), title: Text('Chọn sản phẩm và thêm ảnh tham chiếu')), const ListTile(leading: Icon(Icons.looks_two), title: Text('Chỉnh sửa hook và từng cảnh')), const ListTile(leading: Icon(Icons.looks_3), title: Text('Sao chép hoặc chia sẻ prompt AI')), const ListTile(leading: Icon(Icons.looks_4), title: Text('Tạo bản ghi video, nhập kết quả bán hàng'))]);
  }
}

class ProductsPage extends StatefulWidget {
  final StudioStore store;
  const ProductsPage({super.key, required this.store});
  @override State<ProductsPage> createState() => _ProductsPageState();
}
class _ProductsPageState extends State<ProductsPage> {
  String category = 'Tất cả', query = '';
  @override Widget build(BuildContext context) {
    final items = widget.store.products.where((p) => (category == 'Tất cả' || p.category == category) && p.name.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(body: Column(children: [Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm sản phẩm...', border: OutlineInputBorder()), onChanged: (v) => setState(() => query = v))), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Tất cả', 'Gia dụng', 'Thời trang', 'Mỹ phẩm', 'Khác'].map((c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(c), selected: category == c, onSelected: (_) => setState(() => category = c)))).toList())), Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (context, i) { final p = items[i]; return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(leading: ReferenceThumb(path: p.productImage), title: Text(p.name), subtitle: Text('${p.category} · ${p.scenes.length} cảnh · ${p.price > 0 ? money(p.price) : 'Chưa nhập giá'}'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditor(store: widget.store, product: p)))); })))]), floatingActionButton: FloatingActionButton.extended(onPressed: () { final p = Product(id: uid(), name: 'Sản phẩm mới', category: 'Khác', hook: '', scenes: [for (var i = 0; i < 3; i++) Scene(id: uid(), visual: '', overlay: '')]); widget.store.products.add(p); widget.store.save(); Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditor(store: widget.store, product: p))); }, icon: const Icon(Icons.add), label: const Text('Thêm sản phẩm')));
  }
}
class ReferenceThumb extends StatelessWidget {
  final String path;
  const ReferenceThumb({super.key, required this.path});
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 52, height: 52, child: path.isNotEmpty && File(path).existsSync() ? Image.file(File(path), fit: BoxFit.cover) : const ColoredBox(color: Color(0xFFE9E6FA), child: Icon(Icons.image_outlined))));
}
Widget field(String label, TextEditingController controller, {int lines = 1, TextInputType? type}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, maxLines: lines, keyboardType: type, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), alignLabelWithHint: lines > 1)));

class ProductEditor extends StatefulWidget {
  final StudioStore store;
  final Product product;
  const ProductEditor({super.key, required this.store, required this.product});
  @override State<ProductEditor> createState() => _ProductEditorState();
}
class _ProductEditorState extends State<ProductEditor> {
  late final TextEditingController name, hook, url, notes, price, rate;
  late String category;
  @override void initState() { super.initState(); final p = widget.product; name = TextEditingController(text: p.name); hook = TextEditingController(text: p.hook); url = TextEditingController(text: p.affiliateUrl); notes = TextEditingController(text: p.notes); price = TextEditingController(text: p.price == 0 ? '' : '${p.price}'); rate = TextEditingController(text: p.commissionRate == 0 ? '' : '${p.commissionRate}'); category = ['Gia dụng','Thời trang','Mỹ phẩm','Khác'].contains(p.category) ? p.category : 'Khác'; }
  @override void dispose() { for (final c in [name, hook, url, notes, price, rate]) { c.dispose(); } super.dispose(); }
  Future<void> save() async { final p = widget.product; p.name = name.text.trim(); p.hook = hook.text.trim(); p.affiliateUrl = url.text.trim(); p.notes = notes.text.trim(); p.category = category; p.price = double.tryParse(price.text.replaceAll(',', '.')) ?? 0; p.commissionRate = double.tryParse(rate.text.replaceAll(',', '.')) ?? 0; await widget.store.save(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu sản phẩm'))); }
  Future<void> pick(String kind) async { try { final path = await widget.store.importImage(); if (path == null) return; setState(() { if (kind == 'product') widget.product.productImage = path; if (kind == 'character') widget.product.characterImage = path; if (kind == 'background') widget.product.backgroundImage = path; }); await widget.store.save(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e'))); } }
  Widget photo(String title, String kind, String path) => Card(child: ListTile(leading: ReferenceThumb(path: path), title: Text(title), subtitle: Text(path.isEmpty ? 'Chưa có ảnh' : 'Đã lưu ảnh cục bộ'), trailing: const Icon(Icons.add_photo_alternate_outlined), onTap: () => pick(kind)));
  @override Widget build(BuildContext context) { final p = widget.product; return Scaffold(appBar: AppBar(title: const Text('Chỉnh sửa sản phẩm'), actions: [IconButton(onPressed: save, icon: const Icon(Icons.save_outlined), tooltip: 'Lưu')]), body: ListView(padding: const EdgeInsets.all(16), children: [field('Tên sản phẩm', name), DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Ngành hàng', border: OutlineInputBorder()), items: ['Gia dụng','Thời trang','Mỹ phẩm','Khác'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? category)), const SizedBox(height: 12), field('Hook mở đầu', hook, lines: 2), field('Link Affiliate', url), Row(children: [Expanded(child: field('Giá (VNĐ)', price, type: TextInputType.number)), const SizedBox(width: 8), Expanded(child: field('Hoa hồng (%)', rate, type: TextInputType.number))]), field('Ghi chú sản phẩm', notes, lines: 2), const Text('Ảnh tham chiếu', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), photo('Ảnh sản phẩm', 'product', p.productImage), photo('Ảnh KOC / người mẫu', 'character', p.characterImage), photo('Ảnh bối cảnh', 'background', p.backgroundImage), const SizedBox(height: 12), const Text('Kịch bản theo cảnh', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), ...p.scenes.asMap().entries.map((e) => Card(child: ListTile(title: Text('Cảnh ${e.key + 1} · ${e.value.seconds} giây'), subtitle: Text(e.value.visual, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.edit_outlined), onTap: () async { await save(); if (!context.mounted) return; await Navigator.push(context, MaterialPageRoute(builder: (_) => SceneEditor(store: widget.store, scene: e.value, index: e.key))); setState(() {}); }))), OutlinedButton.icon(onPressed: () async { await save(); p.scenes.add(Scene(id: uid(), visual: '', overlay: '')); await widget.store.save(); setState(() {}); }, icon: const Icon(Icons.add), label: const Text('Thêm cảnh')), const SizedBox(height: 8), FilledButton.icon(onPressed: () async { await save(); if (!context.mounted) return; Navigator.push(context, MaterialPageRoute(builder: (_) => PromptPage(store: widget.store, product: p))); }, icon: const Icon(Icons.auto_awesome), label: const Text('Xem và xuất prompt AI')), OutlinedButton.icon(onPressed: () async { await save(); widget.store.videos.add(VideoRecord(id: uid(), productId: p.id, title: 'Video ${p.name}', status: 'Ý tưởng', date: DateTime.now().toIso8601String().substring(0, 10))); await widget.store.save(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào lịch sử video'))); }, icon: const Icon(Icons.video_call_outlined), label: const Text('Tạo bản ghi video')), TextButton.icon(onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Xóa sản phẩm?'), content: const Text('Kịch bản và thông tin sản phẩm sẽ bị xóa. Các bản ghi video cũ vẫn được giữ.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa'))])); if (ok == true) { widget.store.products.removeWhere((x) => x.id == p.id); await widget.store.save(); if (context.mounted) Navigator.pop(context); } }, icon: const Icon(Icons.delete_outline), label: const Text('Xóa sản phẩm'))])); }
}

class SceneEditor extends StatefulWidget {
  final StudioStore store;
  final Scene scene;
  final int index;
  const SceneEditor({super.key, required this.store, required this.scene, required this.index});
  @override State<SceneEditor> createState() => _SceneEditorState();
}
class _SceneEditorState extends State<SceneEditor> {
  late final TextEditingController visual, overlay, seconds;
  @override void initState() { super.initState(); visual = TextEditingController(text: widget.scene.visual); overlay = TextEditingController(text: widget.scene.overlay); seconds = TextEditingController(text: '${widget.scene.seconds}'); }
  @override void dispose() { visual.dispose(); overlay.dispose(); seconds.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Cảnh ${widget.index + 1}')), body: ListView(padding: const EdgeInsets.all(16), children: [field('Thời lượng (giây)', seconds, type: TextInputType.number), field('Mô tả hành động, camera, bối cảnh', visual, lines: 7), field('Chữ hiển thị trên video', overlay, lines: 3), FilledButton.icon(onPressed: () async { widget.scene.visual = visual.text; widget.scene.overlay = overlay.text; widget.scene.seconds = (int.tryParse(seconds.text) ?? 10).clamp(1, 300).toInt(); await widget.store.save(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.save), label: const Text('Lưu cảnh'))]));
}

class PromptPage extends StatelessWidget {
  final StudioStore store;
  final Product product;
  const PromptPage({super.key, required this.store, required this.product});
  @override Widget build(BuildContext context) { final prompt = store.prompt(product); return Scaffold(appBar: AppBar(title: const Text('Prompt video AI')), body: ListView(padding: const EdgeInsets.all(16), children: [Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), SelectableText(prompt), const SizedBox(height: 18), FilledButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: prompt)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép prompt'))); }, icon: const Icon(Icons.copy), label: const Text('Sao chép toàn bộ prompt')), OutlinedButton.icon(onPressed: () => Share.share(prompt, subject: 'Prompt ${product.name}'), icon: const Icon(Icons.share), label: const Text('Chia sẻ / xuất prompt dạng văn bản'))])); }
}

class VideosPage extends StatelessWidget {
  final StudioStore store;
  const VideosPage({super.key, required this.store});
  @override Widget build(BuildContext context) => store.videos.isEmpty ? const Center(child: Text('Chưa có video. Vào sản phẩm để tạo bản ghi.')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: store.videos.length, itemBuilder: (context, i) { final v = store.videos[i]; return Card(child: ListTile(title: Text(v.title), subtitle: Text('${v.status} · ${v.date}\n${v.views} lượt xem · ${v.orders} đơn · ${money(v.commission)} hoa hồng'), isThreeLine: true, trailing: const Icon(Icons.edit_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoEditor(store: store, record: v))))); });
}
class VideoEditor extends StatefulWidget {
  final StudioStore store;
  final VideoRecord record;
  const VideoEditor({super.key, required this.store, required this.record});
  @override State<VideoEditor> createState() => _VideoEditorState();
}
class _VideoEditorState extends State<VideoEditor> {
  late final TextEditingController title, views, clicks, orders, revenue, commission;
  late String status;
  @override void initState() { super.initState(); final v = widget.record; title = TextEditingController(text: v.title); views = TextEditingController(text: '${v.views}'); clicks = TextEditingController(text: '${v.clicks}'); orders = TextEditingController(text: '${v.orders}'); revenue = TextEditingController(text: '${v.revenue}'); commission = TextEditingController(text: '${v.commission}'); status = ['Ý tưởng','Đang viết','Đã render','Đã đăng'].contains(v.status) ? v.status : 'Ý tưởng'; }
  @override void dispose() { for (final c in [title, views, clicks, orders, revenue, commission]) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Chi tiết video')), body: ListView(padding: const EdgeInsets.all(16), children: [field('Tiêu đề', title), DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()), items: ['Ý tưởng','Đang viết','Đã render','Đã đăng'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => status = v ?? status)), const SizedBox(height: 12), field('Lượt xem', views, type: TextInputType.number), field('Lượt nhấp', clicks, type: TextInputType.number), field('Đơn hàng hợp lệ', orders, type: TextInputType.number), field('Doanh thu (VNĐ)', revenue, type: TextInputType.number), field('Hoa hồng thực nhận (VNĐ)', commission, type: TextInputType.number), FilledButton.icon(onPressed: () async { final v = widget.record; v.title = title.text; v.status = status; v.views = int.tryParse(views.text) ?? 0; v.clicks = int.tryParse(clicks.text) ?? 0; v.orders = int.tryParse(orders.text) ?? 0; v.revenue = double.tryParse(revenue.text.replaceAll(',', '.')) ?? 0; v.commission = double.tryParse(commission.text.replaceAll(',', '.')) ?? 0; await widget.store.save(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.save), label: const Text('Lưu kết quả')), TextButton.icon(onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Xóa bản ghi?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa'))])); if (ok == true) { widget.store.videos.removeWhere((x) => x.id == widget.record.id); await widget.store.save(); if (context.mounted) Navigator.pop(context); } }, icon: const Icon(Icons.delete_outline), label: const Text('Xóa bản ghi'))]));
}

class StatsPage extends StatelessWidget {
  final StudioStore store;
  const StatsPage({super.key, required this.store});
  @override Widget build(BuildContext context) {
    int views = 0, clicks = 0, orders = 0;
    double revenue = 0, commission = 0;
    for (final v in store.videos) { views += v.views; clicks += v.clicks; orders += v.orders; revenue += v.revenue; commission += v.commission; }
    final byCategory = <String, double>{};
    for (final v in store.videos) { final c = store.product(v.productId)?.category ?? 'Đã xóa'; byCategory[c] = (byCategory[c] ?? 0) + v.commission; }
    return ListView(padding: const EdgeInsets.all(16), children: [const Text('Kết quả nhập thủ công', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 10), GridView.count(crossAxisCount: 2, childAspectRatio: 1.35, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [metric('Lượt xem', '$views', Icons.visibility_outlined), metric('Lượt nhấp', '$clicks', Icons.ads_click), metric('Đơn hợp lệ', '$orders', Icons.shopping_bag_outlined), metric('Doanh thu', money(revenue), Icons.payments_outlined), metric('Hoa hồng', money(commission), Icons.savings_outlined), metric('CTR', views == 0 ? '0%' : '${(clicks / views * 100).toStringAsFixed(2)}%', Icons.percent)]), const SizedBox(height: 14), const Text('Hoa hồng theo ngành', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), if (byCategory.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Chưa có dữ liệu.')), ...byCategory.entries.map((e) => ListTile(title: Text(e.key), trailing: Text(money(e.value)))), const SizedBox(height: 12), const Text('Lưu ý: Không phải số liệu trực tiếp từ TikTok Shop. Doanh thu và hoa hồng được nhập trong từng bản ghi video.', style: TextStyle(color: Colors.black54))]);
  }
}
