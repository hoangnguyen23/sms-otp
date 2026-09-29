const errorMiddleware = (err, req, res, next) => {
  if (err.code === "P2002") {
    const fields = err.meta?.target ?? [];

    return res.status(400).json({
      success: false,
      message: `${fields.join(", ")} đã tồn tại`,
    });
  }

  if (err.code === "P2025") {
    return res.status(404).json({
      success: false,
      message: "Không tìm thấy dữ liệu",
    });
  }
  if (err.code === "P2003") {
    return res.status(404).json({
      success: false,
      message: "Lỗi khoá ngoại",
    });
  }
  console.log(err)

  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || "Interval server error",
    ...(err.details && { errors: err.details }),
  })
}

module.exports = errorMiddleware
