-- Question Set - 1 (Easy)

--1. Who is the senior most employee based on job title?
SELECT title, CONCAT(first_name,last_name) Emp_Name,reports_to
FROM employee WHERE reports_to IS NULL;

-- or

SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1

-- 2. Which countries have the most Invoices?
SELECT billing_country, COUNT(*) AS invoice_count  
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC

-- 3. What are top 3 values of total invoice?
SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music 
--   Festival in the city we made the most money. Write a query that returns one city that 
--   has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
SELECT billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;

-- 5. Who is the best customer? The customer who has spent the most money will be 
--    declared the best customer. Write a query that returns the person who has spent the 
--    most money

-- without join
SELECT concat(first_name, last_name) as best_customer 
FROM customer 
WHERE customer_id IN (SELECT t.customer_id 
					  FROM (SELECT customer_id, sum(total) 
							FROM invoice 
							GROUP BY 1 ORDER BY 2 DESC LIMIT 1
						   ) t
					 );

-- with join
SELECT c.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY total_spending DESC
LIMIT 1;


/* Question Set - 2 (Moderate) */

-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music  
-- listeners. Return your list ordered alphabetically by email starting with A 

SELECT * FROM genre; -- we've 'Rock' and 'Rock And Roll' genres

-- without JOIN
SELECT email, first_name, last_name FROM customer whWHEREere customer_id IN (
SELECT DISTINCT customer_id FROM invoice WHERE invoice_id IN (
SELECT DISTINCT invoice_id FROM invoice_line WHERE track_id IN (
SELECT track_id FROM track WHERE genre_id in (
SELECT genre_id FROM genre WHERE name LIKE '%Rock%')))) 
ORDER BY email;  -- 59 rows

-- with JOIN
SELECT DISTINCT email, first_name, last_name, g.name
FROM customer c
INNER JOIN invoice i ON c.customer_id = i.customer_id
INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN track t ON il.track_id = t.track_id
INNER JOIN genre g ON t.genre_id = g.genre_id 
WHERE g.name LIKE '%Rock%'
ORDER BY c.email; -- 59 rows (not a optimize query, as we've utilises multiple JOINS)

-- with JOIN but an Optimised solution
SELECT DISTINCT email, first_name, last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
WHERE track_id IN (
	SELECT track_id FROM track t
	JOIN genre g ON t.genre_id = g.genre_id
	WHERE g.name LIKE 'Rock'
)
ORDER by email; -- 59 rows

-- 2. Let's invite the artists who have written the most rock music in our dataset.
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

-- 3. Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the
-- longest songs listed first

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds)
	FROM track )
ORDER BY milliseconds DESC;

/* Question Set - 3 (Advance) */

-- 1. Find how much amount spent by each customer on artists? Write a query to return
-- customer name, artist name and total spent

-- Customer -> Invoice -> Invoice_line -> Track -> Album -> Artist

SELECT CONCAT(c.first_name,c.last_name) customer_name, art.name artist_name, SUM(total)
fFROMrom customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album alb ON t.album_id = alb.album_id
JOIN artist art ON alb.artist_id = art.artist_id
GROUP BY c.customer_id,art.artist_id
ORDER BY 3 DESC; -- 2189 rows 

-----
-- Doing Some Research Work (although it is obvious from the ER Diagram)
select customer_id, invoice_id,total
from invoice where invoice_id = 1; -- contains 'total' which is price of different tracks club together)

select invoice_id, invoice_line_id, track_id, unit_price,quantity 
from invoice_line
where invoice_id = 1; -- unit_Price * quantity (we need this information)

select album_id, track_id, unit_price 
from track 
WHERE track_id in (
	select track_id
	from invoice_line
	where invoice_id = 1
)
order by album_id,track_id; -- all 16 track_ids for invoice_id = 1 belong to album_id = 91

SELECT artist_id, album_id 
from album 
order by artist_id; -- one artist can realease multiple albums, each album will contain many tracks
-------

-- Below query is calculating amount spent by each customer on the artists.

SELECT CONCAT(c.first_name,last_name) customer_Name, art.name artist_name,
	   SUM(il.unit_price * il.quantity)  amount_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album alb ON t.album_id = alb.album_id
JOIN artist art ON alb.artist_id = art.artist_id -- 4757 rows
GROUP BY c.customer_id,art.artist_id 
ORDER BY 3 DESC; --2189 rows


-- answer (below query is finding how much amount each customer has contributed in the best_selling_artist)

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

--2. We want to find out the most popular music Genre for each country. We determine the 
-- most popular genre as the genre with the highest amount of purchases. Write a query 
-- that returns each country along with the top Genre. For countries where the maximum 
-- number of purchases is shared return all Genres

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

-- 3. Write a query that determines the customer that has spent the most on music for each 
-- country. Write a query that returns the country along with the top customer and how
-- much they spent. For countries where the top amount spent is shared, provide all 
-- customers who spent this amount

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1


/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;