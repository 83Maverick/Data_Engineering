
-- 16.0.0  Access Control and User Management
--         There are two parts to this lab.
--         In Part I, you’ll learn about role-based access control (RBAC) in
--         Snowflake. Specifically, you’ll become familiar with the Snowflake
--         security model and learn how to create roles, grant privileges, and
--         build and implement basic security models.
--         In Part II, you’ll learn about secondary roles and how you can use
--         them to access both primary and secondary roles already granted to
--         the user within a single session.
--         - Show grants to users and roles.
--         - Grant usage on objects to roles.
--         - Use Secondary Roles to aggregate permissions from more than one
--         role.
--         The purpose of this exercise is to give you a chance to see how you
--         can manage access to data in Snowflake by granting privileges to some
--         roles and not to others.
--         In this lab, TRAINING_ROLE will represent the privileges of a user
--         who should have access to a specific table in a particular database.
--         In contrast, role PUBLIC will represent the privileges of a user who
--         shouldn’t.
--         This lab will walk you through the process of setting all this up so
--         you can test the roles and observe the results.
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

-- 16.1.0  Part I - Determine and GRANT Privileges
--         In this section of the lab, you’ll use SHOW GRANTS to determine what
--         roles a user has and what privileges a role has received. This is an
--         important step in determining what a user is or isn’t allowed to do.
--         Then, you’ll learn how to GRANT additional privileges to other roles
--         in order to perform actions on or with a database object.

-- 16.1.1  Set your context and make sure you have the standard lab objects.

USE ROLE TRAINING_ROLE;

CREATE WAREHOUSE IF NOT EXISTS FALCON_WH INITIALLY_SUSPENDED=TRUE;
USE WAREHOUSE FALCON_WH;

CREATE DATABASE IF NOT EXISTS FALCON_DB;

CREATE SCHEMA IF NOT EXISTS FALCON_DB.FALCON_SCHEMA;
USE SCHEMA FALCON_DB.FALCON_SCHEMA;


-- 16.1.2  Run these commands one at a time to see what roles have been granted
--         to you as a user and what privileges have been granted to specified
--         roles.

SHOW GRANTS TO USER FALCON;
SHOW GRANTS TO ROLE PUBLIC;
SHOW GRANTS TO ROLE TRAINING_ROLE;

--         You should see that TRAINING_ROLE has some specific privileges
--         granted and is quite powerful. This has been done intentionally so
--         you can do the labs more easily. In a production environment, it is
--         unlikely that you would ever see a role like this.
--         Next, you’ll use GRANT ROLE to give additional privileges to a ROLE
--         and use GRANT USAGE to permit a user to perform actions on or with a
--         database object.

-- 16.1.3  Create a database called FALCON_CLASSIFIED_DB.

CREATE DATABASE FALCON_CLASSIFIED_DB;


-- 16.1.4  Create a table.
--         Using the role TRAINING_ROLE, create a table named SUPER_SECRET_TBL
--         inside the FALCON_CLASSIFIED_DB.PUBLIC schema.

USE SCHEMA FALCON_CLASSIFIED_DB.PUBLIC;
CREATE TABLE SUPER_SECRET_TBL (id INT);


-- 16.1.5  Insert some data into the table.

INSERT INTO SUPER_SECRET_TBL VALUES (1), (10), (30);


-- 16.1.6  GRANT SELECT privileges on SUPER_SECRET_TBL to the role PUBLIC.
--         Here, we’re going to GRANT SELECT to PUBLIC, but we’re NOT going to
--         GRANT USAGE on the database. We are going to grant usage on a virtual
--         warehouse as PUBLIC doesn’t have permission to use any virtual
--         warehouses at the moment.
--         If we DON’T grant usage on the database AND its schemas to a role,
--         that role won’t be able to do things like create tables or select
--         from tables even IF that role has create or select privileges. In
--         other words, you must have the appropriate permissions on all objects
--         in the hierarchy from top to bottom in order to work at the lowest
--         level of the hierarchy.

GRANT USAGE ON WAREHOUSE FALCON_WH TO ROLE PUBLIC;
GRANT SELECT ON TABLE SUPER_SECRET_TBL TO ROLE PUBLIC;


-- 16.1.7  Use the role PUBLIC to SELECT * from the table SUPER_SECRET_TBL.
--         Now let’s try to select some data using PUBLIC. What do you think is
--         going to happen?

USE ROLE PUBLIC;
SELECT * FROM FALCON_CLASSIFIED_DB.PUBLIC.SUPER_SECRET_TBL;

--         We’re not able to select any data. That’s because the role we’re
--         using has not been granted USAGE on the database or the schema
--         PUBLIC. Let’s GRANT USAGE on both of those objects to PUBLIC and see
--         what happens.

-- 16.1.8  Grant role PUBLIC usage on all schemas in FALCON_CLASSIFIED_DB.

USE ROLE TRAINING_ROLE;

GRANT USAGE ON DATABASE FALCON_CLASSIFIED_DB TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA FALCON_CLASSIFIED_DB.PUBLIC TO ROLE PUBLIC;

USE ROLE PUBLIC;
SELECT * FROM FALCON_CLASSIFIED_DB.PUBLIC.SUPER_SECRET_TBL;

--         This time, it worked! This is because your role has the appropriate
--         permissions at all levels of the hierarchy.

-- 16.1.9  Drop the database FALCON_CLASSIFIED_DB.

USE ROLE TRAINING_ROLE;
DROP DATABASE FALCON_CLASSIFIED_DB;


-- 16.2.0  Part II - Use Secondary Roles
--         In this section, you will use USE SECONDARY ROLES to aggregate
--         permissions from two different roles, TRAINING_ROLE and PUBLIC.
--         First, you will use TRAINING_ROLE to create a database and table and
--         to insert a row into the table. You will then switch to PUBLIC and
--         try to access the table.
--         Next, you will enable secondary roles and try accessing the table
--         again with PUBLIC.

-- 16.2.1  Change to the role TRAINING_ROLE to create the new database and
--         table.

USE ROLE TRAINING_ROLE;


-- 16.2.2  If you haven’t created the virtual warehouse, do it now.

CREATE WAREHOUSE IF NOT EXISTS FALCON_WH;


-- 16.2.3  Create a database called FALCON_ROLETEST_DB.

CREATE DATABASE FALCON_ROLETEST_DB;
USE SCHEMA FALCON_ROLETEST_DB.PUBLIC;

CREATE TABLE ROLE_TBL (id INT);

-- Insert a row of data into the table

INSERT INTO ROLE_TBL VALUES (1), (10), (30);

-- Check the table to make sure the data was loaded

SELECT * FROM ROLE_TBL;


-- 16.2.4  Switch to the role PUBLIC and try to access the database, schema, and
--         table created above.

USE ROLE PUBLIC;
SELECT * FROM FALCON_ROLETEST_DB.PUBLIC.ROLE_TBL;

--         We cannot select any data because PUBLIC has not been granted access
--         to select from the table ROLE_TBL.

-- 16.2.5  Enable SECONDARY ROLES ALL and try again.

USE SECONDARY ROLES ALL;
SELECT * FROM FALCON_ROLETEST_DB.PUBLIC.ROLE_TBL;

--         With SECONDARY ROLES ALL set, the current user can use any permission
--         from any role the user has been granted except CREATE.

-- 16.2.6  Alter the table while SECONDARY ROLES ALL is set.

ALTER TABLE FALCON_ROLETEST_DB.PUBLIC.ROLE_TBL ADD COLUMN name STRING(20);
SELECT * FROM FALCON_ROLETEST_DB.PUBLIC.ROLE_TBL;

--         This should work since the roles granted to your user include
--         TRAINING_ROLE, the owner of the table.

-- 16.2.7  Try creating a new table in the FALCON_ROLETEST_DB.

CREATE TABLE FALCON_ROLETEST_DB.PUBLIC.NOROLE_TBL (name STRING(20));

--         You cannot create a table because the current role PUBLIC does not
--         have CREATE TABLE privileges on the database. As mentioned before,
--         USE SECONDARY ROLES does not include CREATE privileges given to other
--         roles.

-- 16.2.8  Disable secondary roles.

USE SECONDARY ROLES NONE;


-- 16.2.9  Try querying the ROLE_TBL again.

SELECT * FROM FALCON_ROLETEST_DB.PUBLIC.ROLE_TBL;

--         As expected, becasue we have disabled secondary roles, and PUBLIC has
--         not been granted access to select from the table ROLE_TBL, the query
--         does not work.

-- 16.2.10 Suspend your virtual warehouse and drop the database
--         FALCON_ROLETEST_DB.

USE ROLE TRAINING_ROLE;

ALTER WAREHOUSE FALCON_WH SUSPEND;

DROP DATABASE FALCON_ROLETEST_DB;


-- 16.3.0  Key Takeaways
--         - Usage is granted to roles, which in turn are granted to users.
--         - Usage must be granted on all levels in a hierarchy (database and
--         schema) in order for a role to have the ability to select from a
--         table.
--         - Secondary roles can be used to aggregate permissions in a single
--         session.
--         - When using secondary roles, you can only create objects if the
--         primary role has permissions to do that. The secondary role does not
--         include the create privileges given to the other roles.
