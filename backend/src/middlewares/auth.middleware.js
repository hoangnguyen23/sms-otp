const AppError = require("../errors/AppError")
const authService = require("../modules/auth/auth.service")
const authenticate = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization
        if(!authHeader || !authHeader.startsWith("Bearer ")){
            throw new AppError("Unauthorized", 401)
        }

        const token = authHeader.split(" ")[1]

        const decoded = authService.verifyAccessToken(token)

        req.user = decoded
        next()
    } catch (error) {
        next(error)
    }
}
module.exports = authenticate