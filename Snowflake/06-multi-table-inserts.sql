
-- 6.0.0   Multi-Table Inserts
--         In this lab, you will learn how to use sequences and execute multi-
--         table inserts.
--         - Use sequences to create unique values in a primary key column.
--         - Use unconditional multi-table insert statements.
--         - Use conditional multi-table insert statements.
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

-- 6.1.0   Work with Sequences
--         In this section, you will learn how to create and use a sequence. We
--         will use a sequence in the next section to replace a UUID
--         (universally unique identifier) value with an integer as the unique
--         identifier for each row in a table. Then, we will use the same
--         sequence to create a relationship between two tables.
--         Read the section below to get familiar with sequences in Snowflake.
--         SEQUENCE
--         A SEQUENCE is a named object that belongs to a schema in Snowflake.
--         It consists of a set of sequential, unique numbers that increase or
--         decrease in value based on how the sequence is configured. Sequences
--         can be used to populate columns in a Snowflake table with unique
--         values.
--         SEQUENCE PARAMETERS
--         - NAME (required): Identifies the sequence as a unique object within
--         the schema.
--         - START (optional): The first value of the sequence. The default is
--         one.
--         - INCREMENT (optional): The step interval of the sequence. The
--         default is one.
--         - ORDER | NOORDER (optional): Specifies whether or not the values are
--         generated for the sequence in increasing or decreasing order. The
--         default is NOORDER. The behavior can be changed with the
--         NOORDER_SEQUENCE_AS_DEFAULT parameter.
--         NOTE
--         Snowflake does not guarantee the generation of sequence numbers
--         without gaps. The generated numbers are not necessarily contiguous.
--         If the ORDER keyword is specified, the sequence numbers will increase
--         in value if the INCREMENT value is positive or decrease if the
--         INCREMENT value is negative.

-- 6.1.1   Set the context for the lab.

USE ROLE TRAINING_ROLE;

CREATE WAREHOUSE IF NOT EXISTS FALCON_WH;
USE WAREHOUSE FALCON_WH;

CREATE DATABASE IF NOT EXISTS FALCON_DB;

USE SCHEMA FALCON_DB.PUBLIC;


-- 6.1.2   Create a sequence called item_seq.
--         Here, we’re going to create a sequence called item_seq. We will then
--         use it as a primary key in a table. Note that the start value is one,
--         and the increment value is one. This means we can expect the sequence
--         to start with one and continue with two, three, four, five, etc.

CREATE OR REPLACE SEQUENCE item_seq START = 1 INCREMENT = 1 ORDER;


-- 6.1.3   Now evaluate the nextval expression of the sequence we just created
--         once to see the first value.

-- Show the next value using the nextval method on the sequence object.

SELECT Item_seq.nextval;

--         As you can see, the value is one. The expression <sequence>.nextval
--         returns a new value each time it is evaluated. If you want to apply
--         it to a table, you may want to use the nextval expression for the
--         first time right after creating the sequence. If not, it will pick up
--         the next number in the sequence instead of the first. Let’s test this
--         idea and observe the results.

-- 6.1.4   Create a table, insert some values, and select all values from the
--         table.

-- Create a table with the sequence

CREATE OR REPLACE TABLE item_table ( Item_id INTEGER default Item_seq.nextval, description VARCHAR(20));

-- Insert some rows

INSERT INTO item_table (description) VALUES ('Wheels'), ('Tires'), ('hubcaps');

-- Select all values

SELECT * FROM item_table;

--         As you can see, the first row has an item_id of two rather than one.
--         This is because we iterated to the first sequence value, one when we
--         created the table. So, when we evaluated the nextval expression a
--         second time, the next value was fetched, which was two.
--         Let’s try this again and recreate the sequence and the table.

-- 6.1.5   Recreate the sequence and the table.

-- Reset the sequence. Recreating the sequence is the only way to reset a sequence. 

CREATE OR REPLACE SEQUENCE Item_seq START = 1 INCREMENT = 1 ORDER;

-- Create a table with the sequence.

CREATE OR REPLACE TABLE item_table ( Item_id INTEGER default Item_seq.nextval, description VARCHAR(20));

-- Insert some rows.

INSERT INTO item_table (description) VALUES ('Wheels'), ('Tires'), ('hubcaps');

-- Select all rows from the table

SELECT * FROM item_table;

--         As you can see, the sequence applied to the table now starts with
--         one.

-- 6.1.6   DROP table and sequence.

DROP TABLE item_table;
DROP SEQUENCE item_seq;

--         Before dropping a sequence, verify that no tables or other database
--         objects reference the sequence. If the dropped sequence was
--         referenced in the DEFAULT clause of a table, then calling GET_DDL()
--         for that table results in an error, rather than in the DDL that
--         created the table.

-- 6.1.7   Try the different sequences below and examine the results.
--         The activity below shows how the START and INCREMENT values change
--         the resulting values in a sequence.

-- Create two sequences.

CREATE OR REPLACE SEQUENCE seq_2 START = 2 INCREMENT = 2 ORDER;
CREATE OR REPLACE SEQUENCE seq_3 START = 3 INCREMENT = 3 ORDER;

-- Run each statement below three or four times and observe the sequence value.

SELECT seq_2.nextval;
SELECT seq_3.nextval;


-- 6.2.0   Work with Unconditional Multi-Table Inserts
--         In this section, we will take the SNOWBEARAIR_DB.MODELED.MEMBERS
--         table and divide the data between a customer table, an address table,
--         and a phone table. This will allow a single customer to have multiple
--         addresses and multiple phone numbers.
--         Since we are splitting the original table into three disparate
--         tables, MEMBER_ID is going to be used for the primary key-foreign key
--         relationship between the three tables; an AUTOINCREMENT will not
--         work. We will solve this by using a sequence to insert a new numeric
--         value into each table.
--         In order to do this, we will use a multi-table insert to copy the
--         member data into the three different tables. We will also replace the
--         UUID-based primary key with a sequence.

-- 6.2.1   Create a sequence.
--         Before executing the multi-table insert, we will create a sequence to
--         create a unique ID outside of the table and use it for the MEMBER_ID
--         column. The default for a sequence is START = 1 and INCREMENT = 1.
--         Use this as the default for the MEMBERS table.

CREATE OR REPLACE SEQUENCE member_seq START = 1 INCREMENT = 1 ORDER;


-- 6.2.2   Create the member, member_address and member_phone tables.

CREATE OR REPLACE TABLE member (
   member_id INTEGER DEFAULT member_seq.nextval,
   points_balance NUMBER,
   started_date DATE,
   ended_date DATE,
   registered_date DATE,
   firstname VARCHAR,
   lastname VARCHAR,
   gender VARCHAR,
   age NUMBER,
   email VARCHAR
);

CREATE OR REPLACE TABLE member_address (
   member_id INTEGER,
   street VARCHAR,
   city VARCHAR,
   state VARCHAR,
   zip VARCHAR
);

CREATE OR REPLACE TABLE member_phone (
   member_id INTEGER,
   phone VARCHAR
);


-- 6.2.3   Populate the tables.
--         Next, you’ll execute a multi-table insert statement to copy the data
--         from an existing table into the member, member_address, and
--         member_phone tables.
--         UNCONDITIONAL MULTI-TABLE INSERT SYNTAX A multi-table insert
--         statement can insert rows into multiple tables from the same
--         statement. Note the syntax below:
--         Now, execute the statement below to populate your tables. Note that
--         the sequence member_seq creates our member IDs for us. Also, note how
--         the syntax below reflects what you see in the box above.

INSERT ALL
    INTO member(member_id, points_balance, started_date, ended_date,
            registered_date, firstname, lastname, gender, age, email)
    VALUES (member_id, points_balance, started_date, ended_date,
            registered_date, firstname, lastname, gender, age, email)
            
    INTO member_address (member_id, street, city, state, zip)
    VALUES (member_id, street, city, state, zip)
    
    INTO member_phone(member_id, phone)
    VALUES (member_id, phone)
    
    SELECT member_seq.NEXTVAL AS member_id, points_balance, started_date, 
           ended_date, registered_date, firstname, lastname, gender, age, 
           email, street, city, state, zip, phone
    FROM SNOWBEARAIR_DB.MODELED.MEMBERS;


-- 6.2.4   Confirm there is data in the tables.

SELECT * FROM member ORDER BY member_id;

SELECT * FROM member_address;

SELECT * FROM member_phone;


-- 6.2.5   Join the tables and examine the results.
--         Now, let’s run a query to see how we can join the tables we created
--         to answer questions about the members and their contact information.

-- Run a join between the member, member_address, and phone tables

SELECT 
        m.member_id,
        firstname,
        lastname,
        street,
        city,
        state,
        zip,
        phone
FROM 
    member m 
    LEFT JOIN member_address ma on m.member_id = ma.member_id
    LEFT JOIN member_phone mp on m.member_id = mp.member_id;


-- 6.2.6   Add another row to the MEMBER table.
--         Since the MEMBER table uses the sequence as the default, we can
--         insert another row, which will fetch the next unique value.

INSERT 
    INTO member(points_balance,
            started_date,
            registered_date,
            firstname,
            lastname,
            gender,
            age,
            email)
    VALUES (102000,
            '2014-9-12',
            '2014-8-1',
            'Fred',
            'Wiffle',
            'M',
            '34',
            'Fwiffle@AOL.com');


-- 6.2.7   Check the sequence number of the new row.
--         Notice the value might not be what you would expect. In other words,
--         it may be unique, but it may not be the next value in the sequence,
--         which would be 1001. This is because sequence values are generally
--         contiguous, but sometimes, there can be a gap, related to how
--         Snowflake caches sequence values for better performance.

SELECT * FROM member WHERE member_id > 1000;


-- 6.3.0   Work with Conditional Multi-Table Inserts
--         In this section, we’re going to expand on our earlier work.
--         Specifically, we will use a conditional multi-table insert to break
--         the member table into a gold_member and a club_member table. Gold
--         members have greater than or equal to 5,000,000 points in their
--         balance, and club members have less than 5,000,000. We will use the
--         points_balance column to determine who is a gold member.

-- 6.3.1   Create the tables.

-- The first table will be the gold_member table 

CREATE OR REPLACE TABLE gold_member(
    member_id INTEGER DEFAULT member_seq.nextval,
    points_balance NUMBER,
    started_date DATE,
    ended_date DATE,
    registered_date DATE,
    firstname VARCHAR,
    lastname VARCHAR,
    gender VARCHAR,
    age NUMBER,
    email VARCHAR
);

-- The second table will be the club_member table

CREATE OR REPLACE TABLE club_member (
    member_id INTEGER DEFAULT member_seq.nextval,
    points_balance NUMBER,
    started_date DATE,
    ended_date DATE,
    registered_date DATE,
    firstname VARCHAR,
    lastname VARCHAR,
    gender VARCHAR,
    age NUMBER,
    email VARCHAR
);


-- 6.3.2   Execute the inserts.

INSERT ALL
    WHEN points_balance >= 5000000 THEN    
        INTO gold_member(member_id, points_balance, started_date, ended_date, 
                         registered_date, firstname, lastname, gender, age, email)
        VALUES          (member_id, points_balance, started_date, ended_date, 
                         registered_date, firstname, lastname, gender, age, email)
    ELSE        -- Points_balance is less than 5,000,000, so this member is a club member
        INTO club_member (member_id, points_balance, started_date, ended_date, 
                          registered_date, firstname, lastname, gender, age, email)
        VALUES           (member_id, points_balance, started_date, ended_date, 
                          registered_date, firstname, lastname, gender, age, email)
    SELECT member_id, points_balance, started_date, ended_date, 
           registered_date, firstname, lastname, gender, age, email
    FROM member;


-- 6.3.3   Check that the inserts are correct.
--         Run the statements below and check that the POINTS_BALANCE field in
--         gold_member is greater than or equal to 5,000,000 and less than
--         5,000,000 for club_member.

SELECT MIN(points_balance), MAX(points_balance) FROM gold_member;

SELECT MIN(points_balance), MAX(points_balance) FROM club_member;


-- 6.3.4   Suspend your virtual warehouse.

ALTER WAREHOUSE FALCON_wh SUSPEND;


-- 6.4.0   Key Takeaways
--         - Sequences can be used to populate columns in a table with unique
--         values.
--         - A single multi-insert statement can be used to insert data from one
--         table into multiple tables.
--         - Multi-table inserts can be unconditional or conditional.
