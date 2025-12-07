// user_routes.js (Backend API - Express)

const express = require('express');
const router = express.Router();
// Cần import cả 'pool' vì nó được sử dụng trong API 5 để gọi SQL Function.
// Lưu ý: Cần đảm bảo file db_connector.js đã export 'pool'.
const { callProcedure, pool } = require('../db_connector'); 

// --- 1. API: Thêm User (POST /api/users) ---
router.post('/', async (req, res) => {
    const { email, firstName, lastName, username, password, role, bankName, bankAccount } = req.body;
    try {
        // Gọi thủ tục 2.1: insert_user
        await callProcedure('insert_user', [
            email, firstName, lastName, username, password, role, bankName, bankAccount
        ]);
        res.status(201).send({ message: 'Thêm người dùng thành công!' });
    } catch (error) {
        // Xử lý lỗi từ SQL (SIGNAL SQLSTATE)
        res.status(400).send({ error: error.message });
    }
});

// --- 2. API: Sửa User (PUT /api/users/:id) ---
router.put('/:id', async (req, res) => {
    // Đảm bảo id là kiểu số nguyên (INT) nếu cần cho Stored Procedure
    const p_id = parseInt(req.params.id); 
    const { email, firstName, lastName, username, password, role, bankName, bankAccount } = req.body;
    try {
        // Gọi thủ tục 2.1: update_user
        await callProcedure('update_user', [
            p_id, email, firstName, lastName, username, password, role, bankName, bankAccount
        ]);
        res.send({ message: `Cập nhật User ID ${p_id} thành công!` });
    } catch (error) {
        res.status(400).send({ error: error.message });
    }
});

// --- 3. API: Xóa User (DELETE /api/users/:id) ---
router.delete('/:id', async (req, res) => {
    // Đảm bảo id là kiểu số nguyên (INT)
    const p_id = parseInt(req.params.id); 
    try {
        // Gọi thủ tục 2.1: delete_user (Có kiểm tra nghiệp vụ)
        await callProcedure('delete_user', [p_id]);
        res.send({ message: `Xóa User ID ${p_id} thành công!` });
    } catch (error) {
        // Xử lý lỗi nghiệp vụ (ví dụ: giáo viên đang có khóa học)
        res.status(400).send({ error: error.message });
    }
});

// --- 4. API: Lấy danh sách Khóa học của Giáo viên (GET /api/users/courses/:teacherId) - Thủ tục 2.3 ---
router.get('/courses/:teacherId', async (req, res) => {
    const p_teacherId = parseInt(req.params.teacherId);
    // Chuyển maxPrice sang số, nếu không có thì mặc định là số lớn
    const p_maxCoursePrice = parseInt(req.query.maxPrice) || 999999; 
    
    // Kiểm tra và validate dữ liệu nhập vào (yêu cầu 3.2)
    if (isNaN(p_teacherId) || p_teacherId <= 0) {
        return res.status(400).send({ error: 'Lỗi: Teacher ID không hợp lệ.' });
    }
    
    try {
        // Gọi thủ tục 2.3: get_teacher_courses
        const courses = await callProcedure('get_teacher_courses', [
            p_teacherId, p_maxCoursePrice
        ]);
        res.send({ data: courses });
    } catch (error) {
        // Lỗi này thường là lỗi SQL (tên bảng sai, tên thủ tục sai)
        console.error("Lỗi khi gọi get_teacher_courses:", error.message);
        res.status(500).send({ error: 'Lỗi máy chủ khi truy vấn dữ liệu.' });
    }
});

// --- 5. API: Tính thu nhập (GET /api/users/income/:teacherId) - Hàm 2.4 ---
router.get('/income/:teacherId', async (req, res) => {
    const p_teacherId = parseInt(req.params.teacherId);
    const { startDate, endDate } = req.query; 

    // Kiểm tra Tham số đầu vào (Validate date)
    if (!startDate || !endDate || isNaN(p_teacherId)) {
        return res.status(400).send({ error: 'Vui lòng cung cấp Teacher ID, Ngày bắt đầu và Ngày kết thúc hợp lệ.' });
    }
    
    try {
        // Sử dụng pool.query() trực tiếp để gọi Hàm (Function) SQL bằng SELECT
        const [result] = await pool.query(
            'SELECT calculate_teacher_income(?, ?, ?) AS income', 
            [p_teacherId, startDate, endDate]
        );

        // Kiểm tra lỗi logic (nếu hàm 2.4 trả về chuỗi lỗi)
        const income = result[0].income;

        if (income && typeof income === 'string' && income.startsWith('Lỗi:')) {
            return res.status(400).send({ error: income });
        }
        
        res.send({ income: income || 0 });
    } catch (error) {
        console.error("Lỗi khi gọi calculate_teacher_income:", error.message);
        res.status(500).send({ error: 'Lỗi khi tính thu nhập.' });
    }
});

module.exports = router;