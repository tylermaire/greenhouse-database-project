-- ***************************
-- 1) Disable Triggers to Allow Manual Surrogate Key Insertion
-- ***************************
ALTER TRIGGER TRG_SPACE_BI DISABLE;
ALTER TRIGGER TRG_STAFF_BI DISABLE;
ALTER TRIGGER TRG_EXPERIMENT_BI DISABLE;

-- [existing inserts remain unchanged]

-- ***************************
-- 10) Basic Queries
-- ***************************
-- Query 1: Select all columns and all rows from one table
SELECT * FROM STAFF;

-- Query 2: Select five columns and all rows from one table
SELECT STAFF_ID, FIRST_NAME, LAST_NAME, ROLE, EMAIL FROM STAFF;

-- Query 3: Select all columns from all rows from one view
SELECT * FROM PLANT_INFO;

-- Query 4: Join on 2 tables without Cartesian product
SELECT *
FROM STAFF s
JOIN ASSIGNMENT a ON s.STAFF_ID = a.STAFF_ID;

-- Query 5: Select and order data from one table
SELECT * FROM INVENTORY ORDER BY COST_PER_UNIT DESC;

-- Query 6: Join on 3 tables with 5 columns, limit output
SELECT s.FIRST_NAME, e.TITLE, a.TASK_DESC, a.STATUS, a.DUE_DATE
FROM STAFF s
JOIN ASSIGNMENT a ON s.STAFF_ID = a.STAFF_ID
JOIN EXPERIMENT e ON e.EXPERIMENT_ID = a.EXPERIMENT_ID
WHERE ROWNUM <= 10;

-- Query 7: Select distinct rows using joins on 3 tables
SELECT DISTINCT s.ROLE
FROM STAFF s
JOIN ASSIGNMENT a ON s.STAFF_ID = a.STAFF_ID
JOIN EXPERIMENT e ON e.EXPERIMENT_ID = a.EXPERIMENT_ID;

-- Query 8: Use GROUP BY and HAVING
SELECT STATUS, COUNT(*) AS TASK_COUNT
FROM ASSIGNMENT
GROUP BY STATUS
HAVING COUNT(*) > 2;

-- Query 9: Use IN clause
SELECT * FROM STAFF WHERE ROLE IN ('Botanist', 'Intern');

-- Query 10: Select length of one column
SELECT LENGTH(ITEM_NAME) AS NAME_LENGTH FROM INVENTORY;

-- Query 11: DELETE with before/after SELECT + ROLLBACK
-- To avoid foreign key constraint violation, we delete from ASSIGNMENT first, then STAFF
SELECT * FROM STAFF WHERE STAFF_ID = 10;
SELECT * FROM ASSIGNMENT WHERE STAFF_ID = 10;
DELETE FROM ASSIGNMENT WHERE STAFF_ID = 10;
DELETE FROM STAFF WHERE STAFF_ID = 10;
SELECT * FROM STAFF;
ROLLBACK;

-- Query 12: UPDATE with before/after SELECT + ROLLBACK
SELECT * FROM INVENTORY WHERE ITEM_NAME = 'pH meter';
UPDATE INVENTORY SET COST_PER_UNIT = 49.99 WHERE ITEM_NAME = 'pH meter';
SELECT * FROM INVENTORY WHERE ITEM_NAME = 'pH meter';
ROLLBACK;

-- ***************************
-- 11) Advanced Queries
-- ***************************
-- Query 13: Subquery to get most expensive inventory item per experiment
SELECT * FROM INVENTORY i
WHERE COST_PER_UNIT = (
  SELECT MAX(COST_PER_UNIT)
  FROM INVENTORY
  WHERE EXPERIMENT_ID = i.EXPERIMENT_ID
);

-- Query 14: Join + aggregate + GROUP BY
SELECT e.TITLE, COUNT(p.PLANT_ID) AS PLANT_COUNT
FROM EXPERIMENT e
JOIN PLANT p ON e.EXPERIMENT_ID = p.EXPERIMENT_ID
GROUP BY e.TITLE;

-- Query 15: Nested subquery with EXISTS
SELECT * FROM STAFF s
WHERE EXISTS (
  SELECT 1 FROM ASSIGNMENT a WHERE a.STAFF_ID = s.STAFF_ID AND a.STATUS = 'Assigned'
);

-- Query 16: 3-table join with WHERE and ORDER
SELECT s.FIRST_NAME, a.TASK_DESC, e.TITLE
FROM STAFF s
JOIN ASSIGNMENT a ON s.STAFF_ID = a.STAFF_ID
JOIN EXPERIMENT e ON e.EXPERIMENT_ID = a.EXPERIMENT_ID
WHERE a.STATUS = 'Completed'
ORDER BY s.FIRST_NAME;

-- Query 17: Use a view with filter and sort
SELECT * FROM PLANT_INFO WHERE HEALTH_STATUS = 'Healthy' ORDER BY SPECIES;

-- Query 18: COUNT with CASE statement
SELECT STATUS,
  COUNT(CASE WHEN STATUS = 'Assigned' THEN 1 END) AS ASSIGNED_COUNT,
  COUNT(CASE WHEN STATUS = 'Completed' THEN 1 END) AS COMPLETED_COUNT
FROM ASSIGNMENT
GROUP BY STATUS;

-- Query 19: Join + aggregate + HAVING on PLANT
SELECT sp.SPACE_TYPE, COUNT(p.PLANT_ID) AS NUM_PLANTS
FROM SPACE sp
JOIN PLANT p ON sp.SPACE_ID = p.SPACE_ID
GROUP BY sp.SPACE_TYPE
HAVING COUNT(p.PLANT_ID) >= 2;

-- Query 20: Correlated subquery
SELECT * FROM PLANT p1
WHERE PLANTED_DATE = (
  SELECT MIN(p2.PLANTED_DATE)
  FROM PLANT p2
  WHERE p2.SPACE_ID = p1.SPACE_ID
);
