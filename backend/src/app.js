require("dotenv").config()
const express = require("express")
const errorMiddleware = require("./middlewares/error.middleware")
const cors = require("cors")
const cookieParser = require("cookie-parser")
const authRoutes = require("./modules/auth/auth.routes")
const userRoutes = require("./modules/user/user.routes")

const app = express()
app.use(
  cors({
    origin: "http://localhost:5173",
    credentials: true,
  }),
)
app.use(cookieParser())

app.use(express.json())

app.use("/api/auth", authRoutes)
app.use("/api/users", userRoutes)
app.use(errorMiddleware)
module.exports = app
