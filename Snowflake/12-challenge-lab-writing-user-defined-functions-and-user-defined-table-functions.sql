
-- 12.0.0  Challenge Lab: Writing User-Defined Functions and User-Defined Table
--         Functions
--         The purpose of this lab is to give you an on-your-own experience
--         creating a user-defined function and a user-defined table function in
--         Snowflake. We’ll provide details about the expected result and some
--         hints, but you’ll do most of the work yourself.
--         - Write a SQL user-defined function (UDF) that returns a single
--         value.
--         - Write a SQL user-defined table function (UDTF) that returns a set
--         of rows.
--         HOW TO COMPLETE THIS LAB
--         If you need more than the hints provided, the solution can be found
--         at the end of this lab.

-- 12.1.0  Create a SQL User-defined Function
--         Snowbear Air is tracking product quality and customer satisfaction,
--         and one of the metrics they are using is the percentage of products
--         that have been purchased and then returned. There is a column in the
--         lineitem table called l_returnflag that has two possible values: N
--         (not returned) or R (returned).
--         You will write a query to calculate the percentage of returns from
--         the lineitem table and then turn that query into a UDF.

-- 12.1.1  Set your context to FALCON_DB.FALCON_SCHEMA, role TRAINING_ROLE,
--         and virtual warehouse FALCON_WH.
--         If you’re missing a database, schema, or virtual warehouse, you can
--         use a CREATE statement to create those objects. Then, you can execute
--         your USE statements.

-- 12.1.2  Turn the query below into a user-defined function named
--         FALCON_pct_returned.
--         This query calculates the percentage of all items in the lineitem
--         table that have been returned.

SELECT 
  COUNT_IF(l_returnflag = 'R')/COUNT(l_returnflag)*100
FROM 
  snowbearair_db.promo_catalog_sales.lineitem;


-- 12.1.3  Check to ensure your user-defined function returns the value
--         24.6428%.

-- 12.2.0  Create a User-defined Table Function
--         As part of the customer satisfaction initiative, the shipping team
--         wants to track how long it takes to ship URGENT orders and by what
--         method they are shipped.
--         You will write a user-defined table function to provide the shipping
--         team with the required information.

-- 12.2.1  Set your context to FALCON_DB.FALCON_SCHEMA, role TRAINING_ROLE,
--         and virtual warehouse FALCON_WH.

-- 12.2.2  Turn the query below into a user-defined table function and create
--         the function named FALCON_ship_log.
--         This query returns the following information for all URGENT orders:
--         Order Priority
--         Order Date
--         Receipt Date
--         Ship Mode
--         Ship Time (in days)

SELECT 
   o_orderpriority,
   o_orderdate, 
   l_receiptdate,
   l_shipmode,
   l_receiptdate - o_orderdate AS ship_time
FROM
   snowbearair_db.promo_catalog_sales.orders 
   JOIN snowbearair_db.promo_catalog_sales.lineitem ON o_orderkey = l_orderkey 
WHERE
   o_orderpriority = '1-URGENT'
ORDER BY
   ship_time;

--         In the query above, the order priority has been explicitly specified.
--         When creating the table function, ensure that you pass the order
--         priority as an input parameter, so that you can use the same table
--         function for any order priority.
--         Be careful when implementing string searches in WHERE clauses. For
--         example, Snowflake will see 1-urgent (lowercase) and
--         1-URGENT(uppercase) as different values simply because of the change
--         in case.

-- 12.2.3  Write a query to test your user-defined table function.

-- 12.2.4  Suspend your virtual warehouse.

ALTER WAREHOUSE FALCON_WH SUSPEND;

--         If you need help, the solution is on the next page. Otherwise,
--         congratulations! You have now completed this lab.

-- 12.3.0  Solution to User-defined Function
--         If you need to, you can look at the solution below. But try not to
--         peek! You’ll learn more if you try it on your own first and rely only
--         on the hints.

-- Set your context

USE ROLE TRAINING_ROLE;

CREATE WAREHOUSE IF NOT EXISTS FALCON_WH;
ALTER WAREHOUSE FALCON_WH SET WAREHOUSE_SIZE=XSmall;
USE WAREHOUSE FALCON_WH;

CREATE DATABASE IF NOT EXISTS FALCON_DB;

CREATE SCHEMA IF NOT EXISTS FALCON_db.FALCON_SCHEMA;
USE SCHEMA FALCON_db.FALCON_SCHEMA;

-- After turning the query below into a user-defined function named FALCON_pct_returned.

CREATE OR REPLACE FUNCTION FALCON_pct_returned()
RETURNS NUMBER
AS
  $$
  SELECT
    COUNT_IF(l_returnflag = 'R')/COUNT(l_returnflag)*100
  FROM
    snowbearair_db.promo_catalog_sales.lineitem
  $$
;

-- Check to make sure your UDF returns the value 24.6428%.

SELECT FALCON_pct_returned();


-- 12.4.0  Solution to User-defined Table Function


-- Set your context

USE ROLE TRAINING_ROLE;

CREATE WAREHOUSE IF NOT EXISTS FALCON_WH;
ALTER WAREHOUSE FALCON_WH SET WAREHOUSE_SIZE=XSmall;
USE WAREHOUSE FALCON_WH;

CREATE DATABASE IF NOT EXISTS FALCON_DB;

CREATE SCHEMA IF NOT EXISTS FALCON_DB.FALCON_SCHEMA;
USE SCHEMA FALCON_DB.FALCON_SCHEMA;

-- Turn your query into a UDTF.

CREATE OR REPLACE FUNCTION FALCON_ship_log(order_priority varchar)
RETURNS TABLE (
  priority VARCHAR, 
  date_ordered DATE, 
  date_shipped DATE, 
  shipmode VARCHAR, 
  ship_time NUMBER(38,0))
AS
$$
  SELECT 
    o_orderpriority,
    o_orderdate, 
    l_receiptdate,
    l_shipmode,
    l_receiptdate - o_orderdate AS ship_time
  FROM
    snowbearair_db.promo_catalog_sales.orders 
    JOIN snowbearair_db.promo_catalog_sales.lineitem ON o_orderkey = l_orderkey 
  WHERE
    o_orderpriority = order_priority
  ORDER BY
    ship_time
$$;

-- Make sure your user-defined table function works.

SELECT 
  *
FROM
  TABLE(FALCON_ship_log('1-URGENT'));

-- Suspend your virtual warehouse.

ALTER WAREHOUSE FALCON_WH SUSPEND;

