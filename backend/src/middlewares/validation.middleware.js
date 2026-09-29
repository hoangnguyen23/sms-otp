const AppError = require("../errors/AppError")

const validate = (schema) => {
  return (req, res, next) => {
    const result = schema.safeParse({
      body: req.body,
      query: req.query,
      params: req.params,
    })

    if (!result.success) {
      return next(new AppError("Validation failed", 400, result.error.issues))
    }

    req.body = result.data.body
    req.query = result.data.query
    req.params = result.data.params

    next()
  }
}

module.exports = validate
