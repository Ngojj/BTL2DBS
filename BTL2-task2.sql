use elearning_db;

DROP PROCEDURE IF EXISTS insert_user;
DROP PROCEDURE IF EXISTS update_user;
DROP PROCEDURE IF EXISTS delete_user;


DELIMITER $$

-- =========================================================
-- 1. INSERT USER (Có kiểm tra dữ liệu hợp lệ)
-- =========================================================
CREATE PROCEDURE insert_user (
    IN p_email VARCHAR(255),
    IN p_firstName VARCHAR(255),
    IN p_lastName VARCHAR(255),
    IN p_username VARCHAR(64),
    IN p_password VARCHAR(64),
    IN p_role VARCHAR(20),
    IN p_bankName VARCHAR(20),
    IN p_bankAccount VARCHAR(255)
)
BEGIN
    -- 1. Validate EMAIL
    IF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Định dạng Email không hợp lệ.';
    END IF;

    -- 2. Validate USERNAME
    IF p_username NOT REGEXP '^[A-Za-z0-9_]{4,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Username phải dài ít nhất 4 ký tự và chỉ chứa chữ cái, số, hoặc gạch dưới.';
    END IF;

    -- 3. Validate PASSWORD
    IF p_password NOT REGEXP '^[A-Za-z0-9!@#$%^&*()_+=-]{6,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Mật khẩu phải dài ít nhất 6 ký tự và có thể chứa ký tự đặc biệt.';
    END IF;

    -- 4. Validate ROLE
    IF p_role NOT IN ('admin', 'student', 'teacher') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Vai trò (Role) phải là admin, student, hoặc teacher.';
    END IF;

    -- 5. Validate BANK ACCOUNT
    IF p_bankAccount NOT REGEXP '^[0-9]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số tài khoản ngân hàng chỉ được chứa chữ số.';
    END IF;

    -- 6. Kiểm tra EMAIL và USERNAME đã tồn tại chưa (UNIQUE constraint)
    IF EXISTS (SELECT 1 FROM `user` WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Email đã tồn tại trong hệ thống.';
    END IF;

    IF EXISTS (SELECT 1 FROM `user` WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Username đã tồn tại trong hệ thống.';
    END IF;

    -- INSERT DATA
    INSERT INTO `user` (`email`, `firstName`, `lastName`, `username`, `password`, `role`, `bankName`, `bankAccount`)
    VALUES (p_email, p_firstName, p_lastName, p_username, p_password, p_role, p_bankName, p_bankAccount);

END $$

-- =========================================================
-- 2. UPDATE USER (Có kiểm tra dữ liệu hợp lệ)
-- =========================================================
CREATE PROCEDURE update_user (
    IN p_id INT,
    IN p_email VARCHAR(255),
    IN p_firstName VARCHAR(255),
    IN p_lastName VARCHAR(255),
    IN p_username VARCHAR(64),
    IN p_password VARCHAR(64),
    IN p_role VARCHAR(20),
    IN p_bankName VARCHAR(20),
    IN p_bankAccount VARCHAR(255)
)
BEGIN
    -- 1. Kiểm tra ID có tồn tại
    IF NOT EXISTS (SELECT 1 FROM `user` WHERE id = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: User ID không tồn tại.';
    END IF;

    -- 2. Validate EMAIL
    IF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Định dạng Email không hợp lệ.';
    END IF;

    -- 3. Validate USERNAME
    IF p_username NOT REGEXP '^[A-Za-z0-9_]{4,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Username phải dài ít nhất 4 ký tự và chỉ chứa chữ cái, số, hoặc gạch dưới.';
    END IF;

    -- 4. Validate PASSWORD
    IF p_password NOT REGEXP '^[A-Za-z0-9!@#$%^&*()_+=-]{6,}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Mật khẩu phải dài ít nhất 6 ký tự và có thể chứa ký tự đặc biệt.';
    END IF;

    -- 5. Validate ROLE
    IF p_role NOT IN ('admin', 'student', 'teacher') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Vai trò (Role) phải là admin, student, hoặc teacher.';
    END IF;

    -- 6. Validate BANK ACCOUNT
    IF p_bankAccount NOT REGEXP '^[0-9]+$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số tài khoản ngân hàng chỉ được chứa chữ số.';
    END IF;

    -- 7. Kiểm tra EMAIL và USERNAME đã tồn tại chưa (trừ chính user)
    IF EXISTS (SELECT 1 FROM `user` WHERE email = p_email AND id <> p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Email đã được sử dụng bởi user khác.';
    END IF;

    IF EXISTS (SELECT 1 FROM `user` WHERE username = p_username AND id <> p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Username đã được sử dụng bởi user khác.';
    END IF;

    -- UPDATE DATA
    UPDATE `user`
    SET 
        `email` = p_email,
        `firstName` = p_firstName,
        `lastName` = p_lastName,
        `username` = p_username,
        `password` = p_password,
        `role` = p_role,
        `bankName` = p_bankName,
        `bankAccount` = p_bankAccount
    WHERE `id` = p_id;

END $$

-- =========================================================
-- 3. DELETE USER (Có kiểm tra nghiệp vụ)
-- =========================================================
CREATE PROCEDURE delete_user (
    IN p_id INT
)
BEGIN
    DECLARE user_role VARCHAR(20);
    DECLARE err_msg VARCHAR(255);

    -- Lấy role của user
    SELECT `role` INTO user_role FROM `user` WHERE `id` = p_id;

    -- 1. Kiểm tra user có tồn tại
    IF user_role IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: User ID không tồn tại trong hệ thống.';
    END IF;

    -- 2. Kiểm tra nghiệp vụ nếu là TEACHER
    IF user_role = 'teacher' THEN
        IF EXISTS (SELECT 1 FROM `course` WHERE `teacherId` = p_id) THEN
            SET err_msg = CONCAT('Lỗi: Không thể xóa giáo viên (ID ', p_id, ') vì người này đang có khóa học.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
        END IF;
    END IF;

    -- 3. Kiểm tra nghiệp vụ nếu là STUDENT
    IF user_role = 'student' THEN
        IF EXISTS (SELECT 1 FROM `join` WHERE `studentId` = p_id AND `progress` < 100) THEN
            SET err_msg = CONCAT('Lỗi: Không thể xóa học viên (ID ', p_id, ') vì đang tham gia khóa học chưa hoàn thành.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
        END IF;
    END IF;

    -- DELETE DATA
    DELETE FROM `user` WHERE `id` = p_id;

END $$

-- 2.2.1 
CREATE TRIGGER trg_check_max_enrollment
BEFORE INSERT ON `join`
FOR EACH ROW
BEGIN
    DECLARE enrolled_count INT;
    DECLARE max_courses INT DEFAULT 4;
    DECLARE err_msg VARCHAR(255);

    -- Đếm số khóa học sinh viên đang tham gia (progress < 100)
    -- Giả định khóa học mới chèn vào sẽ có progress mặc định là 0 (< 100)
    SELECT COUNT(*) INTO enrolled_count
    FROM `join`
    WHERE `studentId` = NEW.studentId
      AND `progress` < 100; -- Chỉ đếm các khóa học chưa hoàn thành

    -- Kiểm tra: Nếu số khóa học hiện tại vượt quá giới hạn (4)
    IF enrolled_count >= max_courses THEN
        SET err_msg = CONCAT('Lỗi Nghiệp vụ: Học viên (ID ', NEW.studentId, ') đã đạt giới hạn ', max_courses, ' khóa học đang tham gia chưa hoàn thành.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
    END IF;
END $$
DELIMITER ;
-- Thêm khóa học 6 (Course 6, studentId 10, progress 10)
INSERT INTO `join` (`courseId`, `studentId`, `dateStart`, `progress`, `GPA`) VALUES (1, 10, CURRENT_DATE(), 10, NULL);
-- Thêm khóa học 7 (Course 7, studentId 10, progress 20)
INSERT INTO `join` (`courseId`, `studentId`, `dateStart`, `progress`, `GPA`) VALUES (2, 10, CURRENT_DATE(), 20, NULL);
-- Thêm khóa học 8 (Course 8, studentId 10, progress 30)
INSERT INTO `join` (`courseId`, `studentId`, `dateStart`, `progress`, `GPA`) VALUES (3, 10, CURRENT_DATE(), 30, NULL);

INSERT INTO `join` (`courseId`, `studentId`, `dateStart`, `progress`) 
VALUES (4, 10, CURRENT_DATE(), 0);

-- 2.2.2

DELIMITER $$

-- Thủ tục tính toán số khóa học đã đăng ký cho một sinh viên
CREATE PROCEDURE calculate_enrolled_courses(IN student_id_param INT)
BEGIN
    DECLARE enrolled_count INT;
    
    -- Đếm tổng số khóa học mà sinh viên này đang tham gia trong bảng join
    SELECT COUNT(*) INTO enrolled_count
    FROM `join`
    WHERE `studentId` = student_id_param;

    -- Cập nhật thuộc tính dẫn xuất trong bảng student
    UPDATE `student`
    SET `numberCoursesEnrolled` = enrolled_count
    WHERE `userId` = student_id_param;
END $$

DELIMITER ;

DELIMITER $$

-- Trigger 1: Kích hoạt SAU khi có sinh viên đăng ký khóa học mới
CREATE TRIGGER trg_update_enrollment_insert
AFTER INSERT ON `join`
FOR EACH ROW
BEGIN
    -- Gọi thủ tục tính toán cho studentId vừa được chèn (NEW.studentId)
    CALL calculate_enrolled_courses(NEW.studentId);
END $$

-- Trigger 2: Kích hoạt SAU khi sinh viên hủy đăng ký/xóa khỏi khóa học
CREATE TRIGGER trg_update_enrollment_delete
AFTER DELETE ON `join`
FOR EACH ROW
BEGIN
    -- Gọi thủ tục tính toán cho studentId bị xóa (OLD.studentId)
    CALL calculate_enrolled_courses(OLD.studentId);
END $$

DELIMITER ;

-- check
-- Xem số khóa học đã đăng ký ban đầu của Student 10 trong bảng student
SELECT numberCoursesEnrolled FROM `student` WHERE userId = 7; -- Kết quả mong đợi: 1


INSERT INTO `join` (`courseId`, `studentId`, `dateStart`, `progress`) 
VALUES (2, 7, CURRENT_DATE(), 10); 

SELECT numberCoursesEnrolled FROM `student` WHERE userId = 7; 
-- Kết quả mong đợi: 2
SELECT courseId, progress FROM `join` WHERE studentId = 7;

DELETE FROM `join` 
WHERE `studentId` = 10 AND `courseId` = 2;
SELECT numberCoursesEnrolled FROM `student` WHERE userId = 10;
DELETE FROM `join` 
WHERE `studentId` = 10 AND `courseId` = 1;

-- 2.3

DELIMITER $$
DROP PROCEDURE IF EXISTS get_course_details;
CREATE PROCEDURE get_course_details (
    IN p_teacherId INT,
    IN p_minPrice DECIMAL(10, 2)
)
BEGIN
    SELECT 
        c.id AS courseId,
        c.name AS courseName,
        c.price,
        u.firstName AS teacherFirstName,
        u.lastName AS teacherLastName
    FROM 
        `course` c
    JOIN 
        `user` u ON c.teacherId = u.id
    WHERE 
        c.teacherId = p_teacherId AND c.price >= p_minPrice
    ORDER BY 
        c.price DESC, c.name ASC;
END $$

DELIMITER ;
CALL get_course_details(1, 100.00);

DELIMITER $$

DROP PROCEDURE IF EXISTS get_teacher_courses;

CREATE PROCEDURE get_teacher_courses (
    IN p_teacherId INT,
    IN p_maxCoursePrice DECIMAL(10, 2)
)
BEGIN
    SELECT 
        u.id AS teacherId,
        CONCAT(u.firstName, ' ', u.lastName) AS teacherName,
        c.id AS courseId,
        c.name AS courseName,
        c.price
    FROM 
        `user` u -- Bảng chính (user)
    JOIN 
        `course` c ON u.id = c.teacherId -- Liên kết 2 bảng
    WHERE 
        u.id = p_teacherId AND c.price <= p_maxCoursePrice -- Mệnh đề WHERE (Sử dụng tham số)
    ORDER BY 
        c.price DESC, c.name ASC; -- Mệnh đề ORDER BY
END $$

DELIMITER ;
CALL get_teacher_courses(1, 100.00);

DELIMITER $$

DROP PROCEDURE IF EXISTS get_avg_gpa_by_course;

-- Tham số: p_minGpa (GPA trung bình tối thiểu), p_minProgress (Tiến độ tối thiểu để tính)
CREATE PROCEDURE get_avg_gpa_by_course (
    IN p_minGpa DECIMAL(3, 2), 
    IN p_minProgress INT 
)
BEGIN
    SELECT 
        j.courseId,
        c.name AS courseName,
        AVG(j.GPA) AS averageGPA, -- Aggregate Function
        COUNT(j.studentId) AS enrolledStudents
    FROM 
        `join` j -- Bảng liên quan đến 2.1
    JOIN 
        `course` c ON j.courseId = c.id -- Liên kết từ 2 bảng trở lên
    WHERE 
        j.progress >= p_minProgress -- Mệnh đề WHERE (sử dụng tham số)
    GROUP BY 
        j.courseId, c.name -- Mệnh đề GROUP BY
    HAVING 
        AVG(j.GPA) >= p_minGpa -- Mệnh đề HAVING (sử dụng tham số)
    ORDER BY 
        averageGPA DESC; -- Mệnh đề ORDER BY
END $$

DELIMITER ;
-- Gọi thủ tục để tìm các khóa học có GPA trung bình từ 3.0 trở lên, chỉ tính điểm của những sinh viên đã đạt tiến độ 50%
CALL get_avg_gpa_by_course(3.0, 50);

-- 2.4
DELIMITER $$

DROP FUNCTION IF EXISTS calculate_teacher_income;

CREATE FUNCTION calculate_teacher_income (
    p_teacherId INT,
    p_startDate DATE,
    p_endDate DATE
)
RETURNS DECIMAL(15, 2)
READS SQL DATA
BEGIN
    -- 1. KHAI BÁO BIẾN (Luôn luôn ở đầu)
    DECLARE v_totalIncome DECIMAL(15, 2) DEFAULT 0.00;
    DECLARE v_coursePrice DECIMAL(10, 2);
    DECLARE v_finished INT DEFAULT 0;

    -- 2. KHAI BÁO CON TRỎ (CURSOR) (Phải ở đây)
    DECLARE course_cursor CURSOR FOR
        SELECT 
            c.price
        FROM 
            `course` c
        JOIN 
            `join` j ON c.id = j.courseId
        WHERE 
            c.teacherId = p_teacherId
            AND j.dateStart BETWEEN p_startDate AND p_endDate;
            
    -- 3. KHAI BÁO HANDLER (Phải ở đây)
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;

    -- 4. BẮT ĐẦU CÁC LỆNH THỰC THI (IF, OPEN, FETCH, SET...)
    
    -- Kiểm tra Tham số đầu vào (Lệnh IF được phép ở đây)
    IF p_startDate IS NULL OR p_endDate IS NULL OR p_teacherId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Các tham số ngày hoặc ID giáo viên không được để trống.';
    END IF;

    OPEN course_cursor;

    read_loop: LOOP
        FETCH course_cursor INTO v_coursePrice; 
        
        IF v_finished = 1 THEN
            LEAVE read_loop;
        END IF;

        SET v_totalIncome = v_totalIncome + v_coursePrice;
        
    END LOOP read_loop;

    CLOSE course_cursor;

    RETURN v_totalIncome;
END $$

DELIMITER ;

SELECT calculate_teacher_income(5, '2024-01-01', '2025-12-31') AS TeacherIncome2024;

DELIMITER $$

DROP FUNCTION IF EXISTS check_student_progress $$

-- Hàm kiểm tra xem sinh viên có khóa học nào dưới ngưỡng tiến độ hay không
CREATE FUNCTION check_student_progress (
    p_studentId INT,
    p_minProgressThreshold INT
)
RETURNS VARCHAR(100)
READS SQL DATA
BEGIN
    -- 1. KHAI BÁO BIẾN (Phải ở đầu)
    DECLARE v_progress INT;
    DECLARE v_courseName VARCHAR(255);
    DECLARE v_finished INT DEFAULT 0;
    
    -- 2. KHAI BÁO CON TRỎ (CURSOR) (Phải ở đầu)
    DECLARE progress_cursor CURSOR FOR
        SELECT 
            j.progress,
            c.name
        FROM 
            `join` j
        JOIN 
            `course` c ON j.courseId = c.id
        WHERE 
            j.studentId = p_studentId;
            
    -- 3. KHAI BÁO HANDLER (Phải ở đầu)
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;

    -- 4. BẮT ĐẦU CÁC LỆNH THỰC THI (IF, OPEN, LOOP...)
    
    -- Kiểm tra Tham số đầu vào (Sử dụng IF)
    IF p_studentId IS NULL OR p_minProgressThreshold < 0 OR p_minProgressThreshold > 100 THEN
        RETURN 'Lỗi: ID sinh viên không hợp lệ hoặc ngưỡng tiến độ phải từ 0 đến 100.';
    END IF;

    OPEN progress_cursor;

    -- Dùng Vòng lặp (LOOP) để duyệt qua các khóa học
    progress_loop: LOOP
        FETCH progress_cursor INTO v_progress, v_courseName; 
        
        IF v_finished = 1 THEN
            LEAVE progress_loop;
        END IF;

        -- Sử dụng IF để kiểm tra điều kiện
        IF v_progress < p_minProgressThreshold THEN
            CLOSE progress_cursor;
            RETURN CONCAT('Cảnh báo: Khóa học "', v_courseName, '" chưa đạt (', v_progress, '%).');
        END IF;
        
    END LOOP progress_loop;

    CLOSE progress_cursor;

    RETURN 'Hoàn thành: Tất cả các khóa học đều đạt ngưỡng tiến độ.';
END $$

DELIMITER ;
SELECT check_student_progress(7, 50) AS ProgressCheck_50;