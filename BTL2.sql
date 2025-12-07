use elearning_db;

-- =========================================================
-- BẢNG USER
-- =========================================================
CREATE TABLE `user` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `firstName` VARCHAR(255) NOT NULL,
    `lastName` VARCHAR(255) NOT NULL,
    `username` VARCHAR(64) NOT NULL UNIQUE,
    `password` VARCHAR(64) NOT NULL,
    `role` VARCHAR(20) NOT NULL,
    `bankName` VARCHAR(20) NOT NULL,
    `bankAccount` VARCHAR(255) NOT NULL,
    CONSTRAINT chk_user_username
        CHECK (`username` REGEXP '^[A-Za-z0-9_]{4,}$'),
    CONSTRAINT chk_user_password
        CHECK (`password` REGEXP '^[A-Za-z0-9!@#$%^&*()_+=-]{6,}$'),
    CONSTRAINT chk_user_email
        CHECK (`email` REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_user_role
        CHECK (`role` IN ('admin','student','teacher')),
    CONSTRAINT chk_user_bankAccount
        CHECK (`bankAccount` REGEXP '^[0-9]+$')
);

-- =========================================================
-- BẢNG STUDENT
-- =========================================================
CREATE TABLE `student` (
    `userId` INT NOT NULL,
    `studentId` VARCHAR(10) NOT NULL UNIQUE,
    `enrollmentDate` DATE NOT NULL,
    `numberCoursesEnrolled` INT NOT NULL DEFAULT 0,
    `numberCoursesCompleted` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`userId`),
    CONSTRAINT chk_student_course_completed
        CHECK (`numberCoursesCompleted` <= `numberCoursesEnrolled`),
    CONSTRAINT fk_student_user FOREIGN KEY (`userId`)
        REFERENCES `user`(`id`) ON DELETE CASCADE
);

DELIMITER $$
CREATE TRIGGER trg_student_check_enrollmentDate
BEFORE INSERT ON student
FOR EACH ROW
BEGIN
    IF NEW.enrollmentDate > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Enrollment date cannot be in the future';
    END IF;
END $$
CREATE TRIGGER trg_student_check_enrollmentDate_update
BEFORE UPDATE ON student
FOR EACH ROW
BEGIN
    IF NEW.enrollmentDate > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Enrollment date cannot be in the future';
    END IF;
END $$
DELIMITER ;

-- =========================================================
-- BẢNG TEACHER
-- =========================================================
CREATE TABLE `teacher` (
    `userId` INT NOT NULL,
    `teacherId` VARCHAR(10) NOT NULL UNIQUE,
    PRIMARY KEY (`userId`),
    CONSTRAINT chk_teacherId
        CHECK (`teacherId` REGEXP '^TC[0-9]{8}$'),
    CONSTRAINT fk_teacher_user FOREIGN KEY (`userId`)
        REFERENCES `user`(`id`) ON DELETE CASCADE
);

-- =========================================================
-- BẢNG COURSE
-- =========================================================
CREATE TABLE `course` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(80) NOT NULL,
    `language` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `teacherId` INT NOT NULL,
    `creTime` DATE NOT NULL DEFAULT (CURRENT_DATE()),
    `avgQuiz` INT NOT NULL DEFAULT 0,
    `price` INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_course_price
        CHECK (`price` >= 0),
    CONSTRAINT chk_course_avgQuiz
        CHECK (`avgQuiz` >= 0),
    CONSTRAINT fk_course_teacher FOREIGN KEY (`teacherId`)
        REFERENCES `teacher`(`userId`) ON DELETE CASCADE
);

-- 1) section
CREATE TABLE `section` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `numOfLecture` INT NOT NULL DEFAULT 0,
    `timeTocomplete` INT NOT NULL DEFAULT 12,
    `teacherId` INT NOT NULL,
    `courseId` INT NOT NULL,
    `creTime` DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_section_timeTocomplete CHECK (`timeTocomplete` > 0),
    CONSTRAINT fk_section_teacher FOREIGN KEY (`teacherId`)
        REFERENCES `teacher`(`userId`) ON DELETE CASCADE,
    CONSTRAINT fk_section_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE
);

-- 2) lecture
CREATE TABLE `lecture` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `state` VARCHAR(20) NOT NULL DEFAULT 'uncomplete',
    `material` VARCHAR(255),
    `reference` VARCHAR(255),
    `sectionId` INT NOT NULL,
    CONSTRAINT chk_lecture_state CHECK (`state` IN ('complete','uncomplete')),
    CONSTRAINT fk_lecture_section FOREIGN KEY (`sectionId`)
        REFERENCES `section`(`id`) ON DELETE CASCADE
);

-- 3) quiz
CREATE TABLE `quiz` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(512) NOT NULL,
    `state` VARCHAR(20) NOT NULL DEFAULT 'opened',
    `attempt` INT NOT NULL DEFAULT 1,
    `duration` INT NOT NULL DEFAULT 10,
    `teacherId` INT NOT NULL,
    `sectionId` INT NOT NULL,
    `creTime` DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_quiz_state CHECK (`state` IN ('opened','closed')),
    CONSTRAINT chk_quiz_attempt CHECK (`attempt` >= 1),
    CONSTRAINT chk_quiz_duration CHECK (`duration` > 0),
    CONSTRAINT fk_quiz_teacher FOREIGN KEY (`teacherId`)
        REFERENCES `teacher`(`userId`) ON DELETE CASCADE,
    CONSTRAINT fk_quiz_section FOREIGN KEY (`sectionId`)
        REFERENCES `section`(`id`) ON DELETE CASCADE
);

-- 4) question
-- Note: composite PK (id, quizId) as in original
CREATE TABLE `question` (
    `id` INT NOT NULL,
    `quizId` INT NOT NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT 'multiple choice',
    `answer` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `creTime` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `teacherId` INT NOT NULL,
    CONSTRAINT pk_question PRIMARY KEY (`id`,`quizId`),
    CONSTRAINT chk_question_type CHECK (`type` IN ('multiple choice','true/false','short answer')),
    CONSTRAINT fk_question_quiz FOREIGN KEY (`quizId`)
        REFERENCES `quiz`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_question_teacher FOREIGN KEY (`teacherId`)
        REFERENCES `teacher`(`userId`) ON DELETE CASCADE
);

-- 5) `option`
-- using backticks for table and column name 'option'
CREATE TABLE `option` (
    `questionId` INT NOT NULL,
    `option` VARCHAR(528) NOT NULL,
    PRIMARY KEY (`questionId`,`option`),
    CONSTRAINT fk_option_question FOREIGN KEY (`questionId`)
        REFERENCES `question`(`id`) ON DELETE CASCADE
);

-- 6) answerRecord
CREATE TABLE `answerRecord` (
    `quizId` INT NOT NULL,
    `studentId` INT NOT NULL,
    `questionId` INT NOT NULL,
    `studentAns` TEXT,
    CONSTRAINT pk_answerRecord PRIMARY KEY (`questionId`,`studentId`),
    CONSTRAINT fk_answerRecord_quiz FOREIGN KEY (`quizId`)
        REFERENCES `quiz`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_answerRecord_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE,
    CONSTRAINT fk_answerRecord_question FOREIGN KEY (`questionId`)
        REFERENCES `question`(`id`) ON DELETE CASCADE
);

-- 7) dO
CREATE TABLE `dO` (
    `quizId` INT NOT NULL,
    `studentId` INT NOT NULL,
    `score` DOUBLE,
    `attemptOrder` INT NOT NULL DEFAULT 1,
    CONSTRAINT pk_dO PRIMARY KEY (`quizId`,`studentId`,`attemptOrder`),
    CONSTRAINT chk_dO_attemptOrder CHECK (`attemptOrder` >= 1),
    CONSTRAINT fk_dO_quiz FOREIGN KEY (`quizId`)
        REFERENCES `quiz`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_dO_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE
);

-- 8) `join`
-- Note: `join` is SQL keyword — table name is escaped with backticks
CREATE TABLE `join` (
    `courseId` INT NOT NULL,
    `studentId` INT NOT NULL,
    `dateComplete` DATE,
    `dateStart` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `progress` INT NOT NULL DEFAULT 0,
    `GPA` DOUBLE,
    CONSTRAINT pk_join PRIMARY KEY (`courseId`,`studentId`),
    CONSTRAINT chk_join_progress CHECK (`progress` BETWEEN 0 AND 100),
    CONSTRAINT chk_join_dateComplete CHECK (`dateComplete` IS NULL OR `dateComplete` >= `dateStart`),
    CONSTRAINT fk_join_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_join_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE
);

-- 9) interact
CREATE TABLE `interact` (
    `lectureId` INT NOT NULL,
    `studentId` INT NOT NULL,
    PRIMARY KEY (`lectureId`,`studentId`),
    CONSTRAINT fk_interact_lecture FOREIGN KEY (`lectureId`)
        REFERENCES `lecture`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_interact_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE
);

-- 10) certification
CREATE TABLE `certification` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `issueDate` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `expDate` DATE,
    `courseId` INT NOT NULL,
    `studentId` INT NOT NULL,
    CONSTRAINT chk_certification_dates CHECK (`expDate` IS NULL OR `expDate` > `issueDate`),
    CONSTRAINT fk_cert_cert_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_cert_cert_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE
);

-- 11) roadMap
CREATE TABLE `roadMap` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `instruction` TEXT NOT NULL,
    `description` TEXT,
    `name` VARCHAR(255) NOT NULL,
    `teacherId` INT NOT NULL,
    CONSTRAINT fk_roadMap_teacher FOREIGN KEY (`teacherId`)
        REFERENCES `teacher`(`userId`) ON DELETE CASCADE
);

-- 12) viewRoadMap
CREATE TABLE `viewRoadMap` (
    `rmId` INT NOT NULL,
    `studentId` INT NOT NULL,
    `suitability` INT NOT NULL DEFAULT 0,
    `timeSuitability` INT NOT NULL DEFAULT 0,
    `courseSui` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`rmId`,`studentId`),
    CONSTRAINT chk_viewRoadMap_scores CHECK (`suitability` BETWEEN 0 AND 10 AND `timeSuitability` BETWEEN 0 AND 10 AND `courseSui` BETWEEN 0 AND 10),
    CONSTRAINT fk_viewRoadMap_rm FOREIGN KEY (`rmId`)
        REFERENCES `roadMap`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_viewRoadMap_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE
);

-- 13) requireCourse (prerequisite)
CREATE TABLE `requireCourse` (
    `courseId` INT NOT NULL,
    `rCourseId` INT NOT NULL,
    PRIMARY KEY (`courseId`,`rCourseId`),
    CONSTRAINT fk_requireCourse_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_requireCourse_rCourse FOREIGN KEY (`rCourseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE,
    CONSTRAINT chk_requireCourse_no_self CHECK (`courseId` <> `rCourseId`)
);

-- 14) includeCourse
CREATE TABLE `includeCourse` (
    `rmId` INT NOT NULL,
    `courseId` INT NOT NULL,
    `order` INT NOT NULL,
    PRIMARY KEY (`rmId`,`courseId`),
    CONSTRAINT chk_includeCourse_order CHECK (`order` >= 1),
    CONSTRAINT fk_includeCourse_rm FOREIGN KEY (`rmId`)
        REFERENCES `roadMap`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_includeCourse_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE
);

-- 15) roadCertification
CREATE TABLE `roadCertification` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `expDate` DATE,
    `issueDate` DATE NOT NULL DEFAULT (CURRENT_DATE),
    `courseId` INT NOT NULL,
    `studentId` INT NOT NULL,
    CONSTRAINT chk_roadCertification_dates CHECK (`expDate` IS NULL OR `expDate` > `issueDate`),
    CONSTRAINT fk_roadCert_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE,
    CONSTRAINT fk_roadCert_student FOREIGN KEY (`studentId`)
        REFERENCES `student`(`userId`) ON DELETE CASCADE
);

-- 16) teacherQualification
CREATE TABLE `teacherQualification` (
    `teacherId` INT NOT NULL,
    `qualification` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`teacherId`,`qualification`),
    CONSTRAINT fk_teacherQualification_teacher FOREIGN KEY (`teacherId`)
        REFERENCES `teacher`(`userId`) ON DELETE CASCADE
);

-- 17) courseTopic
CREATE TABLE `courseTopic` (
    `courseId` INT NOT NULL,
    `topic` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`courseId`,`topic`),
    CONSTRAINT fk_courseTopic_course FOREIGN KEY (`courseId`)
        REFERENCES `course`(`id`) ON DELETE CASCADE
);

-- ========================
-- DATA INSERTION
-- ========================

-- 1. TABLE `user`
INSERT INTO `user` (`id`, `email`, `firstName`, `lastName`, `username`, `password`, `role`, `bankName`, `bankAccount`) VALUES
(1, 'teacher1@hcmut.edu.vn', 'John', 'Wick', 'teacher1', 'hashedpass1', 'teacher', 'MB Bank', '1234567890'),
(2, 'student1@hcmut.edu.vn', 'Alice', 'Smith', 'student1', 'hashedpass2', 'student', 'Vietcombank', '1234567891'),
(3, 'student2@hcmut.edu.vn', 'Bob', 'Brown', 'student2', 'hashedpass3', 'student', 'Techcombank', '1234567892'),
(4, 'student3@hcmut.edu.vn', 'Charlie', 'Davis', 'student3', 'hashedpass4', 'student', 'Sacombank', '1234567893'),
(5, 'teacher2@hcmut.edu.vn', 'Mary', 'Johnson', 'teacher2', 'hashedpass5', 'teacher', 'ACB', '1234567894'),
(6, 'teacher3@hcmut.edu.vn', 'David', 'Lee', 'teacher3', 'hashedpass6', 'teacher', 'MB Bank', '1234567895'),
(7, 'student4@hcmut.edu.vn', 'Eva', 'Miller', 'student4', 'hashedpass7', 'student', 'Techcombank', '1234567896'),
(8, 'teacher4@hcmut.edu.vn', 'Frank', 'Wilson', 'teacher4', 'hashedpass8', 'teacher', 'Vietcombank', '1234567897'),
(9, 'teacher5@hcmut.edu.vn', 'George', 'King', 'teacher5', 'hashedpass9', 'teacher', 'MB Bank', '1234567898'),
(10, 'student5@hcmut.edu.vn', 'Helen', 'Clark', 'student5', 'hashedpass10', 'student', 'Techcombank', '1234567899');

-- 2. TABLE `teacher`
INSERT INTO `teacher` (`userId`, `teacherId`) VALUES
(1, 'TC00000001'),
(5, 'TC00000005'),
(6, 'TC00000006'),
(8, 'TC00000008'),
(9, 'TC00000009');

-- 3. TABLE `student`
INSERT INTO `student` (`userId`, `studentId`, `enrollmentDate`, `numberCoursesEnrolled`, `numberCoursesCompleted`) VALUES
(2, 'ST00000002', '2024-12-01', 3, 1),
(3, 'ST00000003', '2024-11-15', 2, 2),
(4, 'ST00000004', '2024-10-20', 4, 1),
(7, 'ST00000007', '2024-12-03', 1, 0),
(10, 'ST00000010', '2024-12-05', 2, 0);

-- 4. TABLE `course`
INSERT INTO `course` (`id`, `name`, `language`, `description`, `teacherId`, `creTime`, `avgQuiz`, `price`) VALUES
(1, 'Math 101', 'Vietnamese', 'Basic Math', 1, '2024-12-01', 0, 100),
(2, 'Physics 101', 'Vietnamese', 'Basic Physics', 5, '2024-12-01', 0, 120),
(3, 'Chemistry 101', 'Vietnamese', 'Basic Chemistry', 6, '2024-12-01', 0, 110),
(4, 'Biology 101', 'Vietnamese', 'Basic Biology', 8, '2024-12-01', 0, 90),
(5, 'English 101', 'English', 'Basic English', 9, '2024-12-01', 0, 80);

-- 5. TABLE `section`
INSERT INTO `section` (`id`, `name`, `numOfLecture`, `timeTocomplete`, `teacherId`, `courseId`, `creTime`) VALUES
(1, 'Section A', 3, 12, 1, 1, '2024-12-01'),
(2, 'Section B', 2, 10, 5, 2, '2024-12-01'),
(3, 'Section C', 4, 15, 6, 3, '2024-12-01'),
(4, 'Section D', 3, 12, 8, 4, '2024-12-01'),
(5, 'Section E', 5, 20, 9, 5, '2024-12-01');

-- 6. TABLE `lecture`
INSERT INTO `lecture` (`id`, `name`, `state`, `material`, `reference`, `sectionId`) VALUES
(1, 'Lecture 1', 'uncomplete', 'video1.mp4', 'book1.pdf', 1),
(2, 'Lecture 2', 'uncomplete', 'video2.mp4', 'book2.pdf', 2),
(3, 'Lecture 3', 'uncomplete', 'video3.mp4', 'book3.pdf', 3),
(4, 'Lecture 4', 'uncomplete', 'video4.mp4', 'book4.pdf', 4),
(5, 'Lecture 5', 'uncomplete', 'video5.mp4', 'book5.pdf', 5);

-- 7. TABLE `quiz`
INSERT INTO `quiz` (`id`, `name`, `state`, `attempt`, `duration`, `teacherId`, `sectionId`, `creTime`) VALUES
(1, 'Quiz 1', 'opened', 1, 10, 1, 1, '2024-12-01'),
(2, 'Quiz 2', 'opened', 1, 15, 5, 2, '2024-12-01'),
(3, 'Quiz 3', 'opened', 1, 20, 6, 3, '2024-12-01'),
(4, 'Quiz 4', 'opened', 1, 10, 8, 4, '2024-12-01'),
(5, 'Quiz 5', 'opened', 1, 15, 9, 5, '2024-12-01');

-- 8. TABLE `question`
INSERT INTO `question` (`id`, `quizId`, `type`, `answer`, `content`, `creTime`, `teacherId`) VALUES
(1, 1, 'multiple choice', 'Option A', 'Question 1', '2024-12-01', 1),
(2, 2, 'multiple choice', 'Option B', 'Question 2', '2024-12-01', 5),
(3, 3, 'multiple choice', 'Option C', 'Question 3', '2024-12-01', 6),
(4, 4, 'multiple choice', 'Option D', 'Question 4', '2024-12-01', 8),
(5, 5, 'multiple choice', 'Option E', 'Question 5', '2024-12-01', 9);

-- 9. TABLE `option`
INSERT INTO `option` (`questionId`, `option`) VALUES
(1, 'Option A'), (1, 'Option B'), (1, 'Option C'), (1, 'Option D'),
(2, 'Option A'), (2, 'Option B'), (2, 'Option C'), (2, 'Option D'),
(3, 'Option A'), (3, 'Option B'), (3, 'Option C'), (3, 'Option D'),
(4, 'Option A'), (4, 'Option B'), (4, 'Option C'), (4, 'Option D'),
(5, 'Option A'), (5, 'Option B'), (5, 'Option C'), (5, 'Option D');

-- 10. TABLE `roadMap`
INSERT INTO `roadMap` (`id`, `instruction`, `description`, `name`, `teacherId`) VALUES
(1, 'Instruction 1', 'Description 1', 'Roadmap 1', 1),
(2, 'Instruction 2', 'Description 2', 'Roadmap 2', 5),
(3, 'Instruction 3', 'Description 3', 'Roadmap 3', 6),
(4, 'Instruction 4', 'Description 4', 'Roadmap 4', 8),
(5, 'Instruction 5', 'Description 5', 'Roadmap 5', 9);

-- 11. TABLE `includeCourse`
INSERT INTO `includeCourse` (`rmId`, `courseId`, `order`) VALUES
(1, 1, 1),
(1, 2, 2),
(2, 3, 1),
(3, 4, 1),
(4, 5, 1);

-- 12. TABLE `teacherQualification`
INSERT INTO `teacherQualification` (`teacherId`, `qualification`) VALUES
(1, 'PhD Math'),
(5, 'PhD Physics'),
(6, 'PhD Chemistry'),
(8, 'MSc Biology'),
(9, 'MSc English');

-- 13. TABLE `courseTopic`
INSERT INTO `courseTopic` (`courseId`, `topic`) VALUES
(1, 'Algebra'),
(2, 'Mechanics'),
(3, 'Organic Chemistry'),
(4, 'Botany'),
(5, 'Grammar');

-- 14. TABLE `dO`
INSERT INTO `dO` (`quizId`, `studentId`, `score`) VALUES
(1, 2, 8),
(2, 3, 7),
(3, 4, 9),
(4, 7, 6),
(5, 10, 8);

-- 15. TABLE `answerRecord`
INSERT INTO `answerRecord` (`quizId`, `studentId`, `questionId`, `studentAns`) VALUES
(1, 2, 1, 'Option A'),
(2, 3, 2, 'Option B'),
(3, 4, 3, 'Option C'),
(4, 7, 4, 'Option D'),
(5, 10, 5, 'Option E');

-- 16. TABLE `join`
INSERT INTO `join` (`courseId`, `studentId`, `progress`, `GPA`) VALUES
(1, 2, 50, 3.5),
(2, 3, 40, 2.8),
(3, 4, 60, 3.2),
(4, 7, 70, 3.9),
(5, 10, 80, 4.0);

-- 17. TABLE `viewRoadMap`
INSERT INTO `viewRoadMap` (`rmId`, `studentId`, `suitability`, `timeSuitability`, `courseSui`) VALUES
(1, 2, 8, 7, 9),
(2, 3, 7, 6, 8),
(3, 4, 9, 8, 7),
(4, 7, 6, 7, 6),
(5, 10, 8, 9, 8);

-- 18. TABLE `requireCourse`
INSERT INTO `requireCourse` (`courseId`, `rCourseId`) VALUES
(2, 1),
(3, 1),
(4, 2),
(5, 3),
(5, 4);

-- 19. TABLE `roadCertification`
INSERT INTO `roadCertification` (`name`, `issueDate`, `expDate`, `courseId`, `studentId`) VALUES
('Cert 1', '2024-12-01', '2025-12-01', 1, 2),
('Cert 2', '2024-12-01', '2025-12-01', 2, 3),
('Cert 3', '2024-12-01', '2025-12-01', 3, 4),
('Cert 4', '2024-12-01', '2025-12-01', 4, 7),
('Cert 5', '2024-12-01', '2025-12-01', 5, 10);

-- 20. TABLE `interact`
INSERT INTO `interact` (`lectureId`, `studentId`) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 7),
(5, 10);

-- 21. TABLE `certification`
INSERT INTO `certification` (`name`, `issueDate`, `expDate`, `courseId`, `studentId`) VALUES
('Cert A', '2024-12-01', '2025-12-01', 1, 2),
('Cert B', '2024-12-01', '2025-12-01', 2, 3),
('Cert C', '2024-12-01', '2025-12-01', 3, 4),
('Cert D', '2024-12-01', '2025-12-01', 4, 7),
('Cert E', '2024-12-01', '2025-12-01', 5, 10); -- Dòng đã sửa lỗi
