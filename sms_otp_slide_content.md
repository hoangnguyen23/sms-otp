# Kiến thức & Nội dung làm Slide: Ứng dụng SMS OTP

Tài liệu này tổng hợp các kiến thức cốt lõi và cấu trúc kỹ thuật của dự án **SMS OTP** để hỗ trợ việc xây dựng slide thuyết trình.

## 1. Tổng quan về hệ thống (Overview)
- **SMS OTP là gì?** OTP (One-Time Password) là mật khẩu sử dụng một lần. SMS OTP là hình thức gửi mã xác thực này qua tin nhắn điện thoại đến người dùng.
- **Mục đích:** Tăng cường bảo mật (Xác thực 2 yếu tố - 2FA), xác minh số điện thoại chính chủ, chống spam tài khoản, và hỗ trợ chức năng quên mật khẩu an toàn.
- **Ưu điểm:** Phổ biến, dễ sử dụng, không yêu cầu smartphone cấu hình cao hay kết nối internet ở thiết bị nhận.

## 2. Công nghệ sử dụng (Tech Stack)
- **Frontend (Mobile App):** Flutter (Dart) - giúp phát triển ứng dụng đa nền tảng (Android/iOS) nhanh chóng với hiệu năng cao.
- **Backend (API Server):** Node.js với framework Express.js - xử lý logic nhanh, bất đồng bộ.
- **Database ORM:** Prisma - Giúp tương tác với cơ sở dữ liệu an toàn, type-safe và dễ dàng quản lý schema.
- **Dịch vụ SMS (3rd Party):** (Ví dụ: Twilio, SpeedSMS, hoặc Firebase Auth tùy thuộc vào cấu hình trong `utils/sms.js`) - Chịu trách nhiệm gửi tin nhắn thực tế qua mạng viễn thông.

## 3. Luồng hoạt động cơ bản (OTP Flow)

### A. Luồng Yêu cầu OTP (Request OTP)
1. **Người dùng:** Nhập số điện thoại trên ứng dụng (Flutter) và nhấn "Nhận mã OTP".
2. **Frontend:** Gửi API request (gọi đến `auth.controller.js`) chứa số điện thoại lên Backend.
3. **Backend:**
   - Kiểm tra (Validate) định dạng số điện thoại (`auth.validate.js`).
   - Khởi tạo mã OTP ngẫu nhiên (thường là 4-6 số).
   - Lưu trữ mã OTP này vào database (hoặc Redis/Memory) kèm theo thời gian hết hạn (ví dụ: 5 phút) (`auth.service.js`).
   - Gọi API của nhà cung cấp dịch vụ SMS (SMS Provider - `utils/sms.js`) để gửi mã.
4. **SMS Provider:** Gửi tin nhắn chứa mã OTP đến điện thoại người dùng.

### B. Luồng Xác thực OTP (Verify OTP)
1. **Người dùng:** Nhận được tin nhắn, nhập mã OTP vào ứng dụng và nhấn "Xác nhận".
2. **Frontend:** Gửi API request chứa số điện thoại và mã OTP lên Backend.
3. **Backend:**
   - Truy vấn database để tìm mã OTP tương ứng với số điện thoại.
   - So sánh mã người dùng nhập với mã trong hệ thống.
   - Kiểm tra thời gian hết hạn (Expired).
   - Nếu hợp lệ: Trả về token xác thực (JWT) hoặc thông báo thành công, sau đó xóa hoặc đánh dấu OTP đã sử dụng.
   - Nếu không hợp lệ: Trả về lỗi (Sai mã hoặc mã đã hết hạn).
4. **Frontend:** Chuyển hướng người dùng vào màn hình chính hoặc cho phép đổi mật khẩu mới.

## 4. Các yếu tố Bảo mật & Tối ưu (Security & Best Practices)
- **Thời gian sống (TTL - Time to Live):** Mã OTP chỉ nên có hiệu lực trong một thời gian ngắn (ví dụ: 60s đến 5 phút) để tránh bị lợi dụng.
- **Rate Limiting (Giới hạn yêu cầu):** Chặn người dùng gửi yêu cầu lấy OTP liên tục (ví dụ: chỉ cho phép 3 lần request/phút) để chống spam SMS gây tốn kém chi phí.
- **Độ phức tạp ngẫu nhiên:** Đảm bảo hàm tạo số ngẫu nhiên an toàn, khó đoán.
- **Xóa OTP sau khi dùng:** Một mã OTP chỉ được xác thực thành công đúng một lần.

## 5. Cấu trúc thư mục (Điểm qua trên slide nếu cần)
- `backend/src/server.js` & `app.js`: Khởi tạo server và cấu hình middleware.
- `backend/src/modules/auth/`: Chứa toàn bộ logic liên quan đến xác thực.
  - `auth.controller.js`: Tiếp nhận request và trả về response.
  - `auth.service.js`: Xử lý logic nghiệp vụ (tạo mã, kiểm tra mã).
  - `auth.validate.js`: Kiểm tra tính hợp lệ của dữ liệu đầu vào.
- `backend/src/utils/sms.js`: Cấu hình tích hợp với dịch vụ gửi tin nhắn.

---
*Gợi ý khi làm slide:*
* *Dùng sơ đồ luồng (Flowchart) cho phần "3. Luồng hoạt động cơ bản" sẽ giúp người xem dễ hiểu nhất.*
* *Nhấn mạnh vào phần "Bảo mật & Tối ưu" để thấy được chiều sâu của dự án.*
