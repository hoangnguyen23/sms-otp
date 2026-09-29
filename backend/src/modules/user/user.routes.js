const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  getUsers,
  getUserById,
  getProfile,
  updateProfile,
  updateUser,
  updateRole,
  deleteUser,
} = require("./user.controller")
const { getUsersSchema, idSchema, updateProfileSchema, updateUserSchema, updateRoleSchema } = require("./user.validate")

router.get("/", authenticate, authorize("ADMIN"), validate(getUsersSchema), asyncHandler(getUsers))

router.get("/me", authenticate, asyncHandler(getProfile))

router.get("/:id", authenticate, authorize("ADMIN"), validate(idSchema), asyncHandler(getUserById))

router.patch("/me", authenticate, validate(updateProfileSchema), asyncHandler(updateProfile))

router.patch("/:id", authenticate, authorize("ADMIN"), validate(updateUserSchema), asyncHandler(updateUser))

router.patch("/:id/role", authenticate, authorize("ADMIN"), validate(updateRoleSchema), asyncHandler(updateRole))

router.delete("/:id", authenticate, authorize("ADMIN"), validate(idSchema), asyncHandler(deleteUser))


module.exports = router
