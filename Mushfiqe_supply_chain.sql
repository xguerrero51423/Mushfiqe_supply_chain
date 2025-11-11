/*  */



-- 1. Total Quantity Ordered Per Product Category
-- Show how much quantity was ordered for each product category.

SELECT p.category,
	SUM(o.quantity) AS total_quantity
FROM products p 
JOIN orders o
	ON p.product_id = o.product_id 
GROUP BY p.category
ORDER BY total_quantity DESC;


-- 2. Top 5 Suppliers by Quantity Supplied
-- Rank suppliers based on the total quantity they provided.

SELECT o.supplier_id,
	s.supplier_name,
	SUM(o.quantity) AS total_quantity_supplied,
	ROW_NUMBER() OVER(ORDER BY SUM(o.quantity) DESC) AS rank_quant
FROM orders o
JOIN suppliers s
	ON s.supplier_id = o.supplier_id 
GROUP BY o.supplier_id, s.supplier_name 
ORDER BY rank_quant
LIMIT 5;
	


-- 3. Average Delivery Delay per Vehicle Type
-- Calculate the average delay (in days) for each vehicle type.

SELECT v.vehicle_type,
	AVG(sub.delivery_delay) AS avg_delay_day
FROM  (
	SELECT 
		sh.vehicle_id,
		(sh.actual_delivery - sh.scheduled_delivery) AS delivery_delay
	FROM shipments sh
	WHERE sh.actual_delivery > sh.scheduled_delivery
	) AS sub
JOIN vehicles v
	ON v.vehicle_id = sub.vehicle_id 
GROUP BY v.vehicle_type;


-- 4. Products Ordered by Each Supplier (Grouped)
-- Display all products supplied by each supplier as a grouped list.

SELECT s.supplier_name,
       STRING_AGG(DISTINCT p.product_name, ', ' ORDER BY p.product_name) AS product_list
FROM suppliers s
JOIN orders o ON o.supplier_id = s.supplier_id
JOIN products p ON p.product_id = o.product_id
GROUP BY s.supplier_name;

-- 5. Orders with Late Delivery
-- Identify whether each order was delivered on time or late.

SELECT 
	sh.order_id,
	CASE
		WHEN sh.actual_delivery > sh.scheduled_delivery THEN 'late'
		ELSE 'on time'
	 END AS on_time_delivery
FROM shipments sh;
		

-- 6. Rolling 3-Order Average Delivery Cost per Vehicle
-- For each vehicle, show a rolling average of delivery cost over the last 3 shipments.

SELECT sub.vehicle_id,
	v.driver_name,
	ROUND(sub.three_day_avg::numeric,2),
	sub.order_date
FROM (
	SELECT 
		sh.vehicle_id,
		AVG(sh.delivery_cost) OVER(
			PARTITION BY sh.vehicle_id
			ORDER BY o.order_date 
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_day_avg,
		ROW_NUMBER() OVER(
			PARTITION BY sh.vehicle_id
			ORDER BY o.order_date DESC) AS last_three,
		o.order_date
	FROM orders o
	JOIN shipments sh
		USING(order_id)
	) AS sub
JOIN vehicles v 
	USING(vehicle_id)
WHERE last_three <= 3 
ORDER BY sub.vehicle_id, sub.order_date DESC;
	

-- 7. Monthly Delivery Cost per Product Category
-- Aggregate delivery cost by month and product category.

SELECT 
	TO_CHAR(sh.actual_delivery, 'YYYY-MM') AS delivery_month,
	p.category,
	SUM(sh.delivery_cost) AS total_delivery_cost
FROM orders o
JOIN products p
	ON p.product_id = o.product_id
JOIN shipments sh
	ON sh.order_id = o.order_id
GROUP BY delivery_month, p.category
ORDER BY p.category, delivery_month;
	
-- 8. Orders with Multiple Products
-- Find all orders that contain more than one product.

SELECT o.order_id,
	COUNT(o.product_id) AS product_count
FROM orders o
GROUP BY o.order_id 
HAVING COUNT(o.product_id) > 1;


-- 9. Most Frequently Used Vehicle Types
-- Rank vehicle types by how frequently they were used in shipments.

SELECT 
	v.vehicle_type,
	ROW_NUMBER() OVER(ORDER BY COUNT(sh.shipment_id) DESC) AS ship_freq,
	count(sh.shipment_id) AS shipment_count
FROM shipments sh
JOIN vehicles v
	USING(vehicle_id)
GROUP BY v.vehicle_type 
ORDER BY ship_freq;

-- 10. Supplier Delivery Performance Summary
-- Count total orders and number of late deliveries for each supplier.

SELECT 
	supplier_id,
	total_orders,
	late_delivery_count,
	ROUND((late_delivery_count::numeric/total_orders)*100,2) AS percentage_late
FROM (
	SELECT
		o.supplier_id,
		COUNT(sub.order_id) AS total_orders,
		SUM(sub.late_deliveries) AS late_delivery_count
	FROM (
		SELECT 
			sh.order_id,
			CASE
				WHEN sh.actual_delivery > sh.scheduled_delivery THEN 1
				ELSE 0
			 END AS late_deliveries
		FROM shipments sh
		) AS sub
	JOIN orders o
		USING(order_id)
	GROUP BY o.supplier_id
	) AS sub2
ORDER BY percentage_late DESC;
