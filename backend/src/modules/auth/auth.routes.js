const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const { register, login, logout, refreshToken, changePassword, sendOtp, verifyOtp, resetPassword } = require("./auth.controller")
const authenticate = require("../../middlewares/auth.middleware")
const validate = require("../../middlewares/validation.middleware")
const { registerSchema, loginSchema, changePasswordSchema, resetPasswordSchema, verifyOtpSchema } = require("./auth.validate")
const rateLimit = require("express-rate-limit")

const otpLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 3, // Limit each IP to 3 requests per `window` (here, per 5 minutes)
  message: "Quá nhiều yêu cầu gửi OTP từ IP này, vui lòng thử lại sau 5 phút",
})

router.post("/register", validate(registerSchema), asyncHandler(register))
router.post("/login", validate(loginSchema), asyncHandler(login))
router.post("/logout", asyncHandler(logout))
router.post("/refresh-token", asyncHandler(refreshToken))
router.patch("/change-password", authenticate, validate(changePasswordSchema), asyncHandler(changePassword))

router.post("/send-otp", otpLimiter, asyncHandler(sendOtp))
router.post("/verify-otp", validate(verifyOtpSchema), asyncHandler(verifyOtp))
router.post("/reset-password", validate(resetPasswordSchema), asyncHandler(resetPassword))

module.exports = router
