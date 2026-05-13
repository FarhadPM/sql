/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1

/* Note: I am assuming that for blank, you mean '', not a ' ' that I consider a white space */

SELECT 
	product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')' AS products

FROM product;


--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2

SELECT 
	ROW_NUMBER() OVER(PARTITION BY cp.customer_id ORDER BY cp.market_date, cp.transaction_time) AS visit_number,
	cp.customer_id, 
	cp.market_date, 
	cp.transaction_time, 
	cp.vendor_id, 
	cp.product_id, 
	cp.quantity, 
	cp.cost_to_customer_per_qty

FROM customer_purchases cp

WHERE cp.market_date < '2022-04-29';


--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

/* 3.1: Temporary table to contain each customer's visit ordered by most recent visits */

-- If a table named recent_customer_visits exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS temp.recent_customer_visits;

-- Create the table
CREATE TABLE temp.recent_customer_visits AS

	-- Definition of the table

	SELECT 
		ROW_NUMBER() OVER(PARTITION BY cp.customer_id ORDER BY cp.market_date DESC, cp.transaction_time DESC) AS visit_number_recent,
		cp.customer_id, 
		cp.market_date, 
		cp.transaction_time, 
		cp.vendor_id, 
		cp.product_id, 
		cp.quantity, 
		cp.cost_to_customer_per_qty

	FROM customer_purchases cp;

/* 3.2: Filter the results to only the customer’s most recent visit. */

SELECT rcv.*

FROM temp.recent_customer_visits AS rcv

WHERE rcv.visit_number_recent = 1;


--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4

/* 4.1: How many different times that customer has purchased that product_id?  */

SELECT 
	cp.customer_id, 
	cp.product_id,
	COUNT(*) OVER(PARTITION BY cp.customer_id, cp.product_id) AS number_of_purchase_times,
	cp.vendor_id, 
	cp.market_date, 
	cp.transaction_time,
	cp.quantity, 
	cp.cost_to_customer_per_qty	

FROM customer_purchases cp;

/* 4.2: A running count and filtering the visits to dates before April 29, 2022.  */

SELECT 
	cp.customer_id, 
	cp.product_id,
	COUNT(*) OVER(PARTITION BY cp.customer_id, cp.product_id ORDER BY cp.market_date, cp.transaction_time) AS number_of_purchase_times_rolling_count,
	cp.vendor_id, 
	cp.market_date, 
	cp.transaction_time,
	cp.quantity, 
	cp.cost_to_customer_per_qty	

FROM customer_purchases cp

WHERE cp.market_date < '2022-04-29';


--END QUERY


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5

SELECT 
	product_id, 
	product_name, 
	
	CASE
		WHEN product_name LIKE '%-%'
			THEN TRIM(LTRIM(SUBSTR(product_name, INSTR(product_name, '-')), '-'))
		ELSE NULL 
	END AS description,
	
	product_size,
	product_category_id, 
	product_qty_type

FROM product;


--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6

SELECT 
	product_id, 
	product_name, 
	
	CASE
		WHEN product_name LIKE '%-%'
			THEN TRIM(LTRIM(SUBSTR(product_name, INSTR(product_name, '-')), '-'))
		ELSE NULL 
	END AS description,
	
	product_size,
	product_category_id, 
	product_qty_type

FROM product

WHERE product_size REGEXP '\d+';


--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

/* 7.1: Create a CTE/Temp Table to find sales values grouped dates */

-- If a table named market_date_sales exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS temp.market_date_sales;

-- Create the table
CREATE TABLE temp.market_date_sales AS

	-- Definition of the table

	SELECT 
		cp.market_date, 
		SUM(cp.quantity * cp.cost_to_customer_per_qty) AS total_sales

	FROM customer_purchases cp
	
	GROUP BY cp.market_date;
	
/* 7.1: Create another CTE/Temp table with a rank windowed function on the previous query to create */

-- If a table named market_date_sales_ranked exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS temp.market_date_sales_ranked;

-- Create the table
CREATE TABLE temp.market_date_sales_ranked AS

	-- Definition of the table
	
	SELECT 
		mds.market_date, 
		mds.total_sales, 
		RANK() OVER(ORDER BY mds.total_sales DESC) AS total_sales_rank_best, -- ranking best days
		RANK() OVER(ORDER BY mds.total_sales ASC) AS total_sales_rank_worst -- ranking worst days
		
	FROM temp.market_date_sales AS mds;

/* 7.3: Query the second temp table twice, once for the best day, once for the worst day, with a UNION binding them */

SELECT mdsr.*

FROM market_date_sales_ranked AS mdsr

WHERE mdsr.total_sales_rank_best = 1 -- best day

UNION

SELECT mdsr.*

FROM market_date_sales_ranked AS mdsr

WHERE mdsr.total_sales_rank_worst = 1; -- worst day



--END QUERY



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

SELECT 
	v.vendor_name,
	p.product_name,
	SUM(x.sold_to_customer) AS total_sales_to_customers

FROM vendor AS v -- vendor table gives the vendor_name

INNER JOIN (
	
	/* subquery for a cartesian product of tables: vendor_inventory and customer.
	   This gives all the sales possibilities (208) of vendors => products => customers  */
	SELECT DISTINCT
		vendor_id, 
		product_id, 
		original_price,
		(original_price * 5) AS sold_to_customer, -- 5 of each of vendors' products sold to every customer on record
		customer_id

	FROM vendor_inventory -- DISTINCT vendor_id, product_id: 8 rows

	CROSS JOIN customer -- 26 rows
	-- 8 * 26 = 208 rows for the cartesian product

) AS x
	
	ON v.vendor_id = x.vendor_id
	
INNER JOIN product AS p -- product table gives the product_name
	ON x.product_id = p.product_id
	
GROUP BY x.vendor_id, x.product_id;

--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9

-- If a table named product_units exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS product_units;

-- Create the table
CREATE TABLE product_units AS

	-- Definition of the table
	
	SELECT
		p.*,
		CURRENT_TIMESTAMP AS snapshot_timestamp
				
	FROM product AS p
	
	WHERE p.product_qty_type = 'unit';


--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10


INSERT INTO product_units

VALUES (24, 'Apple Pie', '20"', 3, 'unit', CURRENT_TIMESTAMP);


--END QUERY


-- DELETE
/* 1. Delete the older record for whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11

/* 11.1: A CTE to contain the rank of snapshot_timestamp */
WITH product_units_time_ranked AS (

	SELECT 
		snapshot_timestamp,
		ROW_NUMBER() OVER(ORDER BY snapshot_timestamp DESC) AS older_record_rank
		
	FROM product_units
	
)

/* 11.2: Delete the oldest record */
DELETE FROM product_units AS pu

WHERE pu.snapshot_timestamp
	IN (
		SELECT putr.snapshot_timestamp
		
		FROM product_units_time_ranked AS putr
		
		WHERE putr.older_record_rank = 1
		);


--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
--QUERY 12

/* 12.1: Add the current_quantity to the product_units table. */
ALTER TABLE product_units

ADD current_quantity INT;

/* 12.2: change the current_quantity equal to the last quantity value from the vendor_inventory details. */

/* 12.2.1: Create a temp table to store the rank of market_date per product in the vendor_inventory table */

-- If a table named product_inventory_date_ranked exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS temp.product_inventory_date_ranked;

-- Create the table
CREATE TABLE temp.product_inventory_date_ranked AS

	-- Definition of the table
	
	SELECT
		product_id, 
		quantity,
		market_date,
		ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY market_date DESC) AS recent_date_rank
	
	FROM vendor_inventory;

/* 12.2.2: Create a temporary table to get the last quantity per product */

-- If a table named product_inventory_last_quantity exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS temp.product_inventory_last_quantity;

-- Create the table
CREATE TABLE temp.product_inventory_last_quantity AS

	-- Definition of the table

	SELECT *

	FROM product_inventory_date_ranked

	WHERE recent_date_rank = 1;

/* 12.2.3: Create a temporary table to hold the new_current_quantity: needed for the UPDATE query.

           This is also helpful with coalesce null values to zero and updating current_quantity with last_quantity */

-- If a table named product_inventory_new_current_quantity exists, delete it, otherwise do NOTHING
DROP TABLE IF EXISTS temp.product_inventory_new_current_quantity;

-- Create the table
CREATE TABLE temp.product_inventory_new_current_quantity AS

	-- Definition of the table
		   
	SELECT 
		pu.*,
		pilq.*,
		COALESCE(pu.current_quantity, pilq.quantity, 0) AS new_current_quantity
		
	FROM product_units AS pu

	LEFT JOIN temp.product_inventory_last_quantity AS pilq
		ON pu.product_id = pilq.product_id;
		

/* 12.2.4: Update product_units: set its current_quantity attribute to the last quantity */

UPDATE product_units

SET current_quantity = pincq.new_current_quantity

FROM temp.product_inventory_new_current_quantity AS pincq

WHERE product_units.product_id = pincq.product_id;

/* Test to see the updated column: current_quantity 

SELECT *
FROM product_units

Successful! */ 


--END QUERY



