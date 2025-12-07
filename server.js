// server.js

const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const userRoutes = require('./routes/user_routes'); // Import routes đã tạo ở trên
const courseRoutes = require('./routes/course_routes'); // <<< THÊM

const app = express();
const PORT = 3000;

// Middleware
app.use(bodyParser.json()); // Xử lý dữ liệu JSON từ request body
app.use(express.static(path.join(__dirname, 'public'))); // Cho phép truy cập các file HTML/CSS/JS

// Định tuyến API cho người dùng (Phần 3.1 & 3.2)
app.use('/api/users', userRoutes); 
app.use('/api/courses', courseRoutes); // <<< SỬ DỤNG ROUTE MỚI

// Lắng nghe cổng
app.listen(PORT, () => {
    console.log(`Server đang chạy tại http://localhost:${PORT}`);
});