# TikTok Affiliate Studio (Flutter)

Ứng dụng quản lý sản phẩm TikTok Affiliate, kịch bản 3 cảnh, ảnh tham chiếu, prompt AI, lịch sử video và số liệu kinh doanh.

## Khởi chạy

Yêu cầu Flutter SDK tương thích Dart >= 3.3 và Android Studio/Android SDK.

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

Lệnh `flutter create` bổ sung thư mục `android/`, `ios/` và các tệp nền tảng mặc định. Mã nguồn ứng dụng nằm trong `lib/main.dart`.

## Build APK

```bash
flutter build apk --release
```

File APK mặc định tại `build/app/outputs/flutter-apk/app-release.apk`.

## Chức năng

- 9 sản phẩm và 27 cảnh mẫu, tùy chỉnh toàn bộ.
- Thêm/sửa/xóa sản phẩm, giá, tỷ lệ hoa hồng, link Affiliate.
- Chọn ảnh sản phẩm, KOC, bối cảnh từ thư viện và sao chép vào vùng lưu trữ ứng dụng.
- Chỉnh sửa hook, mô tả hình ảnh, chữ trên video, thời lượng cảnh.
- Tạo prompt thống nhất 9:16, 1080p, 30 FPS; sao chép/chia sẻ văn bản.
- Lịch sử video với 4 trạng thái và số liệu nhập thủ công.
- Dashboard và thống kê hoa hồng theo ngành, CTR.

## Lưu ý

- Không có tích hợp TikTok Shop API, Gemini API hoặc dịch vụ render video. Prompt được tạo từ kịch bản theo mẫu, không gọi mô hình AI.
- Số liệu không tự cập nhật; hãy xác minh giá và tỷ lệ hoa hồng trước khi sử dụng.
- SharedPreferences phù hợp MVP lưu trữ cục bộ, không phải giải pháp đồng bộ hoặc backup lâu dài.
- Khi xóa ứng dụng, dữ liệu cục bộ và ảnh đã nhập có thể bị xóa.
- Ứng dụng chưa được chạy kiểm thử trên thiết bị trong môi trường tạo mã nguồn này.
- Trên iOS, thêm `NSPhotoLibraryUsageDescription` vào `ios/Runner/Info.plist` khi cần truy cập thư viện ảnh.
