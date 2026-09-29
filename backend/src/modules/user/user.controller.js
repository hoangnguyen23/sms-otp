const userService = require("./user.service")
const { getUsersSchema } = require("./user.validate")
const getUsers = async (req, res) => {
  const query = getUsersSchema.parse(req.query)
  const result = await userService.getUsers(query)
  return res.status(200).json({
    success: true,
    data: result
  })
}
const getUserById = async (req, res) => {
  const result = await userService.getUserById(req.params.id)
  return res.status(200).json({
    success: true,
    data: result
  })
}
const getProfile = async (req, res) => {
  const result = await userService.getProfile(req.user.id)
  return res.status(200).json({
    success: true,
    data: result
  })
}
const updateProfile = async (req, res) => {
  const result = await userService.updateProfile(req.user.id, req.body)
  return res.status(200).json({
    success: true,
    data: result
  })
}
const updateUser = async (req, res) => {
  const result = await userService.updateUser(req.params.id, req.body)
  return res.status(200).json({
    success: true,
    data: result
  })
}
const updateRole = async (req, res) => {
  const result = await userService.updateRole(req.params.id, req.body)
  return res.status(200).json({
    success: true,
    data: result
  })
}
const deleteUser = async (req, res) => {
  await userService.deleteUser(req.params.id)
  return res.status(204)
}
module.exports = {
  getUsers,
  getUserById,
  getProfile,
  updateProfile,
  updateUser,
  updateRole,
  deleteUser,
}
