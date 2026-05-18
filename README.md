# Health4U 💪

> **Dinh dưỡng & Tập luyện thông minh**

Health4U là một ứng dụng di động toàn diện được phát triển bằng Flutter, hỗ trợ người dùng theo dõi sức khỏe, cá nhân hóa lộ trình tập luyện và lên kế hoạch dinh dưỡng mỗi ngày. Với giao diện thân thiện và đồng bộ hóa thời gian thực, Health4U đóng vai trò như một trợ lý sức khỏe cá nhân của riêng bạn.

## 🌟 Tính năng nổi bật

Dựa trên kiến trúc của ứng dụng, Health4U cung cấp 5 nhóm tính năng chính:

* **Trang chủ (Home):**
    * Hiển thị lời chào theo thời gian thực và chuỗi ngày hoạt động liên tục (Streak).
    * Theo dõi lượng calo tiêu thụ trong ngày qua biểu đồ vòng (Calorie Ring).
    * Theo dõi chỉ số BMI và hiển thị lộ trình sức khỏe trong ngày.
* **Dinh dưỡng (Nutrition & Meal Plan):**
    * Lên kế hoạch bữa ăn theo tuần (Sáng, Trưa, Tối, Ăn vặt).
    * Theo dõi chỉ số dinh dưỡng đa lượng (Protein, Tinh bột, Chất béo) cho từng ngày.
* **Đi chợ thông minh (Smart Grocery List):**
    * Tự động tổng hợp danh sách nguyên liệu cần mua dựa trên kế hoạch bữa ăn 7 ngày.
    * Nhóm nguyên liệu thông minh (Rau củ, thịt cá, gia vị...) và theo dõi tiến độ mua sắm.
* **Tập luyện (Workout Schedule):**
    * Cung cấp lịch tập luyện hàng tuần với tính năng vuốt để xem thẻ bài tập của từng ngày.
    * Xem trước các bài tập (Exercises Preview) và thống kê chỉ số tuần.
* **Hồ sơ & Đổi thưởng (Profile & Reward Shop):**
    * Quản lý mục tiêu cá nhân, theo dõi chuỗi ngày kỷ luật (Streak).
    * Tích hợp cửa hàng đổi thưởng (Reward Shop) để tạo động lực cho người dùng.
* **Xác thực & Bảo mật (Auth):**
    * Hệ thống đăng nhập/đăng ký, màn hình giới thiệu (Onboarding) và thiết lập thông tin ban đầu chặt chẽ.
* **Quản trị viên (Admin Dashboard):** Bảng điều khiển riêng để quản lý người dùng, món ăn và bài tập hệ thống.

## 🛠 Công nghệ sử dụng

Dự án áp dụng kiến trúc chuẩn và các công nghệ/thư viện hiện đại nhất:
* **Framework:** Flutter & Dart
* **State Management:** `flutter_riverpod`
* **Routing:** `go_router` (tích hợp Auth Guard chuyển hướng động tự động)
* **Backend & Cơ sở dữ liệu:** Firebase Core & Firebase Platform
* **Background Tasks & Notifications:** `workmanager` và `flutter_local_notifications`
* **Đa ngôn ngữ & Định dạng:** Hỗ trợ hiển thị tiếng Việt và DatePicker tiếng Việt (`flutter_localizations`, `intl`).

## 📂 Cấu trúc thư mục

Ứng dụng được tổ chức theo tính năng (Feature-based architecture) giúp dễ dàng bảo trì và mở rộng:

```text
lib/
├── core/            # Chứa các cài đặt cốt lõi (Colors, Themes, Constants)
├── data/            # Models, Repositories, Services (Firebase, Notifications, Worker...)
├── features/        # Các tính năng chính của ứng dụng
│   ├── admin/       # Dashboard quản trị
│   ├── auth/        # Đăng nhập, Đăng ký, Thiết lập thông tin
│   ├── grocery/     # Đi chợ thông minh
│   ├── home/        # Màn hình chính
│   ├── nutrition/   # Bữa ăn và dinh dưỡng
│   ├── profile/     # Hồ sơ cá nhân và đổi thưởng
│   └── workout/     # Lịch tập luyện
├── router/          # Quản lý luồng điều hướng (GoRouter, ShellScaffold)
└── main.dart        # Entry point của ứng dụng