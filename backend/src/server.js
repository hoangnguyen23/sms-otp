const app = require("./app")

const PORT = 3000
app.listen(PORT, '0.0.0.0', () => console.log(`Server is running at http://0.0.0.0:${PORT}`))
