const twilio = require("twilio");

const formatPhoneToE164 = (phone) => {
  // Chuyển 098... thành +8498...
  if (phone.startsWith("0")) {
    return `+84${phone.substring(1)}`;
  }
  // Nếu đã bắt đầu bằng + thì giữ nguyên
  if (phone.startsWith("+")) {
    return phone;
  }
  // Thêm mặc định +84 nếu không có gì
  return `+84${phone}`;
};

const sendOtp = async (phone) => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

  if (!accountSid || !authToken || !serviceSid) {
    console.warn("Twilio Verify credentials missing. Check .env file.");
    // Mock for local testing if env is missing
    return true; 
  }

  const formattedPhone = formatPhoneToE164(phone);

  try {
    const client = twilio(accountSid, authToken);
    await client.verify.v2.services(serviceSid)
      .verifications
      .create({ to: formattedPhone, channel: "sms" });
    return true;
  } catch (error) {
    console.error("Error sending OTP via Twilio Verify:", error);
    throw new Error(`Failed to send OTP: ${error.message}`);
  }
};

const verifyOtp = async (phone, code) => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

  if (!accountSid || !authToken || !serviceSid) {
    console.warn("Twilio Verify credentials missing. Mocking success.");
    if (code !== "123456") {
      throw new Error("Mã OTP không đúng (Mock mode: nhập 123456)");
    }
    return true; 
  }

  const formattedPhone = formatPhoneToE164(phone);

  try {
    const client = twilio(accountSid, authToken);
    const verificationCheck = await client.verify.v2.services(serviceSid)
      .verificationChecks
      .create({ to: formattedPhone, code });

    if (verificationCheck.status !== "approved") {
      throw new Error("Mã OTP không đúng hoặc đã hết hạn");
    }
    return true;
  } catch (error) {
    console.error("Error verifying OTP via Twilio Verify:", error);
    throw new Error(`Failed to verify OTP: ${error.message}`);
  }
};

module.exports = { sendOtp, verifyOtp };
