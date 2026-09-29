const z = require("zod")

const registerBodySchema = z.object({
  name: z.string().min(2).max(50),
  email: z.email(),
  phone: z.string().min(10).optional(),
  password: z.string().min(6),
})
const loginBodySchema = z.object({
  email: z.email(),
  password: z.string().min(6),
})
const changePasswordBodySchema = z.object({
  oldPassword: z.string().min(6),
  newPassword: z.string().min(6),
})

const registerSchema = z.object({
  body: registerBodySchema,
})
const loginSchema = z.object({
  body: loginBodySchema,
})
const changePasswordSchema = z.object({
  body: changePasswordBodySchema,
})
const resetPasswordSchema = z.object({
  body: z.object({
    resetToken: z.string(),
    newPassword: z.string().min(6, "Mật khẩu phải có ít nhất 6 ký tự"),
  })
})
const verifyOtpSchema = z.object({
  body: z.object({
    phone: z.string().min(10),
    otp: z.string().length(6, "OTP phải có 6 chữ số"),
  })
})

module.exports = {
  registerSchema,
  loginSchema,
  changePasswordSchema,
  resetPasswordSchema,
  verifyOtpSchema,
}
