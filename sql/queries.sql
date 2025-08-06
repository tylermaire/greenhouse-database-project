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

-- ***************************
-- 12) Additional Advanced Queries
-- ***************************

-- Query 21: View-based aggregation of staff assignments
SELECT * FROM STAFF_ASSIGNMENT_SUMMARY_VW WHERE TOTAL_ASSIGNMENTS > 1;

-- Query 22: Top 3 most expensive inventory items
SELECT * FROM (
  SELECT * FROM INVENTORY ORDER BY COST_PER_UNIT DESC
) WHERE ROWNUM <= 3;

-- Query 23: Experiments with no associated assignments
SELECT * FROM EXPERIMENT e
WHERE NOT EXISTS (
  SELECT 1 FROM ASSIGNMENT a WHERE a.EXPERIMENT_ID = e.EXPERIMENT_ID
);

-- Query 24: Inner join to find plants in high-capacity spaces
SELECT p.PLANT_ID, s.LOCATION_DESC, s.CAPACITY
FROM PLANT p
JOIN SPACE s ON p.SPACE_ID = s.SPACE_ID
WHERE s.CAPACITY > 100;

-- Query 25: Calculate total cost per experiment from inventory
SELECT EXPERIMENT_ID, SUM(QUANTITY * COST_PER_UNIT) AS TOTAL_COST
FROM INVENTORY
GROUP BY EXPERIMENT_ID;

-- Query 26: Nested subquery to get staff with highest assignment count
SELECT * FROM STAFF s
WHERE s.STAFF_ID = (
  SELECT STAFF_ID FROM (
    SELECT STAFF_ID, COUNT(*) AS CNT
    FROM ASSIGNMENT
    GROUP BY STAFF_ID
    ORDER BY CNT DESC
  ) WHERE ROWNUM = 1
);

-- Query 27: List of plant species with more than one entry
SELECT SPECIES, COUNT(*) AS NUM_SPECIES
FROM PLANT
GROUP BY SPECIES
HAVING COUNT(*) > 1;

-- Query 28: Staff emails containing 'example.com'
SELECT * FROM STAFF WHERE EMAIL LIKE '%example.com';

-- Query 29: Tasks overdue today
SELECT * FROM ASSIGNMENT WHERE DUE_DATE < SYSDATE AND STATUS != 'Completed';

-- Query 30: Join to show plant health status with experiment title and space location
SELECT p.SPECIES, p.HEALTH_STATUS, e.TITLE, s.LOCATION_DESC
FROM PLANT p
JOIN EXPERIMENT e ON p.EXPERIMENT_ID = e.EXPERIMENT_ID
JOIN SPACE s ON p.SPACE_ID = s.SPACE_ID;

-- Query 31: Most common role in STAFF
SELECT ROLE FROM (
  SELECT ROLE, COUNT(*) AS CNT
  FROM STAFF
  GROUP BY ROLE
  ORDER BY CNT DESC
) WHERE ROWNUM = 1;

-- Query 32: Inventory items updated in the last 7 days
SELECT * FROM INVENTORY
WHERE LAST_UPDATED >= SYSDATE - 7;

-- Query 33: Plant count per space type
SELECT sp.SPACE_TYPE, COUNT(pl.PLANT_ID) AS PLANT_COUNT
FROM SPACE sp
JOIN PLANT pl ON sp.SPACE_ID = pl.SPACE_ID
GROUP BY sp.SPACE_TYPE;

-- Query 34: Assignment status percentages
SELECT STATUS, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ASSIGNMENT), 2) AS PERCENTAGE
FROM ASSIGNMENT
GROUP BY STATUS;

-- Query 35: Experiments active today
SELECT * FROM EXPERIMENT
WHERE START_DATE <= SYSDATE AND (END_DATE IS NULL OR END_DATE >= SYSDATE);

-- Query 36: Staff and their assigned experiments (even if none)
SELECT s.FIRST_NAME, s.LAST_NAME, e.TITLE
FROM STAFF s
LEFT JOIN ASSIGNMENT a ON s.STAFF_ID = a.STAFF_ID
LEFT JOIN EXPERIMENT e ON a.EXPERIMENT_ID = e.EXPERIMENT_ID;

-- Query 37: Average inventory item cost by experiment
SELECT EXPERIMENT_ID, ROUND(AVG(COST_PER_UNIT), 2) AS AVG_COST
FROM INVENTORY
GROUP BY EXPERIMENT_ID;

-- Query 38: Plants without notes
SELECT * FROM PLANT WHERE NOTES IS NULL;

-- Query 39: Count of unique roles
SELECT COUNT(DISTINCT ROLE) AS UNIQUE_ROLES FROM STAFF;

-- Query 40: Assignment with the longest overdue time
SELECT * FROM ASSIGNMENT
WHERE STATUS != 'Completed'
AND DUE_DATE = (
  SELECT MIN(DUE_DATE) FROM ASSIGNMENT WHERE STATUS != 'Completed' AND DUE_DATE < SYSDATE
);