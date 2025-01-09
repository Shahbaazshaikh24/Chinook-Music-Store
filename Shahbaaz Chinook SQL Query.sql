-- OBJECTIVE QUESTIONS

-- Answer 1

SELECT * FROM album;

SELECT * FROM artist;

SELECT COUNT(*) FROM customer 
WHERE fax is NULL;

SELECT * from employee
WHERE reports_to is NULL; 

SELECT * FROM genre;

SELECT * FROM invoice;

SELECT * FROM invoice_line;

SELECT * FROM media_type;

SELECT * FROM playlist;

SELECT * FROM playlist_track;

SELECT COUNT(*) FROM track 
WHERE composer is NULL;


-- Answer 2

WITH most_famous_genre AS (
SELECT 
	t.name Top_selling_track, 
    a.name Top_artist, 
    g.name Top_genre, 
    SUM(t.unit_price * il.quantity) 
FROM 
	track t
LEFT JOIN 
	invoice_line il on t.track_id = il.track_id
LEFT JOIN 
	invoice i on i.invoice_id = il.invoice_id
LEFT JOIN 
	album al on al.album_id = t.album_id
LEFT JOIN 
	artist a on a.artist_id = al.artist_id
LEFT JOIN 
	genre g on g.genre_id = t.genre_id
WHERE 
	billing_country = "USA"
GROUP BY 
	t.name, a.name, g.name
ORDER BY 
	SUM(total) DESC
)
SELECT 
	Top_selling_track, 
    Top_artist, 
    Top_genre 
FROM 
	most_famous_genre
Limit 5;

-- Answer 3 
SELECT 
	country, count(customer_id) AS number_of_customers
FROM 
	customer
GROUP BY 1
ORDER BY 2 DESC;


SELECT 
	city, count(customer_id) AS number_of_customers
FROM 	
	customer
GROUP BY 1
ORDER BY 2 DESC;

-- Answer 4

SELECT 
	billing_city, billing_state, 
    billing_country, 
    COUNT(invoice_id) num_of_invoices, 
    SUM(total) total_revenue 
FROM
	invoice
GROUP BY
	1,2,3
ORDER BY 
	COUNT(invoice_id) DESC, SUM(total) DESC;


-- Answer 5

WITH cte AS(
SELECT 
	country, 
    first_name, 
    last_name, 
    SUM(t.unit_price * il.quantity) total_revenue 
FROM 
	customer c
LEFT JOIN 
	invoice i on i.customer_id = c.customer_id
LEFT JOIN 
	invoice_line il on il.invoice_id = i.invoice_id 
LEFT JOIN 
	track t on t.track_id = il.track_id
GROUP BY 1,2,3
ORDER BY country
),
cte2 AS(
SELECT 
	country, 
    first_name, 
    last_name,
	RANK() OVER(PARTITION BY country ORDER BY total_revenue DESC) `rank`
FROM cte
)
SELECT 
	country, 
    first_name, 
    last_name 
FROM 
	cte2
WHERE `rank` <= 5;


-- Answer 6 

SELECT 
	first_name, 
    last_name, 
    t.name Track_name, 
    SUM(quantity) Total_quantity FROM customer c
LEFT JOIN 
	invoice i on i.customer_id = c.customer_id
LEFT JOIN 
	invoice_line il on il.invoice_id = i.invoice_id
LEFT JOIN 
	track t on t.track_id = il.track_id
GROUP BY 1,2,3
ORDER BY SUM(quantity) DESC;

-- Answer 7

SELECT 
	customer_id, 
    COUNT(invoice_id) num_invoices, 
    AVG(total) avg_sales 
FROM 
	invoice
GROUP BY 1
ORDER BY 
	COUNT(invoice_id) DESC, AVG(total) DESC;


-- Answer 8 

SELECT
	((COUNT(DISTINCT CASE WHEN invoice_date BETWEEN '2017-01-01' AND '2017-03-31' THEN customer_id END) -
	COUNT(DISTINCT CASE WHEN invoice_date BETWEEN '2020-11-01'AND '2020-12-31' THEN customer_id END)) /
	COUNT(DISTINCT CASE WHEN invoice_date BETWEEN '2017-01-01' AND '2017-03-31' THEN customer_id END)) * 100 AS churn_rate
FROM 
	invoice;


------------------------------------------------------------------------------------------------------

-- Answer 9
WITH cte as(
	SELECT 
		SUM(total) total_revenue_for_USA 
	FROM 
		invoice
	WHERE 
		billing_country = 'USA'
),
genre_sales as(
	SELECT  
		g.genre_id, 
        g.name, 
        sum(t.unit_price * il.quantity) total_revenue_for_genre 
	FROM 
		track t
	LEFT JOIN 
		genre g on g.genre_id = t.genre_id
	LEFT JOIN 
		invoice_line il on il.track_id = t.track_id
	LEFT JOIN 
		invoice i on i.invoice_id = il.invoice_id
	WHERE billing_country = 'USA'
	GROUP BY 1,2 
	ORDER BY total_revenue_for_genre DESC
),
ranking as(
	SELECT 
		genre_id, 
		name, 
        ROUND(total_revenue_for_genre/(SELECT total_revenue_for_USA FROM cte) * 100,2) percentage_contribution,
		DENSE_RANK() OVER(ORDER BY ROUND(total_revenue_for_genre/(SELECT total_revenue_for_USA FROM cte) * 100,2) DESC) `rank` FROM genre_sales
)
SELECT 
	ranking.genre_id, 
	ranking.name genre_name, 
    a.name artist_name, 
    percentage_contribution, 
    `rank` FROM ranking
LEFT JOIN 
	track t on t.genre_id = ranking.genre_id
LEFT JOIN 
	album al on al.album_id = t.album_id
LEFT JOIN 
	artist a on a.artist_id = al.artist_id
GROUP BY 1,2,3,4;

-- Answer 10

SELECT
	CONCAT(c.first_name, ' ', c.last_name) AS name_of_customer, COUNT(DISTINCT g.name) AS total_genre
FROM 
	customer c
JOIN
	invoice i ON i.customer_id = c.customer_id
JOIN 
	invoice_line il ON il.invoice_id = i.invoice_id
JOIN
	track t ON t.track_id = il.track_id
JOIN 
	genre g ON g.genre_id = t.genre_id
GROUP BY 
	c.customer_id, name_of_customer
Having 
	COUNT(DISTINCT g.name) >= 3
ORDER By
	COUNT(DISTINCT g.name) DESC;

-- Answer 11

SELECT
	g.name, 
    SUM(t.unit_price * il.quantity) AS sale_performance,
    DENSE_RANK() OVER(ORDER By SUM(t.unit_price * il.quantity) DESC) AS `rank`
FROM 
	track t
LEFT JOIN 
	genre g ON g.genre_id = t.genre_id
LEFT JOIN 
	invoice_line il ON il.track_id = t.track_id
LEFT JOIN
	invoice i ON i.invoice_id = il.invoice_id
WHERE 
	i.billing_country = 'USA'
GROUP By
	g.genre_id, g.name
ORDER By 
	sale_performance DESC;

-- Answer 12

SELECT
	CONCAT(c.first_name, ' ' , c.last_name) AS name_of_customer
FROM 
	customer c
LEFT JOIN
	invoice i ON i.customer_id = c.customer_id
	AND i.invoice_date > (SELECT MAX(invoice_date) FROM invoice) - INTERVAL 3 MONTH
WHERE
	i.invoice_id IS NULL; 


-- SUBJECTIVE QUESTIONS

-- Answer 1

SELECT 
    g.genre_id, 
    g.name AS genre_name, 
    al.title AS album_name
FROM 
    genre g
JOIN 
    track t ON t.genre_id = g.genre_id
JOIN 
    album al ON al.album_id = t.album_id
JOIN 
    invoice_line il ON il.track_id = t.track_id
JOIN 
    invoice i ON i.invoice_id = il.invoice_id
LEFT JOIN 
    (SELECT 
         genre_id, 
         SUM(t.unit_price * il.quantity) AS total_revenue_for_genre
     FROM 
         track t
     LEFT JOIN 
         invoice_line il ON il.track_id = t.track_id
     LEFT JOIN 
         invoice i ON i.invoice_id = il.invoice_id
     WHERE 
         i.billing_country = 'USA'
     GROUP BY 
         genre_id
     ORDER BY 
         total_revenue_for_genre DESC
     LIMIT 1) genre_sales ON genre_sales.genre_id = g.genre_id
WHERE 
    genre_sales.total_revenue_for_genre IS NOT NULL
GROUP BY 
    g.genre_id, g.name, al.title
ORDER BY 
    genre_sales.total_revenue_for_genre DESC
LIMIT 3;


-- Answer 2

SELECT  
	g.genre_id, 
    g.name, 
    sum(t.unit_price * il.quantity) total_revenue_for_genre 
FROM 
	track t
LEFT JOIN 
	genre g on g.genre_id = t.genre_id
LEFT JOIN 
	invoice_line il on il.track_id = t.track_id
LEFT JOIN 
	invoice i on i.invoice_id = il.invoice_id
WHERE billing_country != 'USA'
GROUP BY 1,2
ORDER BY total_revenue_for_genre DESC;

-- Answer 3
 
 WITH cte AS(
	SELECT 
		i.customer_id, 
        MAX(invoice_date), 
        MIN(invoice_date), 
        abs(TIMESTAMPDIFF(MONTH, MAX(invoice_date), MIN(invoice_date))) AS time_for_each_customer, 
        SUM(total) sales, 
        SUM(quantity) items, 
        COUNT(invoice_date) AS frequency 
	FROM invoice i
	LEFT JOIN 
		customer c on c.customer_id = i.customer_id
	LEFT JOIN 
		invoice_line il on il.invoice_id = i.invoice_id
	GROUP BY 1
	ORDER BY time_for_each_customer DESC
),
average_time AS (
	SELECT AVG(time_for_each_customer) average 
    FROM cte
),
categorization AS (
	SELECT *,
		CASE WHEN time_for_each_customer > (SELECT average from average_time) THEN "Long-term Customer" ELSE "Short-term Customer" END AS category
	FROM cte
)
SELECT 
	category, 
	SUM(sales) total_spending, 
    SUM(items) basket_size, 
    COUNT(frequency) frequency 
FROM categorization
GROUP BY 1;

 -- Answer 4
 
WITH cte as(
	SELECT 
		invoice_id, 
        COUNT(DISTINCT g.name) AS num 
	FROM 
		invoice_line il
	left JOIN 
		track t on t.track_id = il.track_id
	left JOIN 
		genre g on  g.genre_id = t.genre_id
	GROUP BY 1 HAVING COUNT(DISTINCT g.name) > 1
)
SELECT 
	cte.invoice_id, 
    num, 
    g.name 
FROM cte
left JOIN 
	invoice_line il on il.invoice_id = cte.invoice_id
left JOIN 
	track t on t.track_id = il.track_id
left JOIN 
	genre g on  g.genre_id = t.genre_id
GROUP BY 1,2,3;

WITH cte as(
	SELECT 
		invoice_id, 
		COUNT(DISTINCT al.title) AS num 
	FROM 
		invoice_line il
	left JOIN track t on t.track_id = il.track_id
	left JOIN album al on al.album_id = t.album_id
	GROUP BY 1 HAVING COUNT(DISTINCT al.title) > 1
)
SELECT 
	cte.invoice_id, 
	num, 
    al.title 
FROM cte
left JOIN 
	invoice_line il on il.invoice_id = cte.invoice_id
left JOIN 
	track t on t.track_id = il.track_id
left JOIN 
	album al on  al.album_id = t.album_id
GROUP BY 1,2,3;

WITH cte as(
	SELECT 
		invoice_id, 
        COUNT(DISTINCT a.name) AS num 
	FROM invoice_line il
	left JOIN 
		track t on t.track_id = il.track_id
	left JOIN 
		album al on al.album_id = t.album_id
	left join 
		artist a on a.artist_id = al.artist_id
	GROUP BY 1 HAVING COUNT(DISTINCT a.name) > 1
)
SELECT 
	cte.invoice_id, 
    num, 
    a.name 
FROM cte
left join 
	invoice_line il on il.invoice_id = cte.invoice_id
left JOIN 
	track t on t.track_id = il.track_id
left JOIN 
	album al on  al.album_id = t.album_id
left join 
	artist a on a.artist_id = al.artist_id
GROUP BY 1,2,3;

-- Answer 5

WITH num_cust_in_1st_3months as
(
SELECT billing_country, COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
GROUP BY 1
),
num_cust_in_last_2months as
(
SELECT billing_country, COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
GROUP BY 1
)
SELECT n1.billing_country, (ttl - COALESCE(l_num,0))/ttl * 100 churn_rate FROM num_cust_in_1st_3months n1
LEFT JOIN  num_cust_in_last_2months n2 on n1.billing_country = n2.billing_country
;

WITH num_cust_in_1st_3months as
(
SELECT billing_city, COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
GROUP BY 1
),
num_cust_in_last_2months as
(
SELECT billing_city, COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
GROUP BY 1
)
SELECT n1.billing_city, (ttl - COALESCE(l_num,0))/ttl * 100 churn_rate FROM num_cust_in_1st_3months n1
LEFT JOIN  num_cust_in_last_2months n2 on n1.billing_city = n2.billing_city
;

WITH num_cust_in_1st_3months as
(
SELECT billing_state, COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
GROUP BY 1
),
num_cust_in_last_2months as
(
SELECT billing_state, COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
GROUP BY 1
)
SELECT n1.billing_state, (ttl - COALESCE(l_num,0))/ttl * 100 churn_rate FROM num_cust_in_1st_3months n1
LEFT JOIN  num_cust_in_last_2months n2 on n1.billing_state = n2.billing_state
;


SELECT billing_country, COUNT(invoice_id) num_invoices, AVG(total) avg_sales FROM invoice
GROUP BY 1
ORDER BY COUNT(invoice_id) DESC, AVG(total) DESC;


-- Answer 6

SELECT 
	i.customer_id, 
    CONCAT(first_name, " ", last_name) name, 
    billing_country, 
    invoice_date, 
    SUM(total) total_spending, 
    COUNT(invoice_id) num_of_orders 
FROM 
	invoice i
LEFT JOIN 
	customer c on c.customer_id = i.customer_id
GROUP BY 1,2,3,4
ORDER BY name;

-- Answer 11

SELECT 
	billing_country, 
	COUNT(DISTINCT customer_id) num_of_customers, 
	AVG(total) Average_total_amount, 
	COUNT(track_id) num_of_tracks 
FROM 
	invoice i
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
GROUP BY 1 
;

SELECT 
	customer_id, 
    COUNT(DISTINCT track_id) num_of_tracks_per_customer 
FROM 
	invoice i
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
GROUP BY 1;