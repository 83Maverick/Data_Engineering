
-- 17.0.0  Capstone Lab: Putting it All Together
--         The purpose of this lab is to give you an opportunity to apply
--         several of the skills you’ve practiced in a single scenario that
--         combines all of them. We’ll provide some SQL code, details about the
--         expected result, the steps you need to take, and some hints.
--         Otherwise, you’ll create the entire solution on your own.
--         If you need more than the hints provided, the solution can be found
--         at the end of this lab.
--         Also, make sure you take advantage of https://docs.snowflake.com/en/
--         to complete this exercise. If you haven’t looked at our documentation
--         yet, you’ll find it very comprehensive and helpful. We produce that
--         documentation to help you find solutions for your on-the-job tasks,
--         so now is a great time to get familiar with it.
--         Finally, you may solve this exercise in a very different way than we
--         did. If you think you have a better or more elegant solution, go for
--         it! The point here is for you to get some practice that will
--         reinforce what you’ve learned in this course.
--         - Create a table.
--         - Load data from a file in an internal named stage into a table.
--         - Create and call a user-defined function.
--         - Create and call a user-defined table function.
--         - Create a dashboard.
--         - Add tiles to a dashboard.
--         - Create a bar chart in a dashboard tile.
--         Snowbear Air has assigned you to create a dashboard with a bar chart
--         that illustrates the number of flights that did not land on time. The
--         bar chart will need to display individual bars for flights that are
--         10, 20, 30, 40, 50, 60, and 61+ minutes over the planned flight time.
--         You will create a table, load the data, write a user-defined table
--         function that will produce the data you need for the dashboard, and
--         then create the dashboard itself. The dashboard will have two tiles:
--         one with the graph and one listing the data.
--         Expected Result
--         Your dashboard should look like the one shown below when completed.
--         The figures in your charts may differ from what is shown in this
--         screenshot.
--         How to Complete this Lab
--         In a previous lab, you may have used the SQL code file for that lab
--         to create a new worksheet and then just run the code provided within
--         that worksheet. That approach will be modified a bit for this lab due
--         to the nature of what you will be doing.
--         If you use the SQL file instead of the workbook PDF to follow the
--         instructions for this lab, you will not have access to the screenshot
--         of the expected result that can only be seen in the workbook PDF. The
--         best way to complete this lab is to use the PDF workbook instructions
--         for the entire lab from start to finish.
--         Open the SQL file in the text editor of your choice. Copying and
--         pasting from the workbook PDF will result in errors! Also, importing
--         the entire file into a single tile’s worksheet means all queries will
--         be executed when the tile gets refreshed, which will negatively
--         impact performance. The best way to put code in each tile’s worksheet
--         is to open the SQL file in the text editor of your choice and copy
--         and paste from there into your worksheet.
--         Let’s get started!

-- 17.1.0  Create the Data Needed for this Exercise
--         In this section of the lab, you will run some SQL code we have
--         provided, so you will have a stage that contains the files you will
--         need to load in a later step. You must complete all the steps in this
--         section to complete the capstone lab successfully.

-- 17.1.1  Create a new worksheet.

-- 17.1.2  Copy and paste the SQL code below from your SQL file into the new
--         worksheet.
--         This code will set the context, create the file format you’ll use,
--         create an internal named stage, and populate it with the files you
--         need for this exercise. Execute these statements line-by-line, and
--         make sure you do not miss any.

-- Set context
USE ROLE TRAINING_ROLE;

CREATE WAREHOUSE IF NOT EXISTS FALCON_WH INITIALLY_SUSPENDED=TRUE;
USE WAREHOUSE FALCON_WH;

CREATE DATABASE IF NOT EXISTS FALCON_DB;

CREATE SCHEMA IF NOT EXISTS FALCON_DB.FALCON_SCHEMA;
USE SCHEMA FALCON_DB.FALCON_SCHEMA;

-- Create an internal named stage

CREATE OR REPLACE STAGE flight_stage;

-- Create a file format

CREATE OR REPLACE FILE FORMAT flight_file_format TYPE = CSV
COMPRESSION = NONE
FIELD_DELIMITER = '|'
FILE_EXTENSION = 'tbl' 
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- Create the source files

COPY INTO @flight_stage
FROM (
SELECT fl_date,
       op_carrier_fl_num,
       origin,
       dest,
       TIME_FROM_PARTS(SUBSTR(crs_dep_time, 1, 2), SUBSTR(crs_dep_time, 3, 4), 0) AS crs_departure_time,
       TIME_FROM_PARTS(SUBSTR(dep_time, 1, 2), SUBSTR(dep_time, 3, 4), 0) AS departure_time,
       TIME_FROM_PARTS(SUBSTR(crs_arr_time, 1, 2), SUBSTR(crs_arr_time, 3, 4), 0) AS crs_arrival_time,
       TIME_FROM_PARTS(SUBSTR(arr_time, 1, 2), SUBSTR(arr_time, 3, 4), 0) AS arrival_time,
       IFF(crs_arrival_time <= crs_departure_time, DATEADD(day, 1, fl_date), fl_date) crs_arrival_date,
       IFF(arrival_time <= departure_time, DATEADD(day, 1, fl_date), fl_date) arrival_date,
FROM   SNOWBEARAIR_DB.RAW.ONTIME_REPORTING
WHERE year = 2015
AND length(arr_time)<>0
AND length(dep_time)<>0
AND crs_dep_time < crs_arr_time
AND dep_time < arr_time
)
FILE_FORMAT = (FORMAT_NAME = flight_file_format)
OVERWRITE=TRUE;

-- Verify the stage has files
list @flight_stage;


--         In the statement above that creates the source files, the crs in
--         crs_departure_time stands for Computerized Reservations System. So
--         the column crs_departure_time is the scheduled departure time, and
--         crs_arrival_time is the scheduled arrival time. The columns
--         departure_time and arrival_time contain the actual departure and
--         arrival times.
--         The time values in the SNOWBEARAIR_DB.RAW.ONTIME_REPORTING table is
--         stored as a four-character VARCHAR, so the TIME_FROM_PARTS function
--         has been used to convert these to a time format. The column
--         crs_arrival_date contains the scheduled arrival date. The
--         arrival_date column contains the actual arrival date. These arrival
--         dates were computed based on the departure and arrival times.

-- 17.1.3  Close the worksheet since you no longer need it.

-- 17.2.0  Create a Target Table and Load it with Data

-- 17.2.1  Create a new worksheet and inspect the data in the stage
--         @flight_stage.
--         Notice there are a number of files. Below is a SQL statement to view
--         one of the files. You can change the title of the file name in the
--         statement to view different files, but as you see, they all have the
--         same structure.

SELECT $1 FROM @FALCON_db.FALCON_schema.flight_stage/data_0_0_0.tbl;

--         Each row represents a single flight on a specific date, and each has
--         the scheduled departure and arrival, as well as the actual departure
--         and arrival. You can use these figures to determine both the
--         scheduled and actual flight times.

-- 17.2.2  Create the target table.
--         Create a target table to load all the data from the files.
--         You’ll need to set the appropriate data types for the various fields.

CREATE OR REPLACE TABLE flight_reporting (
      FLIGHT_DATE DATE,  
      FLIGHT_NUM VARCHAR(10),
      ORIGIN_AIRPORT VARCHAR(10),    
      DEST_AIRPORT VARCHAR(10),      
      DEPARTURE_TIME_SCHEDULED TIME,
      DEPARTURE_TIME_ACTUAL TIME,    
      ARRIVAL_TIME_SCHEDULED TIME,   
      ARRIVAL_TIME_ACTUAL TIME,
      ARRIVAL_DATE_SCHEDULED DATE,
      ARRIVAL_DATE_ACTUAL DATE
);


-- 17.2.3  Copy the file data into the target table and verify the data was
--         added successfully.
--         For this, you need a simple COPY INTO statement.
--         Use the file format that you used to create the data for this
--         exercise.
--         The fully qualified path should include the database name, schema
--         name, stage name, and file path. Rather than load each file one by
--         one, you can load all the files by ending the FROM clause of your
--         COPY INTO statement with the folder name where the files are located.
--         If you need to clear out your table and start over for any reason,
--         you can use TRUNCATE to delete the data.

-- 17.3.0  Write a User-Defined Function and a User-Defined Table Function

-- 17.3.1  Write a user-defined function to calculate flight delay time.
--         Write a SQL user-defined function that calculates the difference
--         between the actual flight and scheduled flight times.
--         Determine the TIMESTAMP for actual arrival, actual departure,
--         scheduled arrival, and scheduled departure. The TIMESTAMP for a given
--         date and time can be determined with the TIMESTAMP_FROM_PARTS(date,
--         time) function.
--         Then use the calculation below to determine the flight delay time.
--         - (arrival_actual_ts - departure_actual_ts) - (arrival_scheduled_ts -
--         departure_scheduled_ts)

-- 17.3.2  Write a SQL user-defined table function.
--         The user-defined table function you will create in this step should
--         call the user-defined function you just created and return a table
--         with the data you need for your query.
--         The user-defined function you just wrote produces the bands below.
--         If the flight delay time is between 1 AND 10, the band is 1 - 10.
--         If the flight delay time is between 11 AND 20, the band is 11 - 20.
--         If the flight delay time is between 21 AND 30, the band is 21 - 30.
--         If the flight delay time is between 30 AND 40, the band is 31 - 40.
--         If the flight delay time is between 40 AND 50, the band is 41 - 50.
--         If the flight delay time is between 51 AND 60, the band is 51 - 60.
--         If the flight delay time is greater than 60, the band is 60 +.
--         You can use a CASE statement to produce the bands. CASE is a
--         conditional expression function. Check the documentation for details
--         about syntax and how to use it.
--         Also, remember that some flights will have an actual flight time
--         shorter than the scheduled flight time, while others will have a
--         flight time equal to the scheduled flight time. You will exclude
--         those bands from the final dashboard.

-- 17.4.0  Write the Query

-- 17.4.1  Write a query that uses the user-defined table function to produce
--         the data for the dashboard.
--         The query should produce a band and the flight count for each band.
--         You will need a GROUP BY statement.
--         Check our documentation for details about how to use a user-defined
--         table function in a SQL statement.

-- 17.4.2  Create a dashboard with two tiles, one for the data and one for the
--         bar chart.

-- 17.4.3  When you are finished, suspend your virtual warehouse.

ALTER WAREHOUSE FALCON_WH SUSPEND;

--         Congratulations! You have now completed this lab.
--         If you need help, the solution is on the next page.

-- 17.5.0  Solution for SQL Portion of Lab
--         Remember to set your context based on the Create the Data Needed for
--         this Exercise section before you use the solution.


-- Create the target table

CREATE OR REPLACE TABLE flight_reporting (
      FLIGHT_DATE DATE,  
      FLIGHT_NUM VARCHAR(10),
      ORIGIN_AIRPORT VARCHAR(10),    
      DEST_AIRPORT VARCHAR(10),      
      DEPARTURE_TIME_SCHEDULED TIME,
      DEPARTURE_TIME_ACTUAL TIME,    
      ARRIVAL_TIME_SCHEDULED TIME,   
      ARRIVAL_TIME_ACTUAL TIME,
      ARRIVAL_DATE_SCHEDULED DATE,
      ARRIVAL_DATE_ACTUAL DATE
);

-- Copy the files into the target table

COPY INTO flight_reporting
FROM @FALCON_DB.FALCON_SCHEMA.flight_stage/ pattern='.*\.tbl.*'
FILE_FORMAT = (FORMAT_NAME = flight_file_format);

-- Verify the table is populated

SELECT * FROM flight_reporting;


-- Create the function that calculates the difference between the actual flight time and the scheduled flight time

CREATE OR REPLACE function flight_time_difference(flight_date DATE, departure_time_scheduled TIME, departure_time_actual TIME, arrival_date_scheduled DATE, arrival_time_scheduled TIME, arrival_date_actual DATE, arrival_time_actual TIME)
RETURNS INTEGER
AS $$
     DATEDIFF(minutes, TIMESTAMP_FROM_PARTS(flight_date, departure_time_actual), TIMESTAMP_FROM_PARTS(arrival_date_actual, arrival_time_actual) ) -
     DATEDIFF(minutes, TIMESTAMP_FROM_PARTS(flight_date, departure_time_scheduled), TIMESTAMP_FROM_PARTS(arrival_date_scheduled, arrival_time_scheduled))
$$;

-- Verify the function works as expected

SELECT  
        *,
        flight_time_difference(flight_date, departure_time_scheduled, departure_time_actual, arrival_date_scheduled, arrival_time_scheduled, arrival_date_actual, arrival_time_actual) AS time_difference
FROM
        flight_reporting
WHERE
        time_difference > 0;

-- Create the UDTF to return the data

CREATE OR REPLACE FUNCTION time_band_table()
RETURNS TABLE (time_band varchar)
AS
$$
    WITH cte AS 
    (SELECT  
        flight_time_difference(flight_date, departure_time_scheduled, departure_time_actual, arrival_date_scheduled, arrival_time_scheduled, arrival_date_actual, arrival_time_actual)
        AS time_difference
    FROM
        flight_reporting) 
    SELECT  
    CASE
        WHEN time_difference < 0 THEN 'Shorter flight'
        WHEN time_difference = 0 THEN 'Scheduled=Actual'
        WHEN time_difference BETWEEN  1 AND 10 THEN  '+ 1 - 10'
        WHEN time_difference BETWEEN 11 AND 20 THEN '+ 11 - 20'
        WHEN time_difference BETWEEN 21 AND 30 THEN '+ 21 - 30'
        WHEN time_difference BETWEEN 30 AND 40 THEN '+ 31 - 40'
        WHEN time_difference BETWEEN 40 AND 50 THEN '+ 41 - 50'
        WHEN time_difference BETWEEN 51 AND 60 THEN '+ 51 - 60'
        ELSE '60 +'
    END as time_band
    FROM cte
    WHERE time_band NOT IN ('Shorter flight', 'Scheduled=Actual')
    ORDER BY time_band
$$;

-- Create the query that will produce two columns - the time band and the count of flights in that band

SELECT 
    time_band, 
    COUNT(time_band) AS time_band_count 
FROM 
    TABLE(time_band_table())
GROUP BY 
    time_band 
ORDER BY 
    time_band;



-- 17.6.0  Solution for Creating a Dashboard
--         The steps below show you how to create a dashboard from scratch. If
--         you have a worksheet that you want to turn into a tile on the
--         dashboard, an alternate method is to create a new dashboard from a
--         worksheet. To do this, click the ellipsis to the right of the
--         worksheet name and navigate to Move to. Then select + New Dashboard
--         from the drop-down list.

-- 17.6.1  From the home page, in the left navigation bar select Projects, then
--         select Dashboards.

-- 17.6.2  Click the blue + Dashboard button in the upper right.

-- 17.6.3  A dialog box will appear. Type a name for the dashboard and click the
--         Create Dashboard button.

-- 17.6.4  Once the dashboard is open, select the role and virtual warehouse at
--         the top right of the page.
--         - Role: TRAINING_ROLE
--         - Warehouse: FALCON_WH

-- 17.6.5  Click the blue New Tile button in the center of the page.
--         From the drop-down menu, click on From SQL Worksheet.

-- 17.6.6  You should see an empty worksheet. At the top of the worksheet,
--         select the database and schema.
--         - Database: FALCON_DB
--         - Schema: FALCON_SCHEMA

-- 17.6.7  To rename the worksheet, click the arrow next to the date/time shown
--         at the top of the worksheet, type in the new name, and hit enter.

-- 17.6.8  Copy and paste your query into the pane, or type your query from
--         scratch.

-- 17.6.9  Click the run button in the upper right of the worksheet to verify
--         your code runs without errors.

-- 17.6.10 If you want to display the query result details in your dashboard,
--         click on the Return to <dashboard-name> link in the upper-left area
--         of the worksheet.

-- 17.6.11 If creating a chart, click the Chart button just above the query
--         results.
--         When the chart is visible, click Chart type in the right side menu to
--         change the chart to a bar chart. Choose the required orientation for
--         the bar chart. Optionally, you may also set labels for the X-axis and
--         Y-axis for your bar chart.
--         When finished, use the Return to <dashboard-name> link in the upper-
--         left area of the worksheet to return to your dashboard. The tile
--         should be displayed on the dashboard.

-- 17.6.12 Create your next tile.
--         To add tiles to your dashboard, click the + button below the < arrow
--         at the top left of your dashboard window.
--         Click on the blue New Tile button at the bottom of the list to add
--         your next tile. From the drop-down list, select From SQL Worksheet.

-- 17.6.13 Repeat the steps for each additional tile.

-- 17.6.14 Drag and reposition your tiles as needed.
--         To reposition a tile, navigate to the dashboard and launch it. Hover
--         your mouse cursor over the tile you wish to move, click and hold the
--         mouse button. Then, while holding down the mouse button, drag the
--         tile to the desired position and release the mouse button.
