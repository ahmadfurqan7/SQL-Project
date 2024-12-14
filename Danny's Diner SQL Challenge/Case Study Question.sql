/* --------------------
   Case Study Questions
   --------------------*/
SELECT * FROM dannys_diner.members;
SELECT * FROM dannys_diner.menu;
SELECT * FROM dannys_diner.sales;

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(price) as total_amount_spent
from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as num_days
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with cte as
(select s.customer_id, m.product_name,
ROW_NUMBER() OVER(PARTITION BY s.customer_id order by s.order_date) as row_num
from sales s
inner join menu m
on s.product_id = m.product_id)
select customer_id, product_name
from cte
where row_num = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) as purchased
from menu m
inner join sales s
on m.product_id = s.product_id
group by product_name
order by purchased desc
limit 1;

-- 5. Which item was the most popular for each customer?
with item_count as 
(select s.customer_id, m.product_name,
count(*) as order_count,
dense_rank() over(partition by s.customer_id order by count(*) desc) as popular
from sales s
inner join menu m
on s.product_id = m.product_id
group by s.customer_id, m.product_name)
select customer_id, product_name
from item_count
where popular = 1;

-- 6. Which item was purchased first by the customer after they became a member?
with orders as (select s.customer_id, m.product_name, s.order_date, mb.join_date,
Dense_rank () over(partition by s.customer_id order by order_date) as rn
from menu m
join sales s
on m.product_id = s.product_id
join members mb
on s.customer_id = mb.customer_id
where s.order_date > mb.join_date)
select customer_id, product_name 
from orders
where rn = 1;

-- 7. Which item was purchased just before the customer became a member?
with orders as (select s.customer_id, m.product_name, s.order_date, mb.join_date,
Dense_rank () over(partition by s.customer_id order by order_date desc) as rn
from menu m
join sales s
on m.product_id = s.product_id
join members mb
on s.customer_id = mb.customer_id
where s.order_date < mb.join_date)
select customer_id, product_name 
from orders
where rn = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, s.order_date, mb.join_date, 
count(m.product_id) as total_item_ordered,
sum(price) as total_amount_spent
from menu m
join sales s
on m.product_id = s.product_id
join members mb
on s.customer_id = mb.customer_id
where s.order_date < mb.join_date
group by s.customer_id, s.order_date, mb.join_date;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as
	(select s.customer_id, m.product_name, m.price,
    case
		when m.product_name = 'sushi' then m.price*10*2
        else m.price*10
        end as points
	from sales s
    join menu m
    on s.product_id = m.product_id)
select customer_id, sum(points) as total_points
from cte
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as (
select s.customer_id, m.product_name, m.price, order_date, join_date,
case
	when s.order_date between mb.join_date and dateadd(day, 7, mb.join_date) then m.price*10*2
    when product_name = 'sushi' then m.price*10*2
    else m.price*10
    end as points
from menu m
join sales s
on s.product_id = m.customer_id
join members mb
on s.customer_id = mb.customer_id
where order_date < '2021-02-01'
)
select customer_id, sum(points) as total_points
from cte
group by customer_id;

-- 11.  Determine the name and price of the product ordered by each customer on all order dates and find out whether
-- the customer was a member on the order date or not
select s.customer_id, s.order_date, m.product_name, m.price,
case
	when mb.join_date <= s.order_date then 'Y'
    else 'N'
    end as member_status
from menu m
join sales s
on s.product_id = m.product_id
left join members mb
on mb.customer_id = s.customer_id;

-- 12.  Rank the previous output from question no.11 based on the order date for each customer. Display null if customer
-- was not a member when dish was ordered
with cte as
(select s.customer_id, s.order_date, m.product_name, m.price,
case
	when mb.join_date <= s.order_date then 'Y'
    else 'N'
    end as member_status
from menu m
join sales s
on s.product_id = m.product_id
left join members mb
on mb.customer_id = s.customer_id)
select *,
case
	when cte.member_status =  'Y' then rank() over(partition by customer_id, member_status order  by order_date)
    else null
	end as ranking
from cte;