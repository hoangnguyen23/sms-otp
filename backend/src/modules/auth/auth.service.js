const prisma = require("../../lib/prisma")
const jwt = require("jsonwebtoken")
const bcrypt = require("bcryptjs")
const AppError = require("../../errors/AppError")

const register = async ({ name, email, phone, password }) => {

    const hashPassword = await bcrypt.hash(password, 10)
    const user = await prisma.user.create({
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
      },
      data: {
        name,
        email,
        phone,
        password: hashPassword,
      },
    })
    return user
  
}
const login = async ({ email, password }) => {
  const user = await prisma.user.findUnique({
    where: {email},
  })

  if (!user) {
    throw new AppError("Email hoặc password không hợp lệ", 401)
  }

  const isMatch = await bcrypt.compare(password, user.password)
  if (!isMatch) {
    throw new AppError("Email hoặc password không hợp lệ", 401)
  }

  const accessToken = generateAccessToken(user)
  const refreshToken = generateRefreshToken(user)
  await prisma.refreshToken.create({
    data: {
      refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  })
  return {
    user:{
        id: user.id,
        name: user.name,
        email: user.email,
    },
    accessToken,
    refreshToken
  }
}
const refreshToken = async (refreshToken) => {
  let decoded

  try {
    decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET)
  } catch {
    throw new AppError("Refresh token không hợp lệ", 401)
  }

  const storedToken = await prisma.refreshToken.findUnique({
    where: {
      refreshToken
    }
  })

  if(!storedToken) {
    throw new AppError("Refresh token không hợp lệ", 401)
  }

  if(storedToken.expiresAt < new Date()){
    await prisma.refreshToken.delete({
      where: {
        refreshToken
      }
    })
    throw new AppError("Refresh token không hợp lệ", 401)
  }

  const user = await prisma.user.findUnique({
    where: {
      id: decoded.id
    }
  })
  if(!user){
    throw new AppError("Refresh token không hợp lệ", 401)
  }
  return generateAccessToken(user)
}
const logout = async (refreshToken) => {
    return prisma.refreshToken.delete({
      where: {
        refreshToken
      }
    })
}
const changePassword = async ({userId, oldPassword, newPassword}) => {
  const user = await prisma.user.findUnique({
    where: {
      id: userId
    }
  })
  if(!user){
    throw new AppError("User không tồn tại", 404)
  }

  const isMatch = await bcrypt.compare(oldPassword, user.password)
  if(!isMatch) {
    throw new AppError("Mật khẩu cũ không đúng", 400)
  }
  const isSame = await bcrypt.compare(newPassword, user.password)
  if(isSame){
    throw new AppError("Mật khẩu mới phải khác mật khẩu cũ", 400)
  }
  const hashPassword = await bcrypt.hash(newPassword, 10)

  await prisma.$transaction([
    prisma.refreshToken.deleteMany({
      where: {
        userId
      }
    }),
    prisma.user.update({
      data: {
        password: hashPassword
      },
      where: {
        id: userId
      }
    })
  ])
}

const generateAccessToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
      name: user.name,
      role: user.role,
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: "15m",
    },
  )
}

const generateRefreshToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
    },
    process.env.REFRESH_TOKEN_SECRET,
    {
      expiresIn: "7d",
    },
  )
}
const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, process.env.ACCESS_TOKEN_SECRET)
  } catch {
    throw new AppError("Unauthorized", 401)
  }
}

const { sendOtp: twilioSendOtp, verifyOtp: twilioVerifyOtp } = require("../../utils/sms")

const sendOtp = async ({ phone }) => {
  const user = await prisma.user.findFirst({ where: { phone } })
  if (!user) {
    throw new AppError("Số điện thoại chưa được đăng ký", 404)
  }

  // Use Twilio Verify API to send OTP
  await twilioSendOtp(phone)
}

const verifyOtp = async ({ phone, otp }) => {
  // Use Twilio Verify API to check OTP
  await twilioVerifyOtp(phone, otp)

  // Return some temporary token or signal to allow reset-password
  // We can generate a short-lived token for reset
  const user = await prisma.user.findFirst({ where: { phone } })
  if (!user) {
    throw new AppError("Không tìm thấy người dùng", 404)
  }

  const resetToken = jwt.sign({ id: user.id, reset: true }, process.env.ACCESS_TOKEN_SECRET, { expiresIn: "10m" })
  return { resetToken }
}

const resetPassword = async ({ resetToken, newPassword }) => {
  let decoded
  try {
    decoded = jwt.verify(resetToken, process.env.ACCESS_TOKEN_SECRET)
  } catch {
    throw new AppError("Reset token không hợp lệ hoặc hết hạn", 401)
  }

  if (!decoded.reset) {
    throw new AppError("Token không hợp lệ", 401)
  }

  const hashPassword = await bcrypt.hash(newPassword, 10)
  await prisma.user.update({
    where: { id: decoded.id },
    data: { password: hashPassword },
  })
}

module.exports = {
  register,
  login,
  logout,
  refreshToken,
  changePassword,
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  sendOtp,
  verifyOtp,
  resetPassword,
}
