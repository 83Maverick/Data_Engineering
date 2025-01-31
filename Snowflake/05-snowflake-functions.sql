
-- 5.0.0   Snowflake Functions
--         The purpose of this lab is to introduce you to Snowflake’s extensive,
--         built-in function library.
--         The average Snowflake user uses three Snowflake components to get
--         work done: core SQL constructs (SQL itself), the compute layer, and
--         functions. Thus, functions are helpful in every workload, including
--         data engineering, data lake, data warehousing, data science, data
--         applications, and collaboration.
--         In this lab, you’ll become familiar with several Snowflake SQL
--         functions. You may be familiar with similar or identical functions
--         from other database or data warehouse systems.
--         - Use scalar functions.
--         - Use conditional functions such as IFF() and CASE.
--         - Use date/context functions.
--         - Use aggregate functions such as MIN, MAX, SUM, AVG, and MEDIAN.
--         - Use window functions.
--         - Use table functions.
--         HOW TO COMPLETE THIS LAB
--         Since the workbook PDF has useful diagrams and illustrations (not
--         present in the .SQL files), we recommend that you read the
--         instructions from the workbook PDF. In order to execute the code
--         presented in each step, use the SQL code file provided for this lab.
--         OPENING THE SQL FILE
--         To load the SQL file, in the left navigation bar select Projects,
--         then select Worksheets. From the Worksheets page, in the upper-right
--         corner, click the ellipsis (…) to the left of the blue plus (+)
--         button. Select Create Worksheet from SQL File from the drop-down
--         menu. Navigate to the SQL file for this lab and load it.
--         Let’s get started!

-- 5.1.0   Scalar Functions
--         Scalar functions take a single row or value as input and return a
--         single value, such as a number, a string, or a boolean value.
--         Click here to learn more about Snowflake’s scalar functions.
--         (https://docs.snowflake.com/en/sql-reference/functions.html)
--         Note that although you are probably familiar with most, if not all,
--         of them, some functions may have different names or syntax than what
--         you’ve seen in other systems.
--         Now, let’s try using a few scalar functions.

-- 5.1.1   Set your context.

USE ROLE TRAINING_ROLE;

CREATE WAREHOUSE IF NOT EXISTS FALCON_wh;
USE WAREHOUSE FALCON_wh;

USE SCHEMA SNOWBEARAIR_db.PROMO_CATALOG_SALES;


-- 5.1.2   Execute the query with the CONCAT() function.
--         The query below uses the CONCAT() function to concatenate the part
--         and supplier names. Execute the query to see the result.

SELECT
    p.p_name as part_name,
    s.s_name AS supplier_name,
    CONCAT(p.p_name, ' - ', s.s_name) AS part_and_supplier
FROM    
    part p
    INNER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey;


-- 5.1.3   Execute the query with the || concatenation operator.
--         The query below is functionally identical to the previous one,
--         although it does have a syntactical difference. It uses the double-
--         pipe concatenation operator to achieve the same result.

SELECT
    p.p_name as part_name,
    s.s_name AS supplier_name,
    p.p_name || ' - ' || s.s_name AS part_and_supplier
FROM    
    part p
    INNER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey;


-- 5.1.4   Execute the query with the LPAD() function.
--         You can use the LPAD function to pad a value so that all values in
--         the column have the same length and potentially the same leading
--         characters.
--         In the example below, we pad all the values in the p_partkey column
--         with zeroes so they are all ten characters. If a key was already 10
--         characters, it would not be padded. In this case, however, the
--         maximum length of the key is six characters, so some values will be
--         left padded with at least four zeroes.
--         Execute the statement below to see the result.

SELECT LPAD(p.p_partkey, 10, '0')
FROM    
    part p; 

--         NOTE: As you may have guessed, an RPAD() function behaves
--         identically, except that it pads the right side of the value.

-- 5.1.5   Execute the query with the IFF() function.
--         IFF allows you to do an IF-THEN-ELSE analysis. IFF takes three
--         arguments: the condition, what to return if the condition is true,
--         and what to return if the condition is false.
--         Execute the statement below using the conditional function IFF to see
--         what it does.

SELECT
    s.s_name AS supplier_name,
    IFF(s.s_acctbal > 500, 'Gold Member', 'Silver Member') membership_status    
FROM    
    supplier s; 


-- 5.1.6   Execute the queries with the CASE statements.
--         Here, you’ll use a CASE expression to indicate whether or not a
--         particular part of an order has been returned.

SELECT 
            O_ORDERKEY AS ORDER_NUMBER,
            L.L_PARTKEY AS PART_NUMBER,
            CASE 
                WHEN L.L_RETURNFLAG = 'N'
                    THEN 'NOT RETURNED'
                WHEN L.L_RETURNFLAG = 'R'
                    THEN 'RETURNED'
            END AS RETURN_STATUS
FROM
    ORDERS O 
    INNER JOIN LINEITEM L ON O.O_ORDERKEY = L.L_ORDERKEY
LIMIT 100;

--         In the example below, you’ll determine the membership status of a
--         supplier with a CASE statement.

SELECT
    s.s_name AS supplier_name,
    CASE
        WHEN s.s_acctbal<100 THEN 'Bronze Member'
        WHEN s.s_acctbal>=100 AND s.s_acctbal <500 THEN 'Silver Member'
        WHEN s.s_acctbal >=500 THEN 'Gold Member'
    END AS membership_status
FROM    
    supplier s; 


-- 5.1.7   Run queries with date functions.
--         The date functions below extract the year, month, or day from the
--         date. Run the query to see the result.

--DATE FUNCTIONS
SELECT
    YEAR(O.O_ORDERDATE) AS year_of_order,
    MONTH(O.O_ORDERDATE) AS month_of_order,
    DAYOFMONTH(O.O_ORDERDATE) AS day_of_order
FROM 
    ORDERS O;

--         Below is an example of a casting function. This function uses a
--         double colon followed by the data type to which the expression to the
--         left of the colons will be cast.
--         Notice that a string is being cast to a date, time, or date time in
--         each instance.
--         Run the queries below and examine the results.

--CASTING 
--FROM DATE
SELECT DAY('2023-01-16'::DATE);
SELECT MONTH('2023-01-16'::DATE);
SELECT YEAR('2023-01-16'::DATE);    
    
--FROM TIME
SELECT HOUR('19:06:45.988'::TIME);
SELECT MINUTE('19:06:45.988'::TIME);
SELECT SECOND('19:06:45.988'::TIME);

--FROM DATETIME
SELECT HOUR('2023-01-16T19:10:27.848-08:00'::DATETIME);
SELECT MINUTE('2023-01-16T19:10:27.848-08:00'::DATETIME);
SELECT SECOND('2023-01-16T19:10:27.848-08:00'::DATETIME);
SELECT DAY('2023-01-16T19:10:27.848-08:00'::DATETIME);
SELECT MONTH('2023-01-16T19:10:27.848-08:00'::DATETIME);
SELECT YEAR('2023-01-16T19:10:27.848-08:00'::DATETIME);


-- 5.1.8   Run queries with context functions.
--         Below are three queries with context functions. Their names are self-
--         explanatory. Run the queries and examine the result.

--CONTEXT FUNCTIONS    
SELECT CURRENT_TIME();

SELECT CURRENT_TIMESTAMP();

SELECT CURRENT_DATE();


-- 5.1.9   Run queries with the DATEADD() function.
--         The DATEADD() function below will allow you to add or subtract years,
--         months, or days from a date and hours, minutes, or seconds from a
--         timestamp. The parameters are the date or time part, the interval to
--         add (a positive integer to add, a negative integer to subtract), and
--         the date.
--         Run the queries below and examine the result. Notice that the
--         TO_DATE() function and ::DATE are being used to convert strings to
--         dates and that ::DATETIME is being used to convert strings into time
--         stamps.

-- DATEADD()
-- The following two queries are functionally identical. 
-- Note the use of TO_DATE() vs. ::DATE.

SELECT 
    TO_DATE('2021-03-30') AS MYDATE,
    DATEADD('days', 2,TO_DATE('2021-03-30')) AS ADDING_2_DAYS;

SELECT 
    TO_DATE('2021-03-30') AS MYDATE,
    DATEADD('days', 2,'2021-03-30'::DATE) AS ADDING_2_DAYS;


-- The following two queries are functionally identical. 
-- Note the use of TO_TIMESTAMP() vs. ::DATETIME.

SELECT 
    '2023-01-16T19:10:27.848-08:00'::DATETIME AS MYTIMESTAMP,
    DATEADD('minutes',2,'2023-01-16T19:10:27.848-08:00'::DATETIME) AS ADDING_2_MINUTES;    

SELECT 
    '2023-01-16T19:10:27.848-08:00'::DATETIME AS MYTIMESTAMP,
    DATEADD('minutes',2,TO_TIMESTAMP('2023-01-16T19:10:27.848-08:00')) AS ADDING_2_MINUTES;   



-- 5.2.0   Aggregate Functions
--         Aggregate functions work across rows to perform mathematical
--         functions such as MIN, MAX, COUNT, and various statistical functions.
--         There are several functions you have most likely seen or used in
--         another database system or a spreadsheet program. Click here to learn
--         more about Snowflake’s Aggregate functions
--         (https://docs.snowflake.com/en/sql-reference/functions-
--         aggregation.html).

-- 5.2.1   Run queries with the aggregate functions MIN, MAX, SUM, AVG, and
--         MEDIAN.

--MIN/MAX
SELECT 
    MIN(s.s_acctbal) AS MIN_ACCT_BAL, 
    MAX(s.s_acctbal) AS MAX_ACCT_BAL
FROM supplier s;    
    
--SUM
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    MIN(s.s_acctbal) AS MIN_ACCT_BAL, 
    MAX(s.s_acctbal) AS MAX_ACCT_BAL,
    SUM(s.s_ACCTBAL) AS combined_total 
FROM 
    supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY
    region_name,
    nation_name
    ;

 --AVG, MEDIAN
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    MIN(S.S_ACCTBAL) AS MIN_ACCT_BAL, 
    MAX(S.S_ACCTBAL) AS MAX_ACCT_BAL,
    SUM(S.S_ACCTBAL)::DECIMAL(18,2) AS combined_total,
    AVG(S.S_ACCTBAL)::DECIMAL(18,2) AS average_acct_bal,
    MEDIAN(S.S_ACCTBAL)::DECIMAL(18,2) AS median_acct_bal      
FROM 
    supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY
    region_name,
    nation_name;


-- 5.3.0   Window Functions
--         Window frame functions allow you to perform rolling operations, such
--         as calculating a running total or a moving average, on a subset of
--         the rows in the window. As you’ll see below, the OVER clause allows
--         you to partition rows by a specific value (a window) and order the
--         rows within that window. You can then aggregate values within the
--         window.
--         Many aggregate functions you saw earlier can work with the OVER
--         clause, enabling aggregations across a group of rows.
--         Click here to learn more about Snowflake’s Window functions
--         (https://docs.snowflake.com/en/sql-reference/functions-
--         analytic.html).

-- 5.3.1   Run a query with a window function.
--         We will use the query below to determine each virtual warehouse’s
--         credit usage per date and hour. The total usage per virtual warehouse
--         per date is rolled-up as a column for each record. The credit usage
--         per hour per date is also computed as a percentage. The SQL statement
--         accomplishes this by querying the WAREHOUSE_METERING_HISTORY secure
--         view in the ACCOUNT_USAGE schema of the Snowflake database. We
--         partition by date and the virtual warehouse name.
--         Run the query now and examine the result.

SELECT
        warehouse_name,
        DATE(start_time) AS dt,
        HOUR(start_time) AS hour,
        credits_used,
        SUM(credits_used)
            OVER (PARTITION BY dt, warehouse_name) AS dt_tot_credits,
        ((credits_used / dt_tot_credits) * 100)::NUMBER(6,2) as pct_of_dt_total_credits
FROM
        SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE credits_used <> 0 AND warehouse_name is not null
ORDER BY
        warehouse_name, dt, hour;


-- 5.4.0   Table Functions
--         Table functions return a set of rows instead of a single scalar
--         value. Table functions appear in the FROM clause of a SQL statement
--         and cannot be used as scalar functions.
--         Click here to learn more about Snowflake’s Table functions
--         (https://docs.snowflake.com/en/sql-reference/functions-table.html).

-- 5.4.1   Use a table function to retrieve one hour of query history.
--         As you can see below, we are querying the query_history table
--         function. It takes two parameters in TIMESTAMP format: start and end
--         times.
--         To get a result set, the query_history table function and the
--         parameter values must be passed into the function TABLE().
--         Run the query below and examine the result.

SELECT
        *
FROM
        TABLE(
                information_schema.query_history(
                        DATEADD('hours', -1, CURRENT_TIMESTAMP()), --START
                        CURRENT_TIMESTAMP()                        --END
                    )
              )
ORDER BY
        start_time;

--         Save the Query ID of the last query as a session variable called
--         qhist_queryid.

SET qhist_queryid = LAST_QUERY_ID();

--         We will use this saved Query ID with the Result Scan table function.

-- 5.4.2   Use the RESULT_SCAN function to return the last result set.
--         The function RESULT_SCAN returns the result set of a previous command
--         (within 24 hours of when you executed the query) as if the results
--         were a table. This is useful if you want to process the output of
--         SHOW or DESCRIBE, the output of a query executed on account usage
--         information, such as INFORMATION_SCHEMA or ACCOUNT_USAGE, or the
--         output of a stored procedure.
--         Before running the RESULT_SCAN, we will suspend our virtual
--         warehouse.

ALTER WAREHOUSE FALCON_wh SUSPEND;

--         If you try to suspend the virtual warehouse and it is already
--         suspended, you may get an error. This is normal.
--         The query below is simple and just produces the results of the query
--         history query you ran previously. The session variable qhist_queryid
--         that was previously saved is used as an input.

SELECT * FROM TABLE(RESULT_SCAN($qhist_queryid));

--         The RESULT_SCAN does not need a virtual warehouse unless you are
--         doing other processing (like filtering) with RESULT_SCAN. This helps
--         you save on credits by re-using your result sets.

-- 5.5.0   Key Takeaways
--         - Snowflake has many functions you are already accustomed to using in
--         other software programs.
--         - Scalar functions take a single row or value as input and return a
--         single value, such as a number, a string, or a boolean value.
--         - Aggregate functions work across rows to perform mathematical
--         calculations such as MIN, MAX, COUNT, and various statistical
--         calculations.
--         - Window functions allow performing rolling operations, such as
--         calculating a running total or a moving average, on a subset of rows.
--         - Table functions return a set of rows rather than a scalar value.
