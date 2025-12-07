// course_routes.js

const express = require('express');
const router = express.Router();
const { callProcedure } = require('../db_connector');

// API: Sửa Khóa học (PUT /api/courses/:id)
router.put('/:id', async (req, res) => {
    const p_id = req.params.id;
    const { name, language, price } = req.body; // Các trường cần cập nhật
    try {
        // Gọi thủ tục SQL: update_course
        await callProcedure('update_course', [p_id, name, language, price]);
        res.send({ message: `Cập nhật Khóa học ID ${p_id} thành công!` });
    } catch (error) {
        // Xử lý lỗi Logic từ SQL (ví dụ: giá âm, dữ liệu không hợp lệ)
        res.status(400).send({ error: error.message });
    }
});

// API: Xóa Khóa học (DELETE /api/courses/:id)
router.delete('/:id', async (req, res) => {
    const p_id = req.params.id;
    try {
        // Gọi thủ tục SQL: delete_course
        await callProcedure('delete_course', [p_id]);
        res.send({ message: `Xóa Khóa học ID ${p_id} thành công!` });
    } catch (error) {
        // Xử lý lỗi Logic từ SQL (ví dụ: Khóa học đã có sinh viên đăng ký)
        res.status(400).send({ error: error.message });
    }
});

module.exports = router;