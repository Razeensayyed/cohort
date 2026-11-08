-- ============================================================
-- MODULE 1: Introduction to Databases & SQL SELECT
-- Atlas Skilltech University | MySQL
-- ============================================================
-- Run karein: MySQL Workbench mein Ctrl+Shift+Enter
-- Ek query run karein: cursor uss query par rakho, Ctrl+Enter
-- ============================================================


-- ============================================================
-- SECTION 1: Setup — Database aur Table banana
-- ============================================================

-- Database banao (pehli baar hi)
CREATE DATABASE IF NOT EXISTS atlas_sql;

-- Database select karo (ALWAYS do this first!)
USE atlas_sql;

-- Course ke liye sample EMPLOYEES table
CREATE TABLE IF NOT EXISTS employees (
    employee_id   INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50)    NOT NULL,
    last_name     VARCHAR(50)    NOT NULL,
    department    VARCHAR(50),
    job_title     VARCHAR(100),
    salary        DECIMAL(10,2),
    hire_date     DATE,
    manager_id    INT,
    commission    DECIMAL(5,2)   -- NULL for many employees
);

-- Sample data insert karo
INSERT INTO employees (first_name, last_name, department, job_title, salary, hire_date, manager_id, commission) VALUES
('Rahul',    'Sharma',   'IT',        'Software Engineer',  65000.00,  '2022-03-15', NULL,  NULL),
('Priya',    'Patel',    'IT',        'Senior Developer',   85000.00,  '2020-06-01', 1,     NULL),
('Amit',     'Singh',    'HR',        'HR Manager',         70000.00,  '2019-01-10', NULL,  NULL),
('Neha',     'Gupta',    'Sales',     'Sales Executive',    45000.00,  '2023-07-20', NULL,  5000.00),
('Vikram',   'Joshi',    'Sales',     'Sales Manager',      75000.00,  '2018-11-05', NULL,  8000.00),
('Pooja',    'Desai',    'IT',        'QA Engineer',        55000.00,  '2021-09-12', 1,     NULL),
('Suresh',   'Kumar',    'Finance',   'Accountant',         60000.00,  '2020-04-25', NULL,  NULL),
('Ananya',   'Verma',    'HR',        'Recruiter',          42000.00,  '2023-02-14', 3,     NULL),
('Ravi',     'Nair',     'Sales',     'Sales Executive',    48000.00,  '2022-08-30', 5,     4500.00),
('Kavya',    'Reddy',    'Finance',   'Finance Manager',    80000.00,  '2017-05-20', NULL,  NULL);

-- Verify: table structure dekho
DESCRIBE employees;

-- Verify: data dekho
SELECT * FROM employees;


-- ============================================================
-- SECTION 2: DESCRIBE Command
-- ============================================================

-- Table ki structure dikhao
DESCRIBE employees;

-- Short form bhi kaam karta hai
DESC employees;

-- Sab tables list karo
SHOW TABLES;

-- Current database kaunsa hai
SELECT DATABASE();


-- ============================================================
-- SECTION 3: SELECT * — Saare Columns
-- ============================================================

-- Poori table dekho
SELECT * FROM employees;

-- Kitni rows hain?
SELECT COUNT(*) AS total_employees FROM employees;


-- ============================================================
-- SECTION 4: Specific Columns Select karna
-- ============================================================

-- Sirf naam chahiye
SELECT first_name, last_name FROM employees;

-- Department aur job title
SELECT department, job_title FROM employees;

-- Note: order vahi hoga jo SELECT mein likha hai
-- Neeche: salary pehle, phir naam
SELECT salary, first_name, last_name FROM employees;


-- ============================================================
-- SECTION 5: Column Aliases (AS keyword)
-- ============================================================

-- Column headings readable banao
SELECT
    first_name   AS "First Name",
    last_name    AS "Last Name",
    department   AS Dept,
    salary       AS "Monthly Salary"
FROM employees;

-- Alias without quotes (space nahi hona chahiye)
SELECT
    first_name  AS FirstName,
    last_name   AS LastName,
    salary      AS MonthlySalary
FROM employees;

-- Table alias bhi ho sakta hai (future modules mein kaam aayega)
SELECT e.first_name, e.salary
FROM employees e;      -- 'e' = employees table ka alias


-- ============================================================
-- SECTION 6: Arithmetic Operators
-- ============================================================

-- Basic arithmetic
SELECT
    first_name,
    salary,
    salary + 5000           AS "Salary + Increment",
    salary * 1.10           AS "10% Hike",
    salary * 12             AS "Annual Salary",
    salary * 12 * 0.10      AS "Annual Tax (10%)",
    salary / 1000           AS "Salary in Thousands"
FROM employees;

-- Commission add karna (NULL wale employees ke liye!)
SELECT
    first_name,
    salary,
    commission,
    salary + commission     AS "Salary + Commission"
    -- Jahan commission = NULL, result = NULL
FROM employees;

-- Fix: IFNULL se NULL ko 0 se replace karo
SELECT
    first_name,
    salary,
    commission,
    salary + IFNULL(commission, 0)  AS "Total Package"
FROM employees;

-- Operator precedence example
SELECT
    2 + 3 * 4           AS "Without Brackets",    -- 14
    (2 + 3) * 4         AS "With Brackets",        -- 20
    salary + 1000 * 2   AS "Precedence Test",      -- salary + 2000
    (salary + 1000) * 2 AS "Brackets Change It"    -- (salary+1000)*2
FROM employees
LIMIT 3;    -- Sirf 3 rows dikhao (testing ke liye)


-- ============================================================
-- SECTION 7: DISTINCT — Unique Values
-- ============================================================

-- Duplicate departments (without DISTINCT)
SELECT department FROM employees;

-- Unique departments only
SELECT DISTINCT department FROM employees;

-- Multiple columns: unique combination
SELECT DISTINCT department, job_title FROM employees;


-- ============================================================
-- SECTION 8: Expressions aur Functions in SELECT
-- ============================================================

-- String functions
SELECT
    first_name,
    UPPER(first_name)                           AS "UPPER NAME",
    LOWER(last_name)                            AS "lower name",
    LENGTH(first_name)                          AS "Name Length",
    CONCAT(first_name, ' ', last_name)          AS "Full Name",
    CONCAT(first_name, ' (', department, ')')   AS "Name & Dept"
FROM employees;

-- Number functions
SELECT
    first_name,
    salary,
    ROUND(salary, -3)       AS "Rounded to 1000s",
    FLOOR(salary / 1000)    AS "Thousands (Floor)",
    MOD(salary, 1000)       AS "Remainder",
    ABS(-salary)            AS "Absolute Value"
FROM employees;

-- Date functions
SELECT
    first_name,
    hire_date,
    YEAR(hire_date)                     AS "Hire Year",
    MONTH(hire_date)                    AS "Hire Month",
    CURDATE()                           AS "Today",
    DATEDIFF(CURDATE(), hire_date)      AS "Days Employed",
    DATEDIFF(CURDATE(), hire_date)/365  AS "Years Employed (approx)"
FROM employees;


-- ============================================================
-- SECTION 9: CASE Expression — Conditional Output
-- ============================================================

SELECT
    first_name,
    salary,
    CASE
        WHEN salary >= 80000 THEN 'Senior'
        WHEN salary >= 60000 THEN 'Mid-Level'
        WHEN salary >= 45000 THEN 'Junior'
        ELSE 'Entry Level'
    END AS "Experience Level"
FROM employees;

-- Department wise category
SELECT
    first_name,
    department,
    CASE department
        WHEN 'IT'      THEN 'Technical Team'
        WHEN 'Sales'   THEN 'Revenue Team'
        WHEN 'HR'      THEN 'People Team'
        WHEN 'Finance' THEN 'Money Team'
        ELSE 'Other'
    END AS "Team"
FROM employees;


-- ============================================================
-- SECTION 10: SQL Comments
-- ============================================================

-- Yeh single line comment hai
# Yeh bhi single line comment hai (MySQL specific)

/*
Yeh multi-line comment hai
Kai lines likh sakte ho
*/

SELECT first_name, -- Pehla naam
       salary      -- Monthly CTC
FROM   employees;  -- Table ka naam


-- ============================================================
-- PRACTICE EXERCISES
-- ============================================================

-- Exercise 1: Saare employees ke full names aur annual salary dikhao
-- (Annual = monthly * 12)
-- Columns: Full Name, Department, Monthly Salary, Annual Salary



-- Exercise 2: Unique departments aur job titles ki list dikhao



-- Exercise 3: Employees ki service dikhao (hire_date se aaj tak)
-- Columns: Full Name, Hire Date, Years of Service



-- Exercise 4: Salary 10% increase ke baad kya hogi? Dikhao
-- Columns: Name, Current Salary, New Salary (after 10% hike)



-- ============================================================
-- EXERCISE ANSWERS
-- ============================================================

-- Answer 1:
SELECT
    CONCAT(first_name, ' ', last_name)  AS "Full Name",
    department                          AS "Department",
    salary                              AS "Monthly Salary",
    salary * 12                         AS "Annual Salary"
FROM employees;

-- Answer 2:
SELECT DISTINCT department, job_title
FROM employees
ORDER BY department, job_title;

-- Answer 3:
SELECT
    CONCAT(first_name, ' ', last_name)              AS "Full Name",
    hire_date                                        AS "Hire Date",
    ROUND(DATEDIFF(CURDATE(), hire_date) / 365, 1)  AS "Years of Service"
FROM employees;

-- Answer 4:
SELECT
    first_name          AS "Name",
    salary              AS "Current Salary",
    ROUND(salary * 1.10, 2) AS "New Salary (10% Hike)"
FROM employees;
