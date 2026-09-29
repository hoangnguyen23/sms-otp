SMS OTP Setup Guide
1. Yêu cầu
Node.js

npm

Twilio Account

Twilio Verify Service

Backend Node.js đã được cài đặt

Twilio Verify tự tạo mã OTP và gửi mã qua SMS, backend không cần tự generate OTP.
2. Cài Twilio SDK
Trong thư mục backend:

npm install twilio

3. Tạo Twilio Verify Service
Đăng nhập Twilio Console:

https://console.twilio.com/

Vào:

Verify → Services → Create new

Tạo một service, ví dụ:

Friendly name: MyApp OTP
Verification channel: SMS

Sau khi tạo, lấy Service SID có dạng:

VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Verify Service dùng để cấu hình và quản lý quá trình tạo/kiểm tra OTP.
4. Cấu hình .env
Thêm vào file .env:

TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Không commit file .env lên Git.

Có thể thêm .env vào .gitignore:

.env

5. Gửi OTP
Backend gọi Twilio Verify:

const twilio = require("twilio");

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

async function sendOtp(phone) {
  return await client.verify.v2
    .services(process.env.TWILIO_VERIFY_SERVICE_SID)
    .verifications.create({
      channel: "sms",
      to: phone,
    });
}

Số điện thoại phải sử dụng định dạng quốc tế E.164.

Ví dụ:

0985640248

chuyển thành:

+84985640248

Twilio Verify sẽ tự tạo mã OTP và gửi SMS.
6. Xác minh OTP
Khi người dùng nhập mã OTP trên Flutter:

async function verifyOtp(phone, code) {
  return await client.verify.v2
    .services(process.env.TWILIO_VERIFY_SERVICE_SID)
    .verificationChecks.create({
      to: phone,
      code,
    });
}

Nếu OTP chính xác, Twilio trả về:

{
  "status": "approved"
}

Nếu mã không đúng, trạng thái sẽ không phải approved. Twilio cũng tự quản lý thời gian hết hạn và số lần kiểm tra của verification. 
7. Flow của ứng dụng
Đối với chức năng Forgot Password:

Flutter
   ↓
Nhập số điện thoại
   ↓
POST /forgot-password/send-otp
   ↓
Node.js
   ↓
Twilio Verify
   ↓
SMS OTP
   ↓
Người dùng nhập OTP
   ↓
POST /forgot-password/verify-otp
   ↓
Twilio Verify
   ↓
OTP hợp lệ
   ↓
Cho phép đặt mật khẩu mới

8. Lưu ý khi sử dụng Twilio Trial
Tài khoản Twilio Trial chỉ có thể gửi verification message đến các số điện thoại đã được xác minh trong Twilio Console. Khi triển khai production và muốn gửi đến người nhận bất kỳ, cần nâng cấp tài khoản theo yêu cầu của Twilio.
9. Tài liệu chính thức
Twilio Verify Node.js Quickstart:
https://www.twilio.com/docs/verify/quickstarts/node-express

Twilio Verify API:
https://www.twilio.com/docs/verify/api

Twilio Verification API:
https://www.twilio.com/docs/verify/api/verification

Twilio Verification Check:
https://www.twilio.com/docs/verify/api/verification-check