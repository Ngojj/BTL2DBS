// db_connector.js (Dùng thư viện mysql2)

const mysql = require('mysql2/promise');

// Thay đổi thông tin kết nối của bạn
const dbConfig = {
    host: 'localhost',
    port: 3307,
    user: 'root', 
    password: 'hiep2005@', // Đã cập nhật mật khẩu của bạn
    database: 'elearning_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
};

// Tạo Connection Pool
const pool = mysql.createPool(dbConfig); // Đối tượng pool được tạo ở đây

// Hàm tiện ích để gọi Stored Procedure
async function callProcedure(procedureName, params = []) {
    try {
        // Tạo chuỗi tham số: ?, ?, ?
        const paramPlaceholders = params.map(() => '?').join(', ');
        const query = `CALL ${procedureName}(${paramPlaceholders})`;
        
        // Thực thi query
        const [results] = await pool.query(query, params);
        
        // Stored procedure trả về mảng kết quả (thường là [ [dữ liệu], [thông tin metadata] ])
        // Trả về mảng dữ liệu đầu tiên
        return results[0];
    } catch (error) {
        console.error(`Lỗi khi gọi procedure ${procedureName}:`, error.message);
        // Ném lỗi lên để API xử lý và trả về cho người dùng
        throw new Error(error.message); 
    }
}

// CẬP NHẬT: Export cả 'pool' để có thể gọi pool.query() trực tiếp trong user_routes.js
module.exports = {
    callProcedure,
    pool // <<--- Đã thêm pool vào danh sách export
};