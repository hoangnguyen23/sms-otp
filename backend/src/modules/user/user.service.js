const AppError = require("../../errors/AppError")
const prisma = require("../../lib/prisma")

const getUsers = async (query) => {
  const { role, search, page = 1, limit = 10, sort = "id", order = "asc" } = query

  const where = {}

  if (role) {
    where.role = role
  }

  if (search) {
    where.name = {
      contains: search,
      mode: "insensitive",
    }
  }

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: {
        [sort]: order,
      },
      skip: (page - 1) * limit,
      take: limit,
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    }),
    prisma.user.count({ where }),
  ])

  return {
    users,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPage: Math.ceil(total / limit),
    },
  }
}
const getUserById = async (id) => {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      name: true,
      email: true,
      phone: true,
      address: true,
      role: true,
      createdAt: true,
    },
  })

  if (!user) {
    throw new AppError("User không tồn tại", 404)
  }

  return user
}
const getProfile = async (id) => {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      address: true,
      createdAt: true,
    },
  })

  if (!user) {
    throw new AppError("User không tồn tại", 404)
  }
  return user
}

const updateProfile = async (id, body) => {
  const data = {}

  if (body.name) {
    data.name = body.name
  }
  if (body.phone) {
    data.phone = body.phone
  }
  if (body.address) {
    data.address = body.address
  }

  return prisma.user.update({
    where: { id },
    data,
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      address: true,
    },
  })
}
const updateUser = async (id, body) => {
  try {
    const data = {}

    if (body.name) {
      data.name = body.name
    }
    if (body.phone) {
      data.phone = body.phone
    }
    if (body.address) {
      data.address = body.address
    }
    if (body.email) {
      data.email = body.email
    }

    return await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        address: true,
        role: true,
        updateAt: true,
      },
    })
  } catch (error) {
    if (error.code === "P2025") {
      throw new AppError("User không tồn tại", 404)
    }
    if (error.code === "P2002") {
      throw new AppError("Email đã tồn tại", 409)
    }
    throw error
  }
}
const updateRole = async (id, body) => {
  try {
    return await prisma.user.update({
      where: { id },
      data: {
        role: body.role,
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        updateAt: true,
      },
    })
  } catch (error) {
    if (error.code === "P2025") {
      throw new AppError("User không tồn tại", 404)
    }

    throw error
  }
}
const deleteUser = async (id) => {
  try {
    return await prisma.user.delete({
      where: { id },
    })
  } catch (error) {
    if (error.code === "P2025") {
      throw new AppError("User không tồn tại", 404)
    }
    throw error
  }
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
