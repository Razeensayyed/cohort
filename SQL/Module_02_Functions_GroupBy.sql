-- ============================================================
-- MODULE 2: Single-Row Functions, Conversion, Group Functions
-- Atlas Skilltech University | MySQL
-- ============================================================
-- Run karein: MySQL Workbench mein Ctrl+Shift+Enter
-- Ek query run karein: cursor uss query par rakho, Ctrl+Enter
-- ============================================================

USE atlas_sql;

-- ============================================================
-- SECTION 1: STRING FUNCTIONS
-- ============================================================

-- Basic string functions
SELECT
    first_name,
    UPPER(first_name)                           AS "UPPER",
    LOWER(last_name)                            AS "lower",
    LENGTH(first_name)                          AS "Length",
    CONCAT(first_name, ' ', last_name)          AS "Full Name",
    CONCAT(first_name, ' (', department, ')')   AS "Name & Dept"
FROM employees;

-- SUBSTR: Part of string nikalna (start, length)
SELECT
    first_name,
    SUBSTR(first_name, 1, 3)   AS "First 3 Chars",
    SUBSTR(first_name, 2)      AS "From 2nd Char",
    SUBSTR(last_name, -3)      AS "Last 3 Chars"
FROM employees;

-- TRIM, LPAD, RPAD
SELECT
    TRIM('   Rahul   ')                         AS "Trimmed",
    LPAD(CAST(employee_id AS CHAR), 4, '0')     AS "ID Padded (0001)",
    RPAD(department, 10, '.')                   AS "Dept Padded"
FROM employees;

-- REPLACE, INSTR
SELECT
    job_title,
    REPLACE(job_title, 'Manager', 'Lead')       AS "Replaced",
    INSTR(job_title, 'Manager')                 AS "Manager Position"
FROM employees;

-- String functions in WHERE
SELECT * FROM employees WHERE UPPER(first_name) = 'RAHUL';
SELECT * FROM employees WHERE LOWER(department) = 'it';
SELECT * FROM employees WHERE LENGTH(first_name) > 5;
SELECT * FROM employees WHERE SUBSTR(first_name, 1, 1) = 'R';
SELECT * FROM employees WHERE INSTR(job_title, 'Manager') > 0;


-- ============================================================
-- SECTION 2: NUMBER FUNCTIONS
-- ============================================================

-- ROUND: d decimal places tak round karo
SELECT
    salary,
    ROUND(salary, -3)              AS "Round to 1000s",    -- 65000 -> 65000
    ROUND(45678.567, 2)            AS "ROUND 2dp",         -- 45678.57
    ROUND(45678.567, 0)            AS "ROUND Integer",     -- 45679
    ROUND(45678.567, -2)           AS "ROUND 100s"         -- 45700
FROM employees;

-- TRUNCATE: Round nahi karta, bas cut karta hai
SELECT
    salary,
    TRUNCATE(salary, -3)           AS "TRUNC to 1000s",    -- 65000 -> 65000
    TRUNCATE(45678.999, 2)         AS "TRUNC 2dp"          -- 45678.99 (not .00)
FROM employees;

-- MOD: Remainder
SELECT
    employee_id,
    first_name,
    MOD(employee_id, 2)            AS "Even/Odd (0=Even)",
    MOD(salary, 1000)              AS "Salary Remainder"
FROM employees;

-- Other number functions
SELECT
    salary,
    ABS(salary - 65000)            AS "Diff from 65k",
    CEIL(salary / 1000)            AS "Ceiling (Thousands)",
    FLOOR(salary / 1000)           AS "Floor (Thousands)",
    SQRT(salary)                   AS "SQRT"
FROM employees LIMIT 5;


-- ============================================================
-- SECTION 3: DATE ARITHMETIC & DATE FUNCTIONS
-- ============================================================

-- Date arithmetic with INTERVAL
SELECT
    CURDATE()                               AS "Today",
    CURDATE() + INTERVAL 7 DAY              AS "+7 Days",
    CURDATE() - INTERVAL 1 MONTH           AS "-1 Month",
    CURDATE() + INTERVAL 1 YEAR            AS "+1 Year",
    DATEDIFF('2026-12-31', CURDATE())       AS "Days to Year End";

-- Date functions on employees
SELECT
    first_name,
    hire_date,
    YEAR(hire_date)                               AS "Year",
    MONTH(hire_date)                              AS "Month #",
    MONTHNAME(hire_date)                          AS "Month Name",
    DAYNAME(hire_date)                            AS "Day Name",
    LAST_DAY(hire_date)                           AS "Month Last Day",
    DATEDIFF(CURDATE(), hire_date)                AS "Days Employed",
    TIMESTAMPDIFF(MONTH, hire_date, CURDATE())    AS "Months Employed",
    TIMESTAMPDIFF(YEAR,  hire_date, CURDATE())    AS "Years Employed",
    DATE_ADD(hire_date, INTERVAL 6 MONTH)         AS "Probation End",
    DATE_ADD(hire_date, INTERVAL 1 YEAR)          AS "1st Anniversary"
FROM employees;

-- Current date/time
SELECT CURDATE() AS "Date", CURTIME() AS "Time", NOW() AS "DateTime";

-- Week and Quarter
SELECT
    first_name, hire_date,
    WEEK(hire_date)       AS "Week of Year",
    QUARTER(hire_date)    AS "Quarter"
FROM employees;


-- ============================================================
-- SECTION 4: NESTED FUNCTIONS
-- ============================================================

SELECT
    first_name,
    UPPER(CONCAT(first_name, ' ', last_name))          AS "Full Name UPPER",
    SUBSTR(UPPER(department), 1, 3)                    AS "Dept Code",
    ROUND(DATEDIFF(CURDATE(), hire_date) / 365.25, 1)  AS "Years (Precise)"
FROM employees;


-- ============================================================
-- SECTION 5: DATE_FORMAT (Oracle: TO_CHAR for dates)
-- ============================================================

SELECT
    first_name,
    hire_date,
    DATE_FORMAT(hire_date, '%d-%m-%Y')           AS "DD-MM-YYYY",
    DATE_FORMAT(hire_date, '%M %d, %Y')          AS "Month DD, YYYY",
    DATE_FORMAT(hire_date, '%W, %d %M %Y')       AS "Full Date"
FROM employees;

SELECT DATE_FORMAT(CURDATE(), '%W, %d %M %Y') AS "Today Formatted";


-- ============================================================
-- SECTION 6: STR_TO_DATE (Oracle: TO_DATE)
-- ============================================================

SELECT STR_TO_DATE('15-03-2022', '%d-%m-%Y')     AS "Date from String";
SELECT STR_TO_DATE('March 15, 2022', '%M %d, %Y') AS "Date from Long String";

-- WHERE mein use
SELECT * FROM employees
WHERE hire_date > STR_TO_DATE('01-01-2022', '%d-%m-%Y');


-- ============================================================
-- SECTION 7: CAST aur FORMAT
-- ============================================================

SELECT CAST('12345' AS DECIMAL(10,2))    AS "String to Number";
SELECT CAST(65000.50 AS SIGNED)          AS "Decimal to Int";

SELECT
    first_name,
    salary,
    FORMAT(salary, 0)                    AS "Formatted (65,000)",
    CONCAT('Rs. ', FORMAT(salary, 0))    AS "With Currency"
FROM employees;


-- ============================================================
-- SECTION 8: IFNULL / NULLIF / COALESCE (Oracle: NVL / NULLIF / COALESCE)
-- ============================================================

-- IFNULL (Oracle: NVL)
SELECT
    first_name,
    commission,
    IFNULL(commission, 0)                       AS "Comm (No Null)",
    salary + IFNULL(commission, 0)              AS "Total Package",
    IFNULL(CAST(commission AS CHAR), 'N/A')     AS "Comm Display",
    IFNULL(CAST(manager_id AS CHAR), 'Top Level') AS "Reports To"
FROM employees;

-- NULLIF
SELECT NULLIF(100, 100)   AS "Equal (NULL)",
       NULLIF(100, 200)   AS "Not Equal (100)";

-- Division by zero avoid
SELECT first_name, salary / NULLIF(commission, 0) AS "Ratio" FROM employees;

-- COALESCE
SELECT COALESCE(NULL, NULL, 'Teen', 'Chaar') AS "First Non-Null";

SELECT
    first_name,
    COALESCE(commission, 0)                      AS "Commission",
    COALESCE(CAST(manager_id AS CHAR), 'None')   AS "Manager"
FROM employees;

-- NVL2 equivalent (IF in MySQL)
SELECT
    first_name,
    IF(commission IS NOT NULL,
       CONCAT('Rs. ', FORMAT(commission, 0)),
       'No Commission')
    AS "Commission Status"
FROM employees;


-- ============================================================
-- SECTION 9: CASE EXPRESSION
-- ============================================================

-- Searched CASE
SELECT first_name, salary,
    CASE
        WHEN salary >= 80000 THEN 'Senior'
        WHEN salary >= 60000 THEN 'Mid-Level'
        WHEN salary >= 45000 THEN 'Junior'
        ELSE 'Entry Level'
    END AS "Grade"
FROM employees;

-- Simple CASE
SELECT first_name, department,
    CASE department
        WHEN 'IT'      THEN 'Technical'
        WHEN 'Sales'   THEN 'Revenue'
        WHEN 'HR'      THEN 'People'
        WHEN 'Finance' THEN 'Finance'
    END AS "Team Type"
FROM employees;

-- CASE with NULL handling
SELECT first_name,
    CASE
        WHEN commission IS NULL     THEN 'Fixed Salary'
        WHEN commission >= 7000     THEN 'High Commission'
        WHEN commission >= 4000     THEN 'Medium Commission'
        ELSE 'Low Commission'
    END AS "Pay Structure"
FROM employees;

-- CASE in ORDER BY (custom sort)
SELECT first_name, department
FROM employees
ORDER BY
    CASE department
        WHEN 'IT'      THEN 1
        WHEN 'Finance' THEN 2
        WHEN 'HR'      THEN 3
        WHEN 'Sales'   THEN 4
    END, first_name;

-- CASE in arithmetic (department-wise hike)
SELECT first_name, salary,
    salary * CASE department
        WHEN 'Sales' THEN 1.15
        WHEN 'IT'    THEN 1.10
        ELSE 1.05
    END AS "Revised Salary"
FROM employees;


-- ============================================================
-- SECTION 10: AGGREGATE FUNCTIONS
-- ============================================================

-- Basic aggregates
SELECT
    COUNT(*)                    AS "Total Rows",
    COUNT(commission)           AS "With Commission",
    COUNT(DISTINCT department)  AS "Departments",
    SUM(salary)                 AS "Total Payroll",
    AVG(salary)                 AS "Avg Salary",
    MIN(salary)                 AS "Min Salary",
    MAX(salary)                 AS "Max Salary",
    MAX(salary) - MIN(salary)   AS "Salary Range"
FROM employees;

-- AVG with NULL comparison
SELECT
    AVG(commission)              AS "Avg (NULL skip — divides by 3)",
    AVG(IFNULL(commission, 0))   AS "Avg (NULL=0 — divides by 10)",
    SUM(commission)              AS "Sum Commission"
FROM employees;

-- MIN/MAX on dates
SELECT
    MIN(hire_date)   AS "Earliest Hire",
    MAX(hire_date)   AS "Latest Hire"
FROM employees;


-- ============================================================
-- SECTION 11: GROUP BY
-- ============================================================

-- Department-wise count
SELECT department, COUNT(*) AS "Employees"
FROM employees
GROUP BY department;

-- Department-wise salary stats
SELECT
    department,
    COUNT(*)             AS "Count",
    SUM(salary)          AS "Total Salary",
    ROUND(AVG(salary),0) AS "Avg Salary",
    MIN(salary)          AS "Min Salary",
    MAX(salary)          AS "Max Salary"
FROM employees
GROUP BY department
ORDER BY AVG(salary) DESC;

-- Multiple columns GROUP BY
SELECT department, job_title, COUNT(*) AS "Count"
FROM employees
GROUP BY department, job_title
ORDER BY department, job_title;

-- GROUP BY with expression
SELECT YEAR(hire_date) AS "Hire Year", COUNT(*) AS "Hired"
FROM employees
GROUP BY YEAR(hire_date)
ORDER BY YEAR(hire_date);


-- ============================================================
-- SECTION 12: HAVING
-- ============================================================

-- Departments with more than 1 employee
SELECT department, COUNT(*) AS "Count"
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Departments with avg salary > 60000
SELECT department, ROUND(AVG(salary),0) AS "Avg"
FROM employees
GROUP BY department
HAVING AVG(salary) > 60000
ORDER BY AVG(salary) DESC;

-- WHERE + GROUP BY + HAVING combined
SELECT
    department,
    COUNT(*)             AS "Count",
    ROUND(AVG(salary),0) AS "Avg Salary"
FROM employees
WHERE hire_date >= '2020-01-01'       -- rows filter pehle
GROUP BY department
HAVING COUNT(*) >= 2                   -- groups filter baad mein
ORDER BY AVG(salary) DESC;

-- Aggregate with CASE: department-wise senior/junior count
SELECT
    department,
    COUNT(*) AS "Total",
    SUM(CASE WHEN salary >= 70000 THEN 1 ELSE 0 END) AS "Senior (70k+)",
    SUM(CASE WHEN salary < 70000  THEN 1 ELSE 0 END) AS "Junior (<70k)"
FROM employees
GROUP BY department;

-- Salary band distribution
SELECT
    CASE
        WHEN salary >= 80000 THEN 'Senior'
        WHEN salary >= 60000 THEN 'Mid-Level'
        WHEN salary >= 45000 THEN 'Junior'
        ELSE 'Entry Level'
    END AS "Grade",
    COUNT(*) AS "Count",
    ROUND(AVG(salary),0) AS "Avg Salary"
FROM employees
GROUP BY
    CASE
        WHEN salary >= 80000 THEN 'Senior'
        WHEN salary >= 60000 THEN 'Mid-Level'
        WHEN salary >= 45000 THEN 'Junior'
        ELSE 'Entry Level'
    END
ORDER BY AVG(salary) DESC;
