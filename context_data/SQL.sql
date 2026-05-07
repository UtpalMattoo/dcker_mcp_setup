
69, 86, 87, 41, 54, 57, 58, 65, 66, 67, 119, 113,110, 106, 105, 124

1)

# Get the earliest login date for a user
# Then for each such first (or earliest) login date, find the number of total 
  users who logged within 90 days prior to this earliest login date

https://leetcode.com/problems/new-users-daily-count/description/
1107. New Users Daily Count


With CTE1 As
(
    Select user_id,
           min(activity_date) as login_date

    From Traffic

    Where activity = 'login'

    Group By user_id

    Order By user_id asc
)

Select login_date,

       count(user_id) as user_count

From CTE1 

Where login_date 
                between                 
                
                DATE_SUB('2019-06-30', INTERVAL 90 DAY) and '2019-06-30' 

Group By login_date

2)

2020. Number of Accounts That Did Not Stream
https://leetcode.com/problems/number-of-accounts-that-did-not-stream/description/


Select count(sub.account_id) as accounts_count
From Subscriptions sub 
     Left Join Streams str
     On sub.account_id = str.account_id
Where YEAR(sub.start_date) <= '2021'  #had an active subscription in 2021 (bought before or in 2021)     
      and YEAR(sub.end_date) >= '2021'
      and YEAR(str.stream_date) <> '2021'
	  
3)

2066. Account Balance
https://leetcode.com/problems/account-balance/description/

With cte as 
(
    Select 
        account_id,
        day,
        type,
        CASE 
                When type = 'Deposit' Then amount
                When type = 'Withdraw' Then -1 * amount
        END amount#,
        #row_number() Over() as row_num
    From Transactions
    Order by day asc
)

Select 
       account_id,
       day,
       sum(amount) over(Partition By account_id Order By day asc) as balance
From CTE
Group By account_id, day # this is redundant 

4)

1709. Biggest Window Between Visits
https://leetcode.com/problems/biggest-window-between-visits/description/

With CTE1 as
(
    Select user_id,
        visit_date,
        dense_rank() over(Partition By user_id Order By visit_date desc) dr
    From
    (
        Select distinct user_id, 
            '2021-1-1' as visit_date
        From UserVisits 

        Union 

        Select user_id, 
            visit_date
        From UserVisits
    ) x
    Order By user_id asc, visit_date desc
)

Select a.user_id, 
       max(DATEDIFF(a.visit_date, b.visit_date)) as biggest_window
From CTE1 a 
     Inner Join CTE1 b
     On b.dr = a.dr + 1
Where a.user_id = b.user_id
Group By a.user_id

5)

https://leetcode.com/problems/evaluate-boolean-expression/description/
1440. Evaluate Boolean Expression


SELECT  
        *       
        /*E.*,
        CASE E.operator
            WHEN ">" THEN IF(V1.value > V2.value, "true", "false")
            WHEN "=" THEN IF(V1.value = V2.value, "true", "false")
            WHEN "<" THEN IF(V1.value < V2.value, "true", "false")
        END AS value     */   

FROM Expressions E 

    Inner JOIN Variables V1
     ON E.left_operand=V1.name and 
        E.right_operand = V1.name

6)

https://leetcode.com/problems/product-sales-analysis-iv/description/
2324. Product Sales Analysis IV


With CTE as
(
    Select 
        
        s.user_id, 
        s.product_id, 
        sum(s.quantity * p.price) as 'total_spent'

    From Sales s
        Inner Join Product p
        On s.product_id = p.product_id 

    Group By s.user_id, s.product_id

    Order By user_id asc, total_spent desc #no need to order
),

CTE_1 as 
(
    Select user_id,
        product_id,
        total_spent,
        dense_rank() over(order by total_spent desc) as rnum
    From CTE
    
)

Select x.user_id,
       x.product_id
From CTE_1 x
        Inner Join 
                (
                    Select user_id, 
                           min(rnum) as r_num
                    From CTE_1
                    Group By user_id
                ) y
        On x.user_id = y.user_id and 
           x.rnum = y.r_num
		   


With CTE as
(
    Select 
        
        s.user_id, 
        s.product_id, 
        sum(s.quantity * p.price) as 'total_spent'

    From Sales s
        Inner Join Product p
        On s.product_id = p.product_id 

    Group By s.user_id, s.product_id

    Order By user_id asc, total_spent desc
),

CTE_1 as 
(
    Select user_id,
        product_id,
        total_spent,
        dense_rank() over(order by total_spent desc) as rnum
    From CTE    
)

Select x.user_id, 
       x.product_id
From CTE x
     Inner Join (
         Select user_id, 
                max(total_spent) as max_spent
         From CTE
         Group By user_id
     ) y
     On x.user_id = y.user_id and x.total_spent = y.max_spent


		   
7)

https://leetcode.com/problems/tree-node/description/
608. Tree Node

Select N, 
       Type
From 
(
        # Root has NULL parent
        
        Select N, 
              'Root' as Type
        From Tree
        Where P is null
        
        Union 

        # Inner shows up in both nodes

        Select N, 'Inner' as Type
        From Tree
        Where N in (Select P From Tree) and 
              P is not null # an inner node will not have a null parent

        # Leaf does not show up in parent
        
        #1,3,6
        
        Union
        
        Select  N, 
               'Leaf' as Type
        From Tree 
        Where N not in 
            (
                Select  N
                From Tree
                Where N in (Select P from Tree) # a leaf not is not a parent
            ) 
            and P is not null

) x

Order By x.N asc


8)

https://leetcode.com/problems/game-play-analysis-iii/description/
534. Game Play Analysis III

Query 1:
========

Select player_id,
       event_date,
       sum(games_played) Over (partition by player_id Order By event_date) games_played_so_far
From Activity 

Query 2:
SELECT player_id,
       event_date,
       SUM(games_played) AS total_games_played
FROM Activity
GROUP BY player_id, event_date
ORDER BY player_id, event_date;

'''
Difference Between the Two Approaches:

    Cumulative Total:
        Window Function: It computes a cumulative total across rows, which accumulates over time.
        GROUP BY: It does not compute a cumulative sum. It just gives the sum for each player_id and event_date separately.

    Row-Level Calculation:
        Window Function: The calculation is done at the row level, and the result is based on all the previous rows (within the partition) up to the current row.
        GROUP BY: The calculation happens per group, so each group will just be summed independently without the cumulative effect.
'''


/*
Wrong approach:

In most standard SQL implementations, the ORDER BY clause within a subquery that is used in the SELECT list 
(and is not a window function) does not guarantee the order in which the rows are processed by the aggregate function (SUM() in this case). 
The ORDER BY in such a subquery is mainly relevant if you are using functions like LIMIT or if the database optimizer happens to use the order 
for some internal optimization (which is not guaranteed to affect the final aggregated sum).

To achieve a running total from the latest date backwards, you would need to rethink the subquery logic or use a window function with a different ordering.
Select a.player_id,
       a.event_date,
       (
           Select ifnull(sum(b.games_played),0)
           From Activity b 
           Where  b.player_id = a.player_id and a.event_date <= b.event_date 
           Group By b.player_id
       ) as games_played_so_far
From Activity a 
Group By a.player_id, a.event_date
Order By a.player_id asc,a.event_date desc

🟥 Important: You cannot make a running total by trying to force SUM to operate in a certain order.

If you want:

a running total

a backward running total

cumulative sums

rolling windows

Then you must use:

➤ a window function

or

➤ a different query design

Because SUM() by itself always ignores order.

*/

9)

1285. Find the Start and End Number of Continuous Ranges
https://leetcode.com/problems/find-the-start-and-end-number-of-continuous-ranges/description/

# Find the Start and End Number of Continuous Ranges
# row_number(), rank(), dense_rank()

Select min(log_id) as start_id,
       max(log_id) as end_id
From 
(
    Select log_id,
        rank() Over(Order By log_id) as den_rank,
        log_id - (rank() Over(Order By log_id)) diff
    From Logs
) x
Group By x.diff
Order By start_id asc


# COMMENT

What really happens

When SQL evaluates a SELECT list:

SELECT
    log_id,
    RANK() OVER (ORDER BY log_id) AS den_rank,
    log_id - den_rank AS diff
FROM Logs;


Step 1: SQL evaluates all expressions in the SELECT list at the same time.

Step 2: Aliases (den_rank) are assigned after all expressions are evaluated.

So when SQL reaches:

log_id - den_rank


the alias den_rank does not yet exist.
Step 1: SQL evaluates all expressions in the SELECT list at the same time.

Step 2: Aliases (den_rank) are assigned after all expressions are evaluated.

This is a logical processing rule, not a performance thing — the database could internally compute RANK once, but the SQL language forbids referencing the alias in the same SELECT list.

#To reuse a window function, you must use a CTE or subquery - otherwise just repeat the Windows function 

 ┌─────────────────────────┐
 │        FROM             │
 │  (tables joined first)  │
 └────────────┬────────────┘
              │
 ┌────────────▼────────────┐
 │        WHERE            │
 │  (filter rows)          │
 └────────────┬────────────┘
              │
 ┌────────────▼────────────┐
 │       GROUP BY          │
 │  (aggregate groups)     │
 └────────────┬────────────┘
              │
 ┌────────────▼────────────┐
 │       HAVING            │
 │  (filter aggregates)    │
 └────────────┬────────────┘
              │
 ┌────────────▼────────────┐
 │   WINDOW FUNCTIONS      │
 │ RANK(), ROW_NUMBER(),   │
 │ SUM() OVER (...)        │
 │ (evaluated per row)     │
 └────────────┬────────────┘
              │
 ┌────────────▼────────────┐
 │         SELECT          │
 │  (aliases created here) │
 │  Can use window results │
 └────────────┬────────────┘
              │
 ┌────────────▼────────────┐
 │        ORDER BY         │
 │  (can use SELECT aliases│
 │   and window results)   │
 └─────────────────────────┘
"
    Alias Restriction: While the total_votes value is calculated before the ranking, you cannot use the alias (total_votes) directly 
	inside the window function's ORDER BY clause because window functions are logically executed before the final SELECT list aliases 
	are resolved (unless you are using a subquery or CTE).	
"

10)

1270. All People Report to the Given Manager
https://leetcode.com/problems/all-people-report-to-the-given-manager/description/

######################### Option 1 ######################

With CTE1 as 
(
    Select employee_id #direct 2, 77
    From Employees 
    where manager_id = 1 and 
          employee_id <> 1
),

#2
CTE2 as 
(
    Select e1.employee_id 
    From Employees e1         
        Inner Join Employees e2
        On e1.manager_id = e2.employee_id
    Where e2.employee_id <> 1 and 
          e2.manager_id = 1 
),

CTE3 as 
(
    Select e1.employee_id
    From Employees e1
         Inner Join CTE2 as c
         On e1.manager_id = c.employee_id
)

Select employee_id 
From CTE1

Union

Select employee_id
From CTE2

Union 

Select employee_id
From CTE3


/*
######################### Option 2 ######################

Select  e3.employee_id        
From
    (
        Select e2.employee_id 
        From
        (
            Select employee_id
            From Employees 
            Where manager_id = 1 
        ) x
        Inner Join Employees e2
        On x.employee_id = e2.manager_id
    ) y
    Inner Join Employees e3
    On y.employee_id = e3.manager_id

Where e3.employee_id <> 1

*/


/*

######################### Option 3 ######################

With CTE1 AS
(
    Select employee_id # (1, 2, 77)
    From Employees 
    Where manager_id = 1 
),

CTE2 AS
(
    Select e.employee_id # (4)
    From CTE1 c
         Inner Join Employees e
    Where e.manager_id = c.employee_id 
),

CTE3 AS
(
    Select e.employee_id # (4)
    From CTE2 c
         Inner Join Employees e
    Where e.manager_id = c.employee_id 
)

Select * 
From CTE3
Where employee_id <> 1
*/

/*
Option 4:

WITH RECURSIVE HierarchyCTE AS (
    -- Anchor Member (Finds the Head and sets their level to 0)
    SELECT
        employee_id,
        manager_id,
        0 AS level
    FROM
        Employees
    WHERE
        employee_id = manager_id -- Assumes the head manages themselves

    UNION ALL

    -- Recursive Member (Joins the previous level to find the next level down)
    SELECT
        e.employee_id,
        e.manager_id,
        h.level + 1 AS level
    FROM
        Employees e
    INNER JOIN
        HierarchyCTE h ON e.manager_id = h.employee_id
)

SELECT
    employee_id
FROM
    HierarchyCTE
WHERE
    level BETWEEN 1 AND 3; -- Selects employees at Level 1, 2, and 3
*/
11)

# https://leetcode.com/problems/employee-bonus/description/
577. Employee Bonus

Select e.name,
       b.bonus
      
From Employee e
     Left Join Bonus b 
     On e.empId = b.empId
 
Where COALESCE(b.bonus, 0 ) < 1000

12)

https://leetcode.com/problems/rising-temperature/description/
197. Rising Temperature

Select w2.id

From Weather w1, Weather w2     

Where w2.temperature > w1.temperature and 
      #w2.recordDate > w1.recordDate and 
      DATEDIFF(w2.recordDate, w1.recordDate) = 1
	  
Select w2.id

From Weather w1 
     Inner Join Weather w2
     On w2.recordDate = w1.recordDate + 1

Where w2.temperature > w1.temperature 
	  
13)

#https://leetcode.com/problems/customer-who-visited-but-did-not-make-any-transactions/description/
1581. Customer Who Visited but Did Not Make Any Transactions

Select customer_id,
       SUM(IF(t.transaction_id is null, 1, 0)) as count_no_trans

From Visits v 
     Left Join Transactions t 
     On v.visit_id = t.visit_id

Where t.transaction_id is null

Group By customer_id

14)

https://leetcode.com/problems/product-sales-analysis-i/description/
1068. Product Sales Analysis I


Select p.product_name, 
       s.year, 
       s.price

From Product p
     Left Join Sales s
     On p.product_id = s.product_id

Where s.year is not null and 
      s.price is not null

15)

https://leetcode.com/problems/replace-employee-id-with-the-unique-identifier/description/
1378. Replace Employee ID With The Unique Identifier

Select e2.unique_id,
       e1.name

From Employees e1 
     Left Join EmployeeUNI e2
     On e1.id = e2.id
	 
16)
https://leetcode.com/problems/invalid-tweets/description/
1683. Invalid Tweets

Select tweet_id
From Tweets
Where length(content) > 15

Function	Clause for Filtering	Reason
Scalar (e.g., length(), DATE(), UPPER())	WHERE	Operates on individual rows.
Aggregate (e.g., SUM(), COUNT(), AVG())	HAVING	Operates on groups of rows after aggregation.

17)

https://leetcode.com/problems/article-views-i/description/
1148. Article Views I

Select distinct author_id as id # the source table has duplicates and we did not remove dups before returning result
From Views 
Where author_id = viewer_id
Order By id asc

18)

https://leetcode.com/problems/big-countries/description/
595. Big Countries

Select name, population, area
From World
Where area >= 3000000 Or
      population >= 25000000
	  
19)
https://leetcode.com/problems/find-customer-referee/description/
584. Find Customer Referee

Select name
From Customer
where COALESCE(referee_id, 0) <> '2' # as long as you know that 0 has no meaning as a column value

20)

https://leetcode.com/problems/recyclable-and-low-fat-products/description/
1757. Recyclable and Low Fat Products

Select product_id
From Products
Where low_fats = 'Y' and 
      recyclable = 'Y'
	  
21)

https://leetcode.com/problems/product-sales-analysis-iii/description/
1070. Product Sales Analysis III


Select #s.sale_id, 
       s.product_id, 
       x.first_year, 
       s.quantity, 
       s.price
From Sales s
     Inner Join 
     (       
        Select product_id, 
               min(year) as first_year
        From Sales
        Group By product_id
     ) x
     On s.product_id = x.product_id and 
        s.year = x.first_year 
		
22)

https://leetcode.com/problems/tree-node/description/
608. Tree Node

Select 
      id,
     'Root' as type
From Tree
Where p_id is null

Union 

#Both a parent and child node
Select distinct t1.id, 'Inner'
From Tree t1


     Inner Join Tree t2
     On t1.id = t2.p_id
Where t1.p_id is not null

Union 

Select id,
       'Leaf'
From Tree
Where id not in 
(
    Select id
    From Tree
    Where id in (Select p_id From Tree) # nodes that are also parents
)
and p_id is not null

Select id, 'Leaf'
From Tree
Where id not in (Select p_id From Tree)

23)

https://leetcode.com/problems/customers-who-bought-all-products/description/
1045. Customers Who Bought All Products

Select x.customer_id
From 
    ( 
        Select customer_id, 
               count(distinct product_key) as num_prod
        From Customer
        Group By customer_id
    ) x 
Where x.num_prod = (Select count(distinct(product_key)) From Product)

/*
	SELECT customer_id
	FROM Customer
	GROUP BY customer_id
	HAVING COUNT(DISTINCT product_key) = (SELECT COUNT(DISTINCT product_key) FROM Product);
	
1. Typical use of HAVING

HAVING is designed to filter groups created by GROUP BY.

Example:

SELECT customer_id, COUNT(*)
FROM Orders
GROUP BY customer_id
HAVING COUNT(*) > 5;


GROUP BY creates one group per customer_id.

HAVING filters groups where the count of orders is greater than 5.

✅ This is the standard pattern.

2. HAVING without GROUP BY

Technically, SQL allows HAVING without a GROUP BY. In that case, the entire table is treated as a single group.

Example:

SELECT COUNT(*) AS total_orders
FROM Orders
HAVING COUNT(*) > 100;


There’s no GROUP BY, but SQL treats all rows as one group.

HAVING filters based on an aggregate applied to this single group.

This is rarely used, because in practice, people usually want to filter per group (per customer, per product, etc.).

✅ Key takeaway

HAVING must be applied to aggregates (COUNT, SUM, AVG, etc.).

Usually paired with GROUP BY to filter each group.

Without GROUP BY, HAVING still works, but it applies to the whole table as one group.
*/
24)

https://leetcode.com/problems/capital-gainloss/description/
1393. Capital Gain/Loss

Select stock_name,
       sum(total_gained) as capital_gain_loss
From
    (
        Select stock_name,
               (-1 * sum(price)) as total_gained
        From Stocks
        Where operation = 'Buy'
        Group By stock_name

        Union

        Select stock_name,
               sum(price) as total_gained
        From Stocks
        Where operation = 'Sell'
        Group By stock_name
    ) x
Group By stock_name

25)
https://leetcode.com/problems/friend-requests-ii-who-has-the-most-friends/description/
602. Friend Requests II: Who Has the Most Friends

 Select id,
        sum(num_friends) as num
        From 
            (
                Select requester_id as id, 
                    count(requester_id) as num_friends
                From RequestAccepted
                Group By requester_id

                Union All

                Select accepter_id as id, 
                    count(accepter_id) as num_friends
                From RequestAccepted
                Group By accepter_id
            ) x
        Group By id
        Order By num desc
        Limit 1

26)

https://leetcode.com/problems/movie-rating/description/
1341. Movie Rating


Select name as 'results'
From 
(
    Select u.name , mr.user_id,  count(mr.movie_id) as num_reviews
    From MovieRating mr
        Inner Join Users u
        On mr.user_id = u.user_id
    Group By mr.user_id
    Order By num_reviews desc, u.name asc
    Limit 1
) x


Union All


Select title as 'results'
From
(
    Select m.title, avg(mr.rating) as avg_rating #, mr.user_id,  count(mr.movie_id) as num_reviews
    From MovieRating mr
        Inner Join Movies m
        On mr.movie_id = m.movie_id
    Where Month(mr.created_at) = '2' and 
        Year(mr.created_at) = '2020'
    Group By m.movie_id
    Order By avg_rating desc, m.title asc
    Limit 1
) y


27)

https://leetcode.com/problems/investments-in-2016/description/
585. Investments in 2016


Query 1:
Select round(sum(tiv_2016),2) as tiv_2016
From Insurance i 
Where i.tiv_2015 in 
    (
        Select distinct x.tiv_2015
        From Insurance x 
        Where i.pid <> x.pid
    )
    and 
    (i.lat, i.lon) not in
    (
        Select distinct 
                x.lat, 
                x.lon
        From Insurance x
        Where i.pid <> x.pid
    )

Query 2:

With CTE1 as 
(
    Select i.pid, 
           i.tiv_2015, 
           i.tiv_2016, 
           i.lat, 
           i.lon
    From Insurance i 
         Inner Join Insurance j 
         On i.tiv_2015 = j.tiv_2015
    Where i.pid <> j.pid
)

    Select round(sum(tiv_2016),2) as tiv_2016
    From Insurance i
         Inner Join CTE1 as c1
         On i.tiv_2015 = c1.tiv_2015
    Where i.pid <> c1.pid and 
          (
            i.lat <> c1.lat or 
            i.lon <> c1.lon
          )
		  
28)

https://leetcode.com/problems/game-play-analysis-iv/description/
550. Game Play Analysis IV


Select  round
            ( 
               y.con_days
               /
               (Select count(distinct player_id) From Activity)
               ,
                2
            ) as fraction            
From 
    (
        Select count(distinct a.player_id) as 'con_days'
        From Activity a 
            Inner Join 
                (
                    Select player_id,
                        min(event_date) as event_date
                    From Activity
                    Group By player_id
                ) b
                On a.player_id = b.player_id
        Where DATEDIFF(a.event_date, b.event_date) = 1 #dont change order or a and b, unless you use absolute value for 1
    ) y


29)

https://leetcode.com/problems/managers-with-at-least-5-direct-reports/description/
570. Managers with at Least 5 Direct Reports

Select name 
From Employee e
     Inner Join 
     (
            Select managerId, 
                count(id) as num_reports
            From Employee 
            Where managerId in
                    ( 
                        #get just the managerID and their names
                        Select distinct managerId
                        From Employee
                        Where managerId is not null
                    ) 
            Group By managerId
            Having count(id) >= 5
     ) x
     On
     e.id = x.managerId
Order By name asc


this query will work but is less efficient and harder to follow

Select e.name 
From Employee e
     Inner Join 
     (
            Select e.managerId, 
                count(distinct e.id) as num_reports
            From 
                Employee e
                Inner Join 
                    (
                        Select distinct managerId
                        From Employee
                        Where managerId is not null
                    ) x
                On e.managerId = x.managerId

            Where e.managerId is not null
            Group By e.managerId
            Having count(distinct e.id) >= 5
     ) y
     On e.managerId = y.managerId
	 
	 
30)

https://leetcode.com/problems/rank-scores/description/
178. Rank Scores

Select #id, 
       score,
       #row_number() over (order by score desc ) row_num,
       #RANK() over (order by score desc) rnak,
       DENSE_RANK() over (order by score desc) 'dense_rank'
From Scores
Order By score desc

31)

https://leetcode.com/problems/second-highest-salary/description/
176. Second Highest Salary

Select max(salary) as SecondHighestSalary
From Employee
Where salary not in 
(
    Select max(salary)
    From Employee
)


32)

https://leetcode.com/problems/employees-whose-manager-left-the-company/description/
1978. Employees Whose Manager Left the Company


Select employee_id 
From Employees 
Where manager_id not in # the manager was deleted
    (
        Select distinct employee_id
        From Employees
    )
    and 
    salary < 30000
Order By employee_id asc


33)

https://leetcode.com/problems/average-time-of-process-per-machine/description/
1661. Average Time of Process per Machine

With CTE_1 as
(
    Select a.machine_id,
        a.process_id,
        (b.timestamp - a.timestamp) processing_time
    From Activity a 
        Inner Join Activity b 
        On a.process_id = b.process_id and 
            a.machine_id = b.machine_id
    Where b.activity_type = 'end' and 
          a.activity_type = 'start'
          #b.timestamp > a.timestamp
    Group By a.machine_id, a.process_id
)

/*
Select *
From CTE_1
*/


Select a.machine_id,
       round(avg(a.processing_time),3) as processing_time
From CTE_1 a
     Inner Join CTE_1 b
     On a.machine_id = b.machine_id
#Where a.process_id <> b.process_id
Group By a.machine_id

34)

https://leetcode.com/problems/list-the-products-ordered-in-a-period/description/
1327. List the Products Ordered in a Period

Select 
       p.product_name, 
       sum(o.unit) as 'unit'

From Orders o
     Left Join Products p
     On o.product_id = p.product_id

Where Month(o.order_date) = '2' and 
      Year(o.order_date) = '2020' #and 
      #p.product_id is not null
     
Group By p.product_name

Having sum(o.unit) >= 100



Select 
       p.product_name, 
       sum(o.unit) as 'unit'

From Orders o
     Left Join Products p
     On o.product_id = p.product_id

Where Month(o.order_date) = '2' and 
      Year(o.order_date) = '2020' #and 
      #p.product_id is not null
     
Group By p.product_name

Having sum(o.unit) >= 100

36)

https://leetcode.com/problems/leetflex-banned-accounts/description/
1747. Leetflex Banned Accounts

Select distinct L1.account_id /*,
       
       L1.ip_address as 'L1.ip_address',

       L2.ip_address as 'L2.ip_address',

       L2.logout as L2_logout,

       L2.login  as L2_login,       

       CASE
            When L2.login <= L1.logout Then 'Yes'
            ELSE 'No'
       END 'L2.login <= L1.logout' */

From LogInfo L1 

     Inner Join LogInfo L2

     On L1.account_id = L2.account_id

Where  L1.ip_address <> L2.ip_address

      and L2.login <= L1.logout    #  overlap in time 

      and L1.login <= L2.logout  

      # what this means ---> login happen first and then logouts happen - so there is an overlap in time	  

      #and L1.account_id = 1

#Having count(*) > 1

37)

https://leetcode.com/problems/find-interview-candidates/description/
1811. Find Interview Candidates

WITH cte_medal AS (
SELECT contest_id, gold_medal as user_id, 'gold' AS medal_type
FROM Contests
UNION ALL
SELECT contest_id, silver_medal as user_id, 'silver' AS medal_type
FROM Contests
UNION ALL
SELECT contest_id, bronze_medal as user_id, 'bronze' AS medal_type
FROM Contests
)

Select * 
from cte_medal

/*

With CTE as 
(
	Select contest_id,
		   gold_medal as user_id,
		   'gold' as medal_type
	From Contests 

	Union 

	Select contest_id, 
		   silver_medal as user_id, 
		   'silver' as medal_type
	From Contents

	Union 

	Select contest_id, 
		   bronze_medal as user_id, 
		   'bronze' as medal_type
	From Contents
)

# won gold in three or more distinct contests
CTE1 as 
(
	Select user_id,
		   count(user_id) as num_medals	 
    
	From CTE

	Where medal_type = 'gold'

	Group By user_id

	Having count(user_id) >= 3

)
#The user won any medal in three or more consecutive contests.
# question: use row_number() instead or will either work because a player will not be in more than one contest at the same time
CTE2
(
	Select user_id,
		   dense_rank() over(partition by user_id order by contest_id asc) as dr 
	From CTE
)

# complete the rest by doing a union and then Users table
     


*/

38)

https://leetcode.com/problems/the-most-recent-three-orders/description/
1532. The Most Recent Three Orders

Select c.name as customer_name,
       x.customer_id,
       x.order_id,
       x.order_date
From
(
        Select order_id, 
            order_date,
            customer_id,
            cost,
            RANK() OVER(Partition By customer_id Order By order_date desc) as rnk
        From Orders
) x Left Join Customers c
    On x.customer_id = c.customer_id
Where x.rnk <= 3
Order By c.name asc, 
         x.customer_id asc, 
         x.order_date desc

think of RANK() vs ROW_NUMBER() vs DENSE_RANK() 
--- DENSE_RANK() will give one rank to all orders on the same date within the same partition
--- ROW_NUMBER will increment for all orders on the same date within the same partition
/*
Summary Table:
Function
	
Handles Ties?
	
Gaps in Ranks?
ROW_NUMBER()
	
No
	
No
RANK()
	
Yes
	
Yes
DENSE_RANK()
	
Yes
	
No

*/

39)

https://leetcode.com/problems/page-recommendations/description/
1264. Page Recommendations

Select distinct l.page_id as recommended_page

From 

    (

        Select user2_id as 'friend_of_1'
        From Friendship
        Where user1_id = 1

        Union

        Select user1_id as 'friend_of_1'
        From Friendship
        Where user2_id = 1


    ) x

    Inner Join Likes l
    On x.friend_of_1 = l.user_id

Where l.page_id not in 
   (
       Select page_id
       From Likes
       Where user_id = 1
   )
   
40)

https://leetcode.com/problems/page-recommendations/description/

Select distinct l.page_id as recommended_page

From 

    (

        Select user2_id as 'friend_of_1'
        From Friendship
        Where user1_id = 1

        Union

        Select user1_id as 'friend_of_1'
        From Friendship
        Where user2_id = 1


    ) x

    Inner Join Likes l
    On x.friend_of_1 = l.user_id

Where l.page_id not in 
   (
       Select page_id
       From Likes
       Where user_id = 1
   )
   
41)

# https://leetcode.com/problems/election-results/description/
2820. Election Results

/*
    With CTE as
    (
        Select 
                voter,
                SUM(IF(candidate is null, 0, 1)) votes_cast #count(COALESCE(candidate,0)) as votes_cast        
        From Votes
        #Where candidate is not null
        Group By voter
    ),


    CTE_1 as 
    (
        Select v.voter,
            c.votes_cast,
            v.candidate, 
            round(1/c.votes_cast, 2) as num_votes
        From CTE c
            Inner Join Votes v
            On c.voter = v.voter
        Where c.votes_cast <> 0        
    ),

    CTE_2 as
    (
        Select candidate, 
            round(sum(num_votes), 2) as total_votes,
            dense_rank() over(Order By round(sum(num_votes), 2) desc) rnk
        From CTE_1
        Group By candidate
    )

    Select candidate
    From CTE_2
    Where rnk = 1
    Order By candidate asc
	
comment about the alias total_votes used in dense_rank():

🧠 How the Window Function Accesses the Data

    Grouping Result: After the GROUP BY and SUM are executed, the intermediate result is a table with one row per candidate, and one column is the calculated total votes (the value represented by round(sum(num_votes), 2)).

    Window Function Execution: The DENSE_RANK() function then sees this intermediate result set. Its ORDER BY clause explicitly uses the expression:
    Order By round(sum(num_votes), 2) desc

    Because the window function is executed after the aggregation, it has access to the result of that aggregation for every row in the intermediate table. It uses this result to determine the rank.

    Alias Restriction: While the total_votes value is calculated before the ranking, you cannot use the alias (total_votes) directly inside the window function's ORDER BY clause because window functions are logically 
	executed before the final SELECT list aliases are resolved (unless you are using a subquery or CTE).

        Incorrect: dense_rank() over(Order By total_votes desc)
        Correct: dense_rank() over(Order By round(sum(num_votes), 2) desc)

In summary, the aggregated total_votes value is calculated first, and then the window function uses that calculated value to assign the rank in the subsequent step.

*/

With CTE as 
(
                Select 

                    candidate,

                    sum(weight) as 'total_weight'

                From 

                (
                                Select 

                                    v.voter,

                                    v.candidate,

                                    num.num_votes,
                                    
                                    IF   ( 
                                                    v.candidate is null, 
                                                    0, 
                                                    num.num_votes
                                            ) as actual_num_votes,
                                        
                                        IF
                                            ( v.candidate is null
                                                ,
                                                0
                                                ,
                                                round
                                                ( 
                                                    1
                                                    /
                                                    IF   
                                                        ( 
                                                            v.candidate is null, 
                                                            0, 
                                                            num.num_votes
                                                        )
                                                    ,
                                                    2
                                                ) 
                                            ) as weight

                                From Votes v 

                                    Inner Join 

                                    (
                                        Select voter,
                                            count(voter) as 'num_votes'
                                        From Votes
                                        Group By voter
                                    ) num

                                    On v.voter = num.voter

                                Group By v.voter,
                                    v.candidate,
                                    num.num_votes
                ) x
                Where candidate is not null
                Group By candidate
                Order By candidate asc
)


Select candidate
From CTE
Where total_weight = (Select max(total_weight) From CTE)
Order By candidate asc

42)


https://leetcode.com/problems/the-category-of-each-member-in-the-store/description/
2051. The Category of Each Member in the Store

Select m.member_id,
       m.name,
       /*
		   SUM(IF(COALESCE(v.member_id,0) = 0, 0, 1)) as total_visits,
		   SUM(IF(COALESCE(p.visit_id,0) = 0, 0, 1)) as total_purchases,
       */
       CASE

           WHEN 
                round
                    (
                        ( 
                        100 * SUM(IF(COALESCE(p.visit_id,0) = 0, 0, 1))
                        /
                        SUM(IF(COALESCE(v.member_id,0) = 0, 0, 1))
                        )
                        ,
                        2
                    ) 
                    >= 
                    80
            THEN "Diamond"
 
            WHEN 
                round
                    (
                        ( 
                        100 * SUM(IF(COALESCE(p.visit_id,0) = 0, 0, 1))
                        /
                        SUM(IF(COALESCE(v.member_id,0) = 0, 0, 1))
                        )
                        ,
                        2
                    ) 
                    >= 50
            THEN "Gold"

            WHEN 
                round
                    (
                        ( 
                        100 * SUM(IF(COALESCE(p.visit_id,0) = 0, 0, 1))
                        /
                        SUM(IF(COALESCE(v.member_id,0) = 0, 0, 1))
                        )
                        ,
                        2
                    ) 
                    < 50
            THEN "Silver"

           ELSE "Bronze"
       END as category

From Members m

     Left Join Visits v
     On m.member_id = v.member_id
     
     Left Join Purchases p
     On v.visit_id = p.visit_id

Group By m.member_id,
         m.name

Order by m.member_id asc

/*

		- do a left join 
		- convert null for no purchases to 0 
		- do a caculation and assign rank
		- join back to member table
		- reuturn result

		With CTE1 as 
		(
		Select v.member_id,
			   Case 
				  When p.visit_id is null Then v.visit_id
				  Else v.visit_id
			   End visit_id, 
			   Case 
				  When p.charged_amount is null then 0
				  Else p.charged_amount
			   End charged_amount 
		From Visits v 
			 Left Join Purchases p 
			   On v.visit_id = p.visit_id
		)

		# roll_up to member_id and charged_amount

		CTE2 as 
		(
			Select member_id,
				   count(distinct visit_id) as num_visits,
				   sum(charged_amount) as total_spent
				   round((100 * count(distinct visit_id)/sum(charged_amount)), 2) as conversion_rate
			From CTE1
			Group By member_id
		)


		Select  m.member_id,
				m.name,
				CASE 
				   When c2.conversion_rate > 80 Then 'Diamond'
				   When c2.conversion_rate between 50 and 80 Then 'Gold'
				   When c2.conversion_rate < 50 Then 'Silver'
				   Else 'Bronze'
				End category
			   
		From Members m 
			 Left Join CTE2 c2 
			 on m.member_id = c2.member_id    
*/

43)

https://leetcode.com/problems/department-top-three-salaries/description/
185. Department Top Three Salaries

Select 
            employee_id, 
            name,
            salary,           
            DENSE_RANK() Over(Order By salary asc) as team_id
From 
    (        
                Select employee_id, 
                    name,
                    salary,
                    count(*) over(partition by salary) cnt                    
                From Employees
                Order By salary asc
    ) x 

Where cnt >= 2

Order By team_id asc, employee_id asc


44)

https://leetcode.com/problems/maximum-transaction-each-day/
1831. Maximum Transaction Each Day


Select transaction_id

From Transactions 

Where (day, amount) in 
    (
            Select day, 
                   max(amount) as max_amt
            From Transactions 
            Group By day
    )

Order By transaction_id asc

45)

https://leetcode.com/problems/the-first-day-of-the-maximum-recorded-degree-in-each-city/description/
2314. The First Day of the Maximum Recorded Degree in Each City


Select 

      x.city_id,

       min(w.day) as day,

       x.degree

From 
    (
        
            Select city_id, 
                max(degree) as degree

            From Weather

            Group By city_id

            Order By city_id asc

    ) x

    Inner Join Weather w
    On x.city_id = w.city_id and 
        x.degree = w.degree

Group By x.city_id, x.degree

Order By x.city_id asc, day asc

/*


    # Write your MySQL query statement below
    WITH
        T AS (
            SELECT
                *,
                rank() OVER (
                    PARTITION BY city_id
                    ORDER BY degree DESC, day
                ) AS rk
            FROM Weather
        )
    SELECT city_id, day, degree
    FROM T
    WHERE rk = 1
    ORDER BY 1;


*/
46)


Select 

      x.city_id,

       min(w.day) as day,

       x.degree

From 
    (
        
            Select city_id, 
                max(degree) as degree

            From Weather

            Group By city_id

            Order By city_id asc

    ) x

    Inner Join Weather w
    On x.city_id = w.city_id and 
        x.degree = w.degree

Group By x.city_id, x.degree

Order By x.city_id asc, day asc

47)

#Remember: Where works on From in the same way as Having works on Group By
#Remember: sum(r.score) can not be in the Where because Group By is calculated after Where 

https://leetcode.com/problems/accepted-candidates-from-the-interviews/description/
2041. Accepted Candidates From the Interviews

Select 
    c.candidate_id

From 
    Candidates c 
     Inner Join Rounds r
     On c.interview_id = r.interview_id

Where c.years_of_exp >= 2 

Group By c.candidate_id

Having sum(r.score) > 15


48)
https://leetcode.com/problems/the-airport-with-the-most-traffic/description/
2112. The Airport With the Most Traffic

With CTE as
(
        Select 

            airport,        
            sum(flights) as total_flights

        From
                (
                    Select departure_airport as airport, 
                        sum(flights_count) as flights
                    From Flights
                    Group By departure_airport 

                    Union all

                    Select arrival_airport as airport, 
                        sum(flights_count) as flights
                    From Flights
                    Group By arrival_airport 
                ) x

        Group By airport
        Order By sum(flights) desc
)


-- in case of a tie can return multiple results
Select airport as airport_id
From  CTE 
Where total_flights 
      = 
        (
            Select max(total_flights) 
            from CTE
        ) 

VS


-- will just reutrn only 1 airport even if there is a tie
Select airport as airport_id
From  CTE 
Order By total_flights desc
Limit 1

49)

https://leetcode.com/problems/orders-with-maximum-quantity-above-average/description/
1867. Orders With Maximum Quantity Above Average

Select x.order_id 

From
   (
        Select order_id, 
               max(quantity) as order_id_max
        From OrdersDetails
        Group By order_id
    ) x

Where 
        x.order_id_max 
        >
        (
            Select max(y.order_id_qty_avg)
            From    (
                        Select avg(quantity) as order_id_qty_avg
                        From OrdersDetails o        
                        Group By o.order_id
                    ) y
            
        ) 

50)

https://leetcode.com/problems/activity-participants/description/
1355. Activity Participants

With CTE as
(
	Select activity, count(activity) as num_activity
	From Friends
	Group By activity
	Order By count(activity) desc
) 


Select activity /*, 
       num_activity as max_min_activity*/
From CTE
Where num_activity not in 
            (Select max(num_activity) From CTE)
      and 
      num_activity not in 
            (Select min(num_activity) From CTE)

51)



Select 

      r.driver_id,

      If (
            COALESCE(x.passenger_id,0) = 0, 
            COALESCE(x.cnt,0), 
            x.cnt
          ) as 'cnt'

      From (
			Select distinct driver_id
			From Rides
			) r 
			Left Join 
			(
					Select passenger_id, count(*) cnt
					From Rides
					Group By passenger_id             
			) x
            On r.driver_id = x.passenger_id
     
	 
52)


With recursive CTE as
(
   Select 1 as 'r_num'
   From Customers


   Union 

   Select r_num+1 as 'r_num'
   From CTE a
   Where r_num + 1 <= (Select max(customer_id) From Customers)

)


Select a.r_num as ids
From CTE a Left Join Customers c
     On a.r_num = c.customer_id
Where c.customer_id is null
Order By a.r_num asc

53)

https://leetcode.ca/2021-02-26-1715-Count-Apples-and-Oranges/
https://github.com/yennanliu/CS_basics/blob/master/leetcode_SQL/count-apples-and-oranges.sql

With CTE as
(
        Select 

            #b.box_id,
            #b.chest_id,
            sum(b.apple_count) as box_apples, 
            sum(b.orange_count) as box_orange,
            #c.chest_id as 'Chests.chest_id',
            sum(COALESCE(c.apple_count, 0)) as apples_in_chest,
            sum(COALESCE(c.orange_count, 0)) as oranges_in_chest

        From Boxes b Left Join Chests c
            On b.chest_id = c.chest_id 

) 


Select sum(apple_count) as apple_count,
       sum(orange_count) as orange_count
From
(
        Select box_apples as 'apple_count', box_orange as 'orange_count'
        From CTE

        Union All

        Select  apples_in_chest as 'apple_count', oranges_in_chest as 'orange_count'
        From CTE
) x

54)
# https://leetcode.com/problems/customers-who-bought-products-a-and-b-but-not-c/description/
1398. Customers Who Bought Products A and B but Not C

    Select x.customer_id,
           p.customer_name

    From Customers p

         Inner Join 
            (
                Select c.customer_id
                     
                From Orders c
                        Inner Join
                            (
                                Select a.customer_id 
                                From Orders a
                                    Inner Join
                                        (
                                            Select customer_id
                                            From Orders 
                                            Where customer_id not in (Select customer_id From Orders Where product_name = 'C')
                                            Group By customer_id
                                        ) b 
                                    On a.customer_id = b.customer_id
                                Where a.product_name = 'B'
                                Group By a.customer_id
                            ) d
                        On c.customer_id = d.customer_id
                Where c.product_name = 'A'
            ) x
            On 
            p.customer_id = x.customer_id
Group By x.customer_id
Order By p.customer_id asc

/*
    Customers =
    | customer_id | customer_name |
    | ----------- | ------------- |
    | 1           | Daniel        |
    | 2           | Diana         |
    | 3           | Elizabeth     |
    | 4           | Jhon          |
    Orders =
    | order_id | customer_id | product_name |
    | -------- | ----------- | ------------ |
    | 10       | 1           | A            |
    | 20       | 1           | B            |
    | 30       | 1           | D            |
    | 40       | 1           | C            |
    | 50       | 2           | A            |
    | 60       | 3           | A            |
    | 70       | 3           | B            |
    | 80       | 3           | A            |
    | 90       | 4           | C            |

Note: Customer_id buys A twice - hence the distinct - prefer the inner join solution


With CTE as
(
            Select x.customer_id,
                   x.product_name,
                   x.order_id
            From 
                (
                    Select customer_id, 
                           product_name,
                           order_id
                    From Orders
                    Where customer_id not in # ignore customers entirely if they bought 'C'
                            (
                                Select customer_id 
                                From Orders 
                                Where product_name = 'C'
                            )
                ) x
            Where x.product_name = 'A' 
)

Select c.customer_id, 
       c.customer_name
From Customers c
     Inner Join 
        (
            Select distinct o.customer_id
            From CTE c 
                Inner Join Orders o
                On c.customer_id = o.customer_id
            Where c.order_id <> o.order_id and 
                  o.product_name = 'B'
        ) x
    On c.customer_id = x.customer_id
Order By c.customer_id asc


*/
55)

# https://github.com/yennanliu/CS_basics/blob/master/leetcode_SQL/number-of-trusted-contacts-of-a-customer.sql

Select  i.invoice_id,       
        cust1.customer_name,
        i.price,        
        CASE 
            When c.user_id is null then 0
            Else count(c.user_id)
        END contacts_cnt,       
        count(cust.customer_name) as trusted_contacts_cnt

From  Invoices i 
      
       Left Join Contacts c 
       On i.user_id = c.user_id

       Left Join Customers cust
       On c.contact_name = cust.customer_name

       Inner Join customers cust1
       On i.user_id = cust1.customer_id

Group By i.invoice_id,       
        i.price

Order By i.invoice_id asc

56)

With CTE As
(
        Select e.emp_name as 'manager_name', 
            x.dep_id,
            x.num_employees,
            DENSE_RANK() Over(Order By x.num_employees desc) as d_rank
        From 
            (  --number of distinct employees per department
                Select dep_id, 
                       count(distinct emp_id) as num_employees
                From Employees 
                Group By dep_id
                #Order By 
                #        count(distinct emp_id) desc, 
                #        dep_id asc        
            ) x 
            Inner Join Employees e
            On x.dep_id = e.dep_id     
        Where e.position = 'Manager'
        Group By e.emp_name, x.dep_id
        Order By x.dep_id asc, 
                x.num_employees desc
 )

Select manager_name,
       dep_id
From CTE
Where d_rank = (Select min(d_rank) From CTE)


57)

#1596. The Most Frequently Ordered Products for Each Customer
https://leetcode.com/problems/the-most-frequently-ordered-products-for-each-customer/description/

/*
#you can partition by more than one column or within a partition, you can order by more than one column to break ties
#hint: COUNT(b.order_id) OVER(PARTITION BY a.customer_id, b.product_id) AS freq
*/

/*
With CTE as 
(
    Select customer_id,
        #count(customer_id) total_orders,
        product_id,
        count(product_id) times_product_id_ordered
        
    From Orders
    Group By customer_id, product_id
    Order By customer_id asc, product_id asc, times_product_id_ordered 
)

Select c.customer_id, c.product_id, p.product_name
From CTE c
     Inner Join Products p
     On c.product_id = p.product_id
Where (c.customer_id, c.times_product_id_ordered) in
      (
        Select customer_id, max(times_product_id_ordered) 'how_many_times'
        From CTE
        Group By customer_id
      )
*/

/*
Method 1:
*/
/*
WITH CTE AS (
    SELECT 
        customer_id, 
        o.product_id,
        p.product_name,
        COUNT(o.product_id) num_purchases
    FROM 
        Orders O 
        INNER JOIN 
        Products p ON o.product_id = p.product_id
    GROUP BY 
        customer_id, 
        o.product_id,
        p.product_name
    Order By customer_id asc, o.product_id asc
),

CTE1 AS (
    SELECT 
        customer_id, 
        product_id,
        product_name,
        num_purchases,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY num_purchases DESC) AS rnk
    FROM 
        CTE
)

SELECT 
    customer_id, 
    product_id,
    product_name
FROM 
    CTE1
WHERE 
    rnk = 1;
*/

/*
Method 2:

--coorelated subquery

Performance Considerations:

    Correlated subqueries can be expensive in terms of performance because the inner query may run many times (once for each row in the outer query), similar to how an inner loop runs multiple times for each iteration of the outer loop.
    This is why in large datasets, it’s often preferable to refactor correlated subqueries into JOINs or CTEs to avoid repeated execution of the inner query.
*/

WITH CTE AS (
    SELECT 
        customer_id, 
        o.product_id,
        p.product_name,
        COUNT(o.product_id) AS num_purchases
    FROM Orders O
    INNER JOIN Products p ON o.product_id = p.product_id
    GROUP BY 
        customer_id, 
        o.product_id,
        p.product_name
)

SELECT  
    customer_id,
    product_id,
    product_name
FROM 
    CTE c1
WHERE 
    num_purchases = (
        SELECT MAX(num_purchases) 
        FROM CTE c2 
        WHERE c1.customer_id = c2.customer_id
    )
ORDER BY 
    customer_id ASC, 
    product_id ASC;


/*
Method 3:

You can refactor this correlated subquery using a JOIN with a Common Table Expression (CTE) or a 
window function. Using a JOIN can avoid the repeated execution of the inner query, improving 
performance for larger datasets.
Refactored Query using a JOIN:
*/

WITH CTE AS (
    SELECT 
        customer_id, 
        o.product_id,
        p.product_name,
        COUNT(o.product_id) AS num_purchases
    FROM Orders O
    INNER JOIN Products p ON o.product_id = p.product_id
    GROUP BY 
        customer_id, 
        o.product_id,
        p.product_name
)
SELECT 
    c1.customer_id, 
    c1.product_id, 
    c1.product_name
FROM 
    CTE c1
INNER JOIN (
    SELECT 
        customer_id, 
        MAX(num_purchases) AS max_purchases
    FROM CTE
    GROUP BY customer_id
) c2
ON c1.customer_id = c2.customer_id 
AND c1.num_purchases = c2.max_purchases
ORDER BY 
    c1.customer_id ASC, 
    c1.product_id ASC;

58)

#1468. Calculate Salaries
#https://leetcode.com/problems/calculate-salaries/description/

--Method 1:

with CTE as
(
    Select company_id,  
           max(salary) as max_salary
    From Salaries
    Group By company_id
)


Select 
       s.company_id,

       s.employee_id,

       s.employee_name,

       CASE
    
        When c.max_salary < 1000 Then s.salary
        When c.max_salary between 1000 and 10000 Then ROUND((1-0.24) * s.salary)
        When c.max_salary > 10000 Then ROUND((1-0.49) * s.salary)

       END salary

From Salaries s Inner Join CTE c
     On s.company_id = c.company_id
	
-- Method 2:
WITH CTE AS
(
    SELECT 
        s.company_id, 
        s.employee_id, 
        s.employee_name,
        CASE
            WHEN MAX(s.salary) OVER (PARTITION BY s.company_id) < 1000 THEN s.salary
            WHEN MAX(s.salary) OVER (PARTITION BY s.company_id) BETWEEN 1000 AND 10000 THEN ROUND((1-0.24) * s.salary)
            WHEN MAX(s.salary) OVER (PARTITION BY s.company_id) > 10000 THEN ROUND((1-0.49) * s.salary)
        END AS adjusted_salary
    FROM Salaries s
)

SELECT 
    company_id,
    employee_id,
    employee_name,
    adjusted_salary AS salary
FROM CTE;	
	 
59)

2298 - Tasks Count in the Weekend
https://leetcode.ca/2022-07-09-2298-Tasks-Count-in-the-Weekend/

Select 

        SUM(IF
               (
                DAYOFWEEK(submit_date) = 7 OR 
                DAYOFWEEK(submit_date) = 1
                , 
                1
                , 
                0
               )
            ) 
       
        weekend_cnt,

       SUM(IF(
              DAYOFWEEK(submit_date) = 2 OR 
              DAYOFWEEK(submit_date) = 3 OR
              DAYOFWEEK(submit_date) = 4 OR
              DAYOFWEEK(submit_date) = 5 OR
              DAYOFWEEK(submit_date) = 6
              , 
              1, 
              0
              ) )
            working_cnt
From Tasks

60)

# 1699. Number of Calls Between Two Persons
#https://leetcode.ca/all/1699.html

Select  from_id as 'person1',
        to_id   as 'person2',
        sum(call_count) as 'call_count',
        sum(total_duration) as 'total_duration'
From 
			(
					Select 
						   c1.from_id,
						   c1.to_id,
						   count(*) as 'call_count',
						   sum(c1.duration) as 'total_duration'

					From Calls c1 

					Where   (
								c1.from_id < c1.to_id 
								and 
								(c1.from_id, c1.to_id) 
								in
								(
									Select from_id, c1.to_id
									From Calls
								)
							)
					Group By c1.from_id,  c1.to_id

					Union All

					Select 
						   c1.to_id as from_id,
						   c1.from_id as to_id,
						   count(*) as 'call_count',
						   sum(c1.duration) as total_duration

					From Calls c1 

					Where   (
								c1.from_id > c1.to_id 
								and 
								(c1.from_id, c1.to_id) 
								in
								(
									Select from_id, to_id
									From Calls
								)
							)
					Group By from_id,  to_id
			) x

Group By from_id, to_id


/*
Why Interviewers Prefer This Version

They are testing:

Can you recognize unordered pair grouping

Can you normalize data before aggregation

Can you avoid unnecessary joins/unions

Your original solution shows:

Good problem understanding

But over-engineering, which is usually penalized
from chatGPT:
SELECT
    CASE WHEN from_id < to_id THEN from_id ELSE to_id END AS person1,
    CASE WHEN from_id < to_id THEN to_id ELSE from_id END AS person2,
    COUNT(*) AS call_count,
    SUM(duration) AS total_duration
FROM Calls
GROUP BY
    CASE WHEN from_id < to_id THEN from_id ELSE to_id END,
    CASE WHEN from_id < to_id THEN to_id ELSE from_id END;
	
	SELECT
    from_id   AS person1,
    to_id     AS person2,
    COUNT(*)  AS call_count,
    SUM(duration) AS total_duration
FROM (
    SELECT
        from_id,
        to_id,
        duration
    FROM Calls
    WHERE from_id < to_id

    UNION ALL

    SELECT
        to_id   AS from_id,
        from_id AS to_id,
        duration
    FROM Calls
    WHERE from_id > to_id
) x
GROUP BY from_id, to_id;
*/

/*
SELECT
    LEAST(from_id, to_id) AS person1,
    GREATEST(from_id, to_id) AS person2,
    COUNT(*) AS call_count,
    SUM(duration) AS total_duration
FROM Calls
GROUP BY
    LEAST(from_id, to_id),
    GREATEST(from_id, to_id);
*/

/*
System Design–Level Explanation

“This GROUP BY implements a canonicalization step in the aggregation pipeline.
It normalizes bidirectional relationships by enforcing a deterministic ordering of participant identifiers before aggregation.”

Framed as a Data Pipeline Concept

“Before aggregation, each record is transformed into a canonical form where the lower user ID is always assigned to person1 and the higher to person2.
This ensures that logically equivalent events—regardless of direction—produce identical grouping keys.”

Why This Matters Architecturally

“Without this normalization layer, the system would treat (A → B) and (B → A) as separate entities, leading to fragmented aggregates and incorrect metrics.”

How It Fits Into a Typical System Architecture

“This is equivalent to a key-normalization stage in a streaming or batch processing system—similar to pre-processing keys before a reduce 
operation in MapReduce or before a group-by in a distributed SQL engine.”

Consistency & Correctness Angle

“By canonicalizing the relationship key at query time, we guarantee consistency of aggregated metrics without relying on upstream data cleanliness or enforcing directional constraints at ingestion.”

Performance & Simplicity Justification

“This approach avoids multi-pass aggregation or UNION-based logic, reducing computational complexity and making the aggregation idempotent and 
easier to reason about.”

Alternative Framing (If Talking to Infra / Data Platform Engineers)

“Think of this as defining a composite primary key for an undirected edge in a graph:
(min(nodeA, nodeB), max(nodeA, nodeB)).”

Short System-Design One-Liner

“We normalize symmetric relationships into a canonical key so aggregation happens once per logical entity instead of once per direction.”

If You’re Asked “Why Not Do This Earlier?”

Strong answer:

“Ideally this normalization happens at ingestion, but doing it at query time allows us to preserve raw event fidelity while still producing correct 
analytical aggregates.”
*/


61)


Select 
     sp.salesperson_id,
     sp.name, 
     COALESCE(sum(s.price),0) as total    

From Salesperson sp
     
     Left Join Customer c
     On sp.salesperson_id = c.salesperson_id

     Left Join Sales s
     On c.customer_id = s.customer_id

Group By 
     sp.salesperson_id,
     sp.name  
	 
	 
62)

#1783. Grand Slam Titles

/*

	SELECT p.player_id, 
		   p.player_name, 
		   COUNT(*) AS grand_slams_count
	FROM Players p
	LEFT JOIN (
		SELECT Wimbledon AS player_id FROM Championships
		UNION ALL
		SELECT Fr_open FROM Championships
		UNION ALL
		SELECT US_open FROM Championships
		UNION ALL
		SELECT Au_open FROM Championships
	) c ON p.player_id = c.player_id
	GROUP BY p.player_id, p.player_name
	ORDER BY grand_slams_count DESC, p.player_name;

*/
Select player_id,
       player_name, 
       sum(grand_slams_count) as 'grand_slams_count'
From 
(
            Select 
                #'Wimbledon',
                p.player_id,
                p.player_name,
                count(c.Wimbledon) as 'grand_slams_count'    
            From Players p Inner Join Championships c
                 On p.player_id = c.Wimbledon
            Group By p.player_id, p.player_name

            Union All

            Select 
                #'FR',
                p.player_id,
                p.player_name,
                count(c.Fr_open) as 'grand_slams_count'    
            From Players p Inner Join Championships c
                On p.player_id = c.Fr_open
            
            Group By p.player_id, p.player_name

            Union All

            Select 
                #'US',
                p.player_id,
                p.player_name,
                count(c.US_open) as 'grand_slams_count'    
            From Players p Inner Join Championships c
                On p.player_id = c.US_open
            Group By p.player_id, p.player_name

            Union All

            Select 
                #'AU',
                p.player_id,
                p.player_name,
                count(c.AU_open) as 'grand_slams_count'    
            From Players p Inner Join Championships c
                On p.player_id = c.AU_open
            Group By p.player_id, p.player_name
) x

Group By player_id, 
         player_name
		 
63)
https://leetcode.com/problems/running-total-for-different-genders/description/
#Problem 1308: Running Total for Different Genders

Select 

    gender, 
    day,
    sum(score_points) Over(Partition By gender Order By day asc) as total

From Scores

Group By gender, 
    day

64)

#https://leetcode.com/problems/drop-type-1-orders-for-customers-with-type-0-orders/description/
#https://leetcode.ca/2021-12-07-2084-Drop-Type-1-Orders-for-Customers-With-Type-0-Orders/

With CTE1 as
(
        Select o1.order_id, o1.customer_id, o1.order_type
        From Orders o1
        Where (o1.order_id, o1.customer_id, o1.order_type) in
                (   
                    #those orders and customers where at least one order_type is 0
                    Select o2.order_id, o2.customer_id, o2.order_type
                    From Orders o2
                    Where 
                        o1.order_id = o2.order_id and 
                        o1.customer_id = o2.customer_id and 
                        o2.order_type = 0             
                )
            AND 
            o1.order_type <> 1 -- don't report 1
),

CTE2 as
(
        Select o1.order_id, o1.customer_id, o1.order_type
        From Orders o1
        Where o1.customer_id not in 
                (   
                    #those orders and customers where at least one order_type is 0
                    Select distinct customer_id
                    From CTE1                    
                )
)

Select order_id, customer_id, order_type
From CTE1
UNION
Select order_id, customer_id, order_type
From CTE2

#recognize that you need two tables

/*

WITH CTE1 AS (
    SELECT o1.order_id, o1.customer_id, o1.order_type
    FROM Orders o1
    JOIN Orders o2 ON o1.order_id = o2.order_id
    WHERE o2.customer_id = o1.customer_id
      AND o2.order_type = 0
      AND o1.order_type <> 1
),

CTE2 AS (
    SELECT o1.order_id, o1.customer_id, o1.order_type
    FROM Orders o1
    WHERE NOT EXISTS (
        SELECT 1
        FROM Orders o2
        WHERE o1.customer_id = o2.customer_id
          AND o2.order_type = 0
    )
)

SELECT order_id, customer_id, order_type
FROM CTE1

UNION

SELECT order_id, customer_id, order_type
FROM CTE2;

Why use 1?

    Using 1 is a common convention in SQL subqueries when you just need to check for the existence of a row rather than retrieve any actual data.
    You could replace it with * (i.e., SELECT *), but using 1 is a more optimized practice because the database engine does not need to fetch any 
	actual columns—just the fact that at least one row exists is enough.

Summary:

The 1 doesn't have any specific meaning beyond indicating that the subquery is simply checking for 
existence. It’s a minimal value and used just for efficiency when you're not interested in the actual 
data returned by the subquery, only whether or not any rows exist.
*/

65)

#2991. Top Three Wineries
#https://leetcode.com/problems/top-three-wineries/description/

/*

"Dense" means that if there are ties (multiple rows with the same value), they get the same rank, and there are no gaps in the ranking sequence. 
For example, if two rows are ranked 1, the next row will be ranked 2, not 3.

query structure is cleaner and more efficient. This solution avoids unnecessary complexity and is more performant as it reduces the number of CTEs 
and joins.

The key factor that could influence the choice is whether or not you expect to have countries with fewer than 3 wineries. If so, this solution will 
return NULL values, which are then replaced with "No second winery" or "No third winery". If this behavior is acceptable, Solution 2 is the clear winner. 
If you want more control over the output for countries with fewer than 3 wineries, Solution 1 might be preferable. However, in most cases, Solution 2's 
simplicity and performance would be the better choice.

Solution 2: Alternative solution

With CTE as 
(
	SELECT 
		country,
		winery,
		SUM(points) OVER (PARTITION BY country, winery) AS cumulative_points, 
		ROW_NUMBER() OVER (PARTITION BY country ORDER BY SUM(points) OVER (PARTITION BY country, winery) DESC) AS rnk,
		concat(winery, '(', cumulative_points, ')') as winery_and_points

	FROM 
		employees

	ORDER BY 
		country ASC, cumulative_points DESC, rnk ASC
)


Select a.country, 
       a.top_winery as top_winery,
	   COALESCE(b.second_winery, 'No Second Winery') as 'Second_Winery', 
	   COALESCE(c.third_winery, 'No Third Winery') as 'Third_Winery'	   

From 
    (	
	    Select country, winery_and_points as 'top_winery'
		From CTE
		Where rnk = 1
    ) a
	
	Left Join	
	(
		Select country, winery_and_points as 'second_winery'
		From CTE
		Where rnk = 2
	) b 
	
	On a.country = b.country
	
	Left Join 	
	(
		Select country, winery_and_points as 'third_winery'
		From CTE
		Where rnk = 3
	) c
	
	On a.country = c.country 

*/

With CTE as
(
    Select country,       
           winery,
           sum(points) as points,
           ROW_NUMBER() OVER(Partition by country Order By sum(points) desc, winery asc) as row_num

    From Wineries

    #Where country in ('Spain', 'SouthAfrica')

    Group By country, winery
), 

get_top_three as
(
    Select country,
           winery,
           points,
           row_num,
           concat(winery, ' (', points, ')') as 'winery_and_points'
    From cte
    Where row_num < 4
),


top_wineries AS (
  SELECT 
    country, 
    winery_and_points, 
    row_num
  FROM 
    get_top_three
  WHERE 
    row_num = 1
),


second_wineries AS (
  SELECT 
    country, 
    winery_and_points, 
    row_num
  FROM 
    get_top_three
  WHERE 
    row_num = 2
),


third_wineries AS (
  SELECT 
    country, 
    winery_and_points, 
    row_num
  FROM 
    get_top_three
  WHERE 
    row_num = 3
)

Select top_wineries.country,
       top_wineries.winery_and_points as top_winery,
       COALESCE(second_wineries.winery_and_points, 'No second winery') as second_winery,
       COALESCE(third_wineries.winery_and_points, 'No third winery') as third_winery
From top_wineries
     LEFT JOIN second_wineries ON top_wineries.country = second_wineries.country
     LEFT JOIN third_wineries ON top_wineries.country = third_wineries.country
Order By top_wineries.country asc

66)



# 1159. Market Analysis II
# https://leetcode.com/problems/market-analysis-ii/description/


/*

Option 1:
=========

With CTE as 
(
        Select COALESCE(u.user_id, y.seller_id) as seller_id,
            u.favorite_brand as favorite_brand,
            y.item_id as ited_id_sold,
            i.item_brand as brand_nameOf_item_sold,
            i.item_id as id_of_brand_sold,
            y.rnk
        From 
            Users u 
            Left Join #not all users will also be sellers
                (
                    Select seller_id,
                        item_id,
                        rnk
                    From 
                        (
                            Select seller_id,
                                item_id,
                                dense_rank() Over(Partition by seller_id Order by order_date asc) as rnk
                            From Orders
                        ) x
                ) y
            On u.user_id = y.seller_id

            Left Join Items i 
            On y.item_id = i.item_id
)


Select seller_id,
       'yes' as 2nd_item_fav_brand
From CTE
Where favorite_brand = brand_nameOf_item_sold and rnk = 2

Union 

Select seller_id,
       'no' as 2nd_item_fav_brand
From CTE
Where seller_id not in 
      (
        Select seller_id
        From CTE
        Where favorite_brand = brand_nameOf_item_sold and rnk = 2
      )
*/

/*
Select seller_id,
       CASE
          When  favorite_brand = brand_nameOf_item_sold Then 'Yes'
          Else 'no'
       END  as 2nd_item_fav_brand
From CTE
Where rnk = 2

Union

Select seller_id,
       'no' as 2nd_item_fav_brand
From CTE
Where rnk < 2
*/


/*
Select seller_id,
       CASE 
            When rnk = 2 and favorite_brand = brand_nameOf_item_sold Then 'yes'
            When max(COALESCE(rnk, 0)) < 2 Then 'no'
       END 2nd_item_fav_brand
From CTE 
Group By seller_id
*/


/*
#Option 2

With CTE as 
(
    Select 
           o.order_id, 
           o.order_date, 
           o.item_id,
           i.item_brand,
           u.favorite_brand,

           CASE
            When i.item_brand = u.favorite_brand 
            Then 'yes'
            Else 'no'
           END 2nd_item_fav_brand,   

           o.seller_id, 
           dense_rank() over(Partition By o.seller_id Order By o.order_date asc) sale_sequence

    From Orders o 
         Inner Join Items i 
         On o.item_id = i.item_id

         Inner Join Users u 
         On o.seller_id = u.user_id 
    Order By o.seller_id asc, sale_sequence asc
),

CTE_1 as
(
    Select seller_id, 
        2nd_item_fav_brand
    From CTE
    Where sale_sequence = 2 and 
        item_brand = favorite_brand
)

Select seller_id, 
       2nd_item_fav_brand
From CTE_1

Union 

# we had to do this because we did not use a Left Join for the CTE table built above

Select user_id as seller_id,
       'no' as 2nd_item_fav_brand
From Users
Where user_id not in (Select distinct seller_id From CTE_1)
*/



/*

Option 3
=========
With CTE as 
(
    Select #o.*,    
           #u.*,
           o.seller_id, 
           o.order_date,
           i.item_brand,
           u.favorite_brand

    From Orders o 
         
         Inner Join Users u
         On o.seller_id = u.user_id # joined the seller_id so 

         Inner Join Items i 
         On o.item_id = i.item_id

    Order By o.seller_id, o.order_date
),

#Get the least order date

CTE1 as
(

    Select x.seller_id, 
        #x.item_brand, 
        #x.favorite_brand,
        min(x.order_date) as 'first_order_date'   

    From CTE x 

    Group By x.seller_id

    Order By x.seller_id asc

),

#Select * from CTE1

#get the second least order date

CTE2 as 
(

    Select x.seller_id, 
           #x.item_brand, 
           #x.favorite_brand,
           min(x.order_date) as 'second_order_date'   
    
    From CTE x Inner Join CTE1 y
         On x.seller_id = y.seller_id

    Where x.order_date > y.first_order_date

    Group By x.seller_id

    Order By x.seller_id asc

),

#Select * From CTE2

CTE3 as
(

    Select x.seller_id,
        CASE
                When y.item_brand = y.favorite_brand Then 'yes'
                Else 'no'
        END as '2nd_item_fav_brand'

    From CTE2 x Inner Join CTE y
        On x.seller_id = y.seller_id

    Where x.second_order_date = y.order_date

    Order By x.seller_id asc

)


Select seller_id,
       2nd_item_fav_brand

From CTE3

Union

Select user_id as 'seller_id',
       'no' as '2nd_item_fav_brand'
From Users
Where user_id not in (Select distinct seller_id from CTE3)      

*/

67)
601. Human Traffic of Stadium
https://leetcode.com/problems/human-traffic-of-stadium/

/*
With CTE as
(
    Select * 
    From Stadium 
    Where people >= 100
),

CTE_1 as 
(
    Select id,
        visit_date,
        people,
        row_number() over(order by id asc) rn,
        id - row_number() over(order by id asc) diff        
    From CTE
),

CTE_2 as
(
    Select  id,
            visit_date,
            people,
            diff,
            count(diff) over(partition by diff) num_times
    From CTE_1
)

Select id,
       visit_date,
       people
From CTE_2
Where num_times >=3
Order by visit_date asc
*/

With CTE as 
(
Select 
        B.id,       
        B.visit_date,
        B.people /*, 
        ROW_NUMBER() OVER(Order By B.id asc) as row_num_B,
        B.id - ROW_NUMBER() OVER(Order By B.id asc) as diff*/
    From Stadium A Cross Join Stadium B
    Where  A.id - B.id = 1 and
           B.people >= 100 

Union 

# For an edge case where the last row with higher id passes the Where clause (for the SQL before UNION)
# But is never returned because I return B.id above. So below, we also return A.id for A.people

Select 
        A.id,       
        A.visit_date,
        A.people/*, 
        ROW_NUMBER() OVER(Order By B.id asc) as row_num_B,
        B.id - ROW_NUMBER() OVER(Order By B.id asc) as diff*/
    From Stadium A Cross Join Stadium B
    Where  A.id - B.id = 1 and
           A.people >= 100 
		   
),

cte1 as
(
    Select id,
        visit_date,
        people,
        ROW_NUMBER() OVER(Order By id asc) as row_num,
        id - ROW_NUMBER() OVER(Order By id asc) as diff
    From CTE
)

Select id,
       visit_date,
       people
From cte1
Where diff in 
        (
            Select diff
            From cte1
            Group By diff
            Having count(*) >= 3
        )

68)

https://leetcode.com/problems/average-salary-departments-vs-company/description/
615. Average Salary: Departments VS Company
/*
the DateRange CTE—is not recursive. It is a standard CTE.

The recursion happens in the second block (Calendar), but in SQL, if any part of a WITH statement is recursive, many 
dialects (like MySQL) require you to start the entire statement with the WITH RECURSIVE keyword.
*/

Solution 1:
============

# Write your MySQL query statement below
WITH
    S AS (
        SELECT *
        FROM
            Salary
            JOIN Employee USING (employee_id)
    ),
    T AS (
        SELECT
            DATE_FORMAT(pay_date, '%Y-%m') AS pay_month,
            department_id,
            AVG(amount) OVER (PARTITION BY pay_date, department_id) AS department_avg,
            AVG(amount) OVER (PARTITION BY pay_date) AS company_avg
        FROM S
    )
SELECT
    pay_month,
    department_id,
    CASE
        WHEN AVG(department_avg) > AVG(company_avg) THEN 'higher'
        WHEN AVG(department_avg) < AVG(company_avg) THEN 'lower'
        ELSE 'same'
    END AS comparison
FROM T
GROUP BY 1, 2;

Solution 2:
===========

With avg_monthly_dept_sal As
(
    Select  e.department_id,
            #s.pay_date,
            DATE_FORMAT(s.pay_date, '%Y-%m') as dept_mnth,
            avg(s.amount) as 'avg_dept_salary' #department_id is inclusive of all employees 

    From Employee e 
         Right Join Salary s 
            On e.employee_id = s.employee_id
    
    Group By e.department_id,
            #s.pay_date,
            DATE_FORMAT(s.pay_date, '%Y-%m')
),

/*
Select * 
From avg_monthly_dept_sal
*/

monthly_average_by_company As
(

Select #pay_date,
       DATE_FORMAT(pay_date, '%Y-%m') as comp_mnth,
       avg(amount) as 'avg_company_salary'
       
From Salary

Group by #pay_date,
       DATE_FORMAT(pay_date, '%Y-%m')  #or this is the monthly grouping

)

Select MDS.dept_mnth as pay_month,
       MDS.department_id as department_id,
       #MDS.avg_dept_salary,
       #MCS.avg_company_salary,
       CASE
          When MDS.avg_dept_salary > MCS.avg_company_salary Then 'higher'
          When MDS.avg_dept_salary < MCS.avg_company_salary Then 'lower'
          Else 'same'
       END as comparison

From avg_monthly_dept_sal as MDS Inner Join monthly_average_by_company as MCS
     On MDS.dept_mnth = MCS.comp_mnth

Group By 
       MDS.dept_mnth,
       MDS.department_id#,
       #MDS.avg_dept_salary,
       #MCS.avg_company_salary
	   
/*
	WITH MonthlyStats AS (
		SELECT 
			FORMAT(s.pay_date, 'yyyy-MM') AS pay_month,
			e.department_id,
			AVG(s.amount) OVER(PARTITION BY s.pay_date) AS company_avg,
			AVG(s.amount) OVER(PARTITION BY s.pay_date, e.department_id) AS dept_avg
		FROM salary s
		JOIN employee e ON s.employee_id = e.employee_id
	)
	SELECT DISTINCT
		pay_month,
		department_id,
		CASE 
			WHEN dept_avg > company_avg THEN 'higher'
			WHEN dept_avg < company_avg THEN 'lower'
			ELSE 'same'
		END AS comparison
	FROM MonthlyStats
	ORDER BY pay_month DESC, department_id;
*/

/*

############ BEGIN ENTERPRISE GRADE ##############################################

Here is the complete, enterprise-grade SQL query.

This version combines all the "Senior Architect" concepts we discussed: 
it is gap-proof (handles missing months), dynamic (scales with your data), and cleanly modularized using CTEs.
SQL.

/* 1. FIND THE BOUNDARIES: Dynamically get the first and last pay dates */
WITH RECURSIVE DateRange AS (
    SELECT 
        DATE_FORMAT(MIN(pay_date), '%Y-%m-01') AS start_date,
        DATE_FORMAT(MAX(pay_date), '%Y-%m-01') AS end_date
    FROM salary
),

/* 2. GENERATE DATE SPINE: Create a continuous list of months between those dates */
Calendar AS (
    SELECT CAST(start_date AS DATE) AS month_date FROM DateRange
    UNION ALL
    SELECT DATE_ADD(month_date, INTERVAL 1 MONTH)
    FROM Calendar, DateRange
    WHERE month_date < CAST(end_date AS DATE)
),

/* 3. FORMAT MONTHS: Standardize the 'YYYY-MM' format for the join key */
MonthSpine AS (
    SELECT DATE_FORMAT(month_date, '%Y-%m') AS pay_month
    FROM Calendar
),

/* 4. COMPANY STATS: Calculate monthly company average */
CompanyAvg AS (
    SELECT 
        DATE_FORMAT(pay_date, '%Y-%m') AS pay_month,
        AVG(amount) AS company_avg_by_month
    FROM salary
    GROUP BY pay_month
),

/* 5. DEPT STATS: Calculate monthly departmental average */
DeptAvg AS (
    SELECT 
        e.department_id,
        DATE_FORMAT(s.pay_date, '%Y-%m') AS pay_month,
        AVG(s.amount) AS dept_avg_by_month
    FROM salary s
    INNER JOIN employee e ON s.employee_id = e.employee_id
    GROUP BY e.department_id, pay_month
),

/* 6. UNIQUE DEPARTMENTS: Get a list of all depts to ensure visibility in every month */
AllDepartments AS (
    SELECT DISTINCT department_id FROM employee
)

/* 7. FINAL ARCHITECTURE: Join the Spine, Departments, and Averages */
SELECT 
    ms.pay_month,
    ad.department_id,
    CASE 
        WHEN da.dept_avg_by_month > ca.company_avg_by_month THEN 'higher'
        WHEN da.dept_avg_by_month < ca.company_avg_by_month THEN 'lower'
        WHEN da.dept_avg_by_month = ca.company_avg_by_month THEN 'same'
        ELSE 'no data' 
    END AS comparison
FROM MonthSpine ms
CROSS JOIN AllDepartments ad -- Every month gets a row for every department
LEFT JOIN DeptAvg da 
    ON ms.pay_month = da.pay_month 
    AND ad.department_id = da.department_id
LEFT JOIN CompanyAvg ca 
    ON ms.pay_month = ca.pay_month
ORDER BY ms.pay_month DESC, ad.department_id ASC;

Why this query earns an "A+" in an Interview:

    Resilience: If the university stops paying salaries in July (summer break), your query won't "break" or skip the month. It will show July with no data.

    Scalability: You aren't hardcoding 2017 or 2025. It looks at the Salary table and builds the report specifically for the window of time available.

    Completeness: By using a CROSS JOIN between MonthSpine and AllDepartments, you ensure that if Department A had no salaries but Department B did, both departments still appear in the report for that month.

Next Step: This covers the "Data Reporting" side of architecture. Would you like to switch to the "Data Cleaning" side and try a Deduplication problem? It involves merging two conflicting employee records, which is a key skill for the UT Austin legacy migration.

why is this query recursive? WITH RECURSIVE DateRange AS (

SELECT

DATE_FORMAT(MIN(pay_date), '%Y-%m-01') AS start_date,

DATE_FORMAT(MAX(pay_date), '%Y-%m-01') AS end_date

FROM salary

),

Actually, that specific block you highlighted—the DateRange CTE—is not recursive. It is a standard CTE.

The recursion happens in the second block (Calendar), but in SQL, if any part of a WITH statement is recursive, many dialects (like MySQL) require you to start the entire statement with the WITH RECURSIVE keyword.

Here is exactly why and where the recursion lives:
1. The "Base Case" (DateRange)

The DateRange block simply finds the "boundaries." It tells the computer: "Start at February 2017 and end at March 2017." This is a simple aggregate query.
2. The "Recursive Loop" (Calendar)

This is the part that actually uses recursion to create data out of thin air.

In the Calendar CTE (the block after the one you cited), the logic works like a for loop:

    The Anchor: It takes the start_date from DateRange. (e.g., Feb 1).

    The Recursion: It says, "Take the date I just made, add 1 month to it, and do it again."

    The Termination: It keeps looping until it hits the end_date (March 1).

Why we use this instead of a normal query

Normally, SQL is designed to filter or transform rows that already exist. It is not naturally good at generating rows that don't exist.

If your Salary table is missing a month, a normal SELECT can't "find" that month because it isn't there. Recursion allows the database to "count" or "generate" a complete timeline (the "Date Spine") so that we have a solid foundation to join our data onto.
Summary for your interview:

If they ask why you used RECURSIVE, your answer should be:

    "I used a recursive CTE to generate a continuous date spine. Since fact tables often have 'calendar gaps' where no transactions occurred, 
	the recursion allows us to programmatically build a complete monthly timeline to ensure our final report doesn't skip any periods."

"

###################### END ENTERPRISE GRADE QUERY #############################

*/

69)

https://leetcode.com/problems/find-median-given-frequency-of-numbers/description/
571. Find Median Given Frequency of Numbers


WITH RECURSIVE numbers_list AS 
(

	  SELECT    num,
				frequency
	  FROM Numbers
	  
	  UNION ALL
	   
	  SELECT    num,
				frequency-1
	  FROM      numbers_list 
	  WHERE     frequency - 1 > 0

),

cte1 as
(
	Select num,
		   frequency,
		   ROW_NUMBER() OVER() as row_num
	From numbers_list
	Order By num asc
)

#Select * from cte1


Select  CASE 

                WHEN 
                    
                    mod(max(row_num),2) = 0

                THEN                     
         
                    (
                    
                        Select avg(num) 

                        From cte1

                        Where row_num in 

                            (
								Select  max(row_num) div 2 From cte1
								Union 
								Select max(row_num) div 2 + 1 From cte1
                            )
                    )     
                
                ELSE

                    (
                    
                        Select num

                        From cte1

                        Where row_num in 

                            (
                              Select CEIL(max(row_num) div 2) + 1 #CEIL function in MySQL does not work so need to add 1
                              From cte1
                            )
                    )     
                

        END as 'median'

From   cte1        

70)

https://leetcode.com/problems/highest-grade-for-each-student/description/
1112. Highest Grade For Each Student
https://leetcode.ca/all/1112.html

Select 
     x.student_id,
     min(e1.course_id) as course_id,
     x.grade    

From 
(
    Select  student_id, 
            max(grade) as 'grade'

    From Enrollments 

    Group By student_id
) x
   Inner Join Enrollments e1
   On x.student_id = e1.student_id and 
      x.grade = e1.grade 
Group By x.student_id
Order By x.student_id asc

71)

#Unpopular Books
https://leetcode.com/problems/unpopular-books/description/
1098. Unpopular Books

# Write your MySQL query statement below

# for the last one year - find diff between today (given) and the available_from - 

# fothe last one month - find diff between today (given) and the dispatch_date - use PERIOD_DIFF

Select b.book_id, 
       b.name /*,
       b.available_from,
       TIMESTAMPDIFF(MONTH, b.available_from, '2019-06-23') 'months_available',
       COALESCE(o.quantity,0) 'copies_sold'*/

From Orders o Right Join Books b
      On o.book_id = b.book_id

Where TIMESTAMPDIFF(MONTH, b.available_from, '2019-06-23')  >= 1  # Exclude books available for less than 1 month
      
      #and o.dispatch_date between CAST('2018-06-23' as DATE) and CAST('2019-06-23' as DATE)
      and 
      365 >= DATEDIFF('2019-06-23', '2018-06-23')
      #o.dispatch_date >= DATE_SUB('2019-06-23', INTERVAL 1 YEAR) 

      OR 
      (
              
            o.order_id is null # valid book but never sold anything - refer to the right join
      )    

Group By b.book_id

HAVING SUM( 
            CASE 
                When o.dispatch_date >= DATE_SUB('2019-06-23', INTERVAL 1 YEAR) THEN quantity
                ELSE 0
            END 
          ) < 10


/*

			# same solution as above - DATE_SUB works because all dates in the table are earlier 
			# than '2019-06-23', otherwise BETWEEN was the correct option

			SELECT b.book_id,
				   b.name
				   /*,
				   b.available_from,
				   TIMESTAMPDIFF(MONTH, b.available_from, '2019-06-23') AS months_available,
				   COALESCE(o.quantity, 0) AS copies_sold
				   
			FROM Orders o
			RIGHT JOIN Books b
			  ON o.book_id = b.book_id
			WHERE TIMESTAMPDIFF(MONTH, b.available_from, '2019-06-23') >= 1
			  AND 365 >= DATEDIFF('2019-06-23', '2018-06-23')
			  OR (
				   o.order_id IS NULL
				 )
			GROUP BY b.book_id
			HAVING SUM(
					 CASE
					   WHEN o.dispatch_date >= DATE_SUB('2019-06-23', INTERVAL 1 YEAR)
					   THEN quantity
					   ELSE 0
					 END
				   ) < 10;


			# same solution as above  but with BETWEEN 

			SELECT b.book_id,
				   b.name
			FROM Orders o
			RIGHT JOIN Books b
			  ON o.book_id = b.book_id
			WHERE TIMESTAMPDIFF(MONTH, b.available_from, '2019-06-23') >= 1
			   OR o.order_id IS NULL
			GROUP BY b.book_id
			HAVING SUM(
					 CASE
					   WHEN o.dispatch_date BETWEEN DATE_SUB('2019-06-23', INTERVAL 1 YEAR)
												AND '2019-06-23'
					   THEN quantity
					   ELSE 0
					 END
				   ) < 10;
	   
3️⃣ Step 4: HAVING (Group-level filtering)
HAVING SUM(
         CASE
           WHEN o.dispatch_date BETWEEN DATE_SUB('2019-06-23', INTERVAL 1 YEAR)
                                    AND '2019-06-23'
           THEN quantity
           ELSE 0
         END
       ) < 10


This is the most important part.

Key Differences: WHERE vs HAVING
WHERE	                      HAVING
Filters rows	          Filters groups
Runs before aggregation	  Runs after aggregation
Cannot use SUM()	      Can use aggregates


Cleaner version from ChatGPT:

	SELECT b.book_id, b.name #imagine a quantity column here....
	FROM Books b
	LEFT JOIN Orders o
	  ON b.book_id = o.book_id
	 AND o.dispatch_date >= DATE_SUB('2019-06-23', INTERVAL 1 YEAR)
	WHERE b.available_from <= DATE_SUB('2019-06-23', INTERVAL 1 MONTH)
	GROUP BY b.book_id
	HAVING COALESCE(SUM(o.quantity), 0) < 10;

*/

72)

# https://leetcode.com/problems/project-employees-iii/description/
1077. Project Employees III

With cte as 
(

Select p.project_id, 
       e.employee_id,
       e.experience_years,
       DENSE_RANK() OVER(Order By e.experience_years) as d_rank
From Project p Inner Join Employee e
     On p.employee_id = e.employee_id
Order By p.project_id asc, 
         e.experience_years desc
) 


Select x.project_id, c.employee_id
From 
       (
            Select a.project_id, max(a.experience_years) as max_exp_years
            From cte a Inner Join cte b
                On a.project_id = b.project_id and 
                    a.employee_id = b.employee_id
            Group By a.project_id
        ) x 
        Inner Join cte c
        On x.project_id = c.project_id and 
           x.max_exp_years = c.experience_years
		   
/*
better options:

option 1:
========

SELECT project_id, employee_id
FROM Project
JOIN Employee USING (employee_id)
WHERE (project_id, experience_years) IN (
    SELECT p.project_id, MAX(e.experience_years)
    FROM Project p
    JOIN Employee e ON p.employee_id = e.employee_id
    GROUP BY p.project_id
);

Option 2:
=========

With CTE as 
(
Select p.project_id, 
       p.employee_id, 
       e.experience_years,
       dense_rank() Over (Partition By p.project_id Order By e.experience_years desc) as dr
       
From Project p 
     Inner Join Employee e 
     On p.employee_id = e.employee_id 
)



Select project_id, 
       employee_id
From CTE
Where dr = 1 

*/
		   
73)

#https://leetcode.com/problems/second-degree-follower/description/
614. Second Degree Follower


WITH CTE AS (
    SELECT DISTINCT followee
    FROM Follow
    WHERE followee IN (SELECT DISTINCT follower FROM Follow)
)
SELECT followee AS follower, COUNT(follower) AS num
FROM Follow
WHERE followee IN (SELECT followee FROM CTE)
GROUP BY followee
ORDER BY followee ASC;

VS

WITH CTE AS (
    SELECT DISTINCT followee 
    FROM Follow 
    WHERE followee IN (SELECT DISTINCT follower FROM Follow)
)
SELECT F.followee AS follower, COUNT(F.follower) AS num
FROM Follow F
JOIN CTE C ON F.followee = C.followee
GROUP BY F.followee
ORDER BY F.followee ASC;

vs
#complicated Solution
Select f.followee as follower, 
       /*# the users who follow (so they are first degree) but are also followees (as they are second degree)
       #f.follower  # the follower of the first result above */
       count(distinct f.follower) as num
From Follow f Inner Join 
    (#follows at least one user
        Select distinct follower
        From Follow
        Group By follower # wont work without Group By 
        Having count(distinct followee) >= 1 #follows at least one user
    ) x
    On f.followee = x.follower
Group By f.followee

74)

#https://leetcode.com/problems/get-highest-answer-rate-question/description/
578. Get Highest Answer Rate Question


With cte as 
(
Select  
        question_id,
        SUM(IF(action = 'show', 1, 0)) as 'total_times_shown',
        SUM(IF(action = 'answer', 1, 0)) as 'total_times_answered',
        round(SUM(IF(action = 'answer', 1, 0))/(SUM(IF(action = 'show', 1, 0)) + SUM(IF(action = 'answer', 1, 0))),2) as 'answer_rate'
From SurveyLog
Group By question_id       
)

Select question_id as survey_log /*,
       total_times_shown,
       total_times_answered,
       answer_rate*/
From cte
Where answer_rate = (Select max(answer_rate) From cte)
Order By answer_rate desc, 
         question_id asc
Limit 1

/*

	WITH T AS (
		SELECT
			question_id AS survey_log,
			(SUM(CASE WHEN action = 'answer' THEN 1 ELSE 0 END) OVER (PARTITION BY question_id)) / 
			NULLIF(SUM(CASE WHEN action = 'show' THEN 1 ELSE 0 END) OVER (PARTITION BY question_id), 0) AS ratio
		FROM SurveyLog
	)
	SELECT survey_log
	FROM T
	ORDER BY ratio DESC, survey_log
	LIMIT 1;

	NULLIF(..., 0) ensures you avoid dividing by zero by returning NULL if there are no 'show' actions for a particular question_id.

Why Use NULLIF?

	Avoid division by zero: As in the case of your original SQL query, NULLIF can be used to avoid errors when performing mathematical 
	operations, like division. If you're dividing by a value that could be 0, you can use NULLIF to turn that 0 into NULL, which you can 
	handle gracefully in your calculations.

Summary:

NULLIF returns NULL when the two expressions are equal.

It returns the first expression if the two are not equal.

It's useful for handling division by zero and ensuring clean query results.

*/

75)

#https://leetcode.com/problems/count-student-number-in-departments/description/
580. Count Student Number in Departments


Select d.dept_name,
       s.dept_id,
       count(s.dept_id) as student_number
From Student s Right Join Department d 
     On s.dept_id = d.dept_id
Group By d.dept_name
#Order By student_number desc

/*

	SELECT dept_name, COUNT(student_id) AS student_number
	FROM
		Department
		LEFT JOIN Student USING (dept_id)
	GROUP BY dept_id
	ORDER BY 2 DESC, 1;

		For departments where there are students, COUNT(student_id) will return the number of students (student_id is not NULL).

		For departments with no students (where student_id is NULL), COUNT(student_id) will return 0, because there are no non-null 
		student_id values in the result for that department.
	
*/
76)

#https://leetcode.com/problems/shortest-distance-in-a-plane/description/
612. Shortest Distance in a Plane


Select  #Min(
                round
                (
                        sqrt
                        (
                            power((a.x - b.x), 2) 
                            + 
                            power((a.y - b.y), 2)
                        )
                        ,
                        2                
                ) as shortest
            #) as shortest
From Point2D a Cross Join Point2D b
Having shortest <> 0 #can not be distance between the same two points
Order By shortest asc
Limit 1

77)

https://leetcode.ca/all/574.html
574. Winning Candidate

Select x.name
From Candidate c
	Left Join 
	(
		Select candidateID, count(candidateId) as num_votes
		From Votes
		Group By candidateID
	) x
        On c.id = x.candidateID
Order By x.num_votes desc
Limit 1

OR

Select c.name
From Candidate c
	Inner Join 
	(
		Select candidateID, count(candidateId) as num_votes
		From Votes
		Group By candidateID
	) x
        On c.id = x.candidateID
Having x.num_votes = (
                        Select max(x.num_votes) 
                        From 
                            (
                              Select candidateID, count(candidateId) as num_votes
							  From Votes
							  Group By candidateID
                            ) x
                     )
OR					 
Select /*c.id,
       COALESCE(v.candidateId,c.id) as candidateId,*/
       #count(v.candidateId) as num_votes,
       c.name
        /*
        COALESCE(v.candidateId,c.id) as candidateId, 
            count(COALESCE(v.candidateId,0)) as num_votes, 
            c.name
        */
From Vote v 
     Right Join Candidate c
     On v.candidateId = c.id
Group By c.id
Order By count(v.candidateId) desc
Limit 1

/*

Best Practice:
Note for future:

It is generally recommended to use a LEFT JOIN over a RIGHT JOIN for clarity and consistency. LEFT JOIN is more 
commonly used in SQL queries, and it tends to be easier to reason about for most people reading the query.

Many developers find LEFT JOIN more intuitive because it emphasizes the table that you're "starting from" (the left table), and 
it's easier to understand that all rows from the left table will be returned regardless of matches in the right table.

*/
78)

#https://leetcode.com/problems/team-scores-in-football-tournament/description/
1212. Team Scores in Football Tournament


Select COALESCE(x.team_id, t.team_id) as team_id,
       t.team_name,
       sum(COALESCE(x.num_points,0)) as num_points
From 
        (
            Select  match_id,
                    host_team as team_id,
                    CASE
                    When host_goals > guest_goals Then 3
                    When host_goals = guest_goals Then 1
                    Else 0
                    END as num_points
            From Matches

            Union All

            Select  match_id,
                    guest_team as team_id,
                    CASE
                    When guest_goals > host_goals Then 3
                    When guest_goals = host_goals Then 1
                    Else 0
                    END as num_points
            From Matches
        ) x
 
    Right Join Teams t
    On x.team_id = t.team_id 

Group By team_id

Order By num_points desc, team_id asc

vs
# from above website
# Write your MySQL query statement below
SELECT
    team_id,
    team_name,
    SUM(
        CASE
            WHEN team_id = host_team
            AND host_goals > guest_goals THEN 3
            WHEN team_id = guest_team
            AND guest_goals > host_goals THEN 3
            WHEN host_goals = guest_goals THEN 1
            ELSE 0
        END
    ) AS num_points
FROM
    Teams
    LEFT JOIN Matches ON team_id = host_team OR team_id = guest_team
GROUP BY 1
ORDER BY 3 DESC, 1;


79)

#https://leetcode.com/problems/bank-account-summary/description/
1555. Bank Account Summary


With cte as
(
        Select user_id, 
            amount,
            type
        From
            (
            Select paid_by as 'user_id', -1* sum(amount) as 'amount', 'paid' as type
            From Transactions
            Group By paid_by

            Union

            Select paid_to as 'user_id', sum(amount) as 'amount', 'recieved' as type
            From Transactions
            Group By paid_to
            ) x
),

#Select * From cte

cte1 as 
(
    Select user_id, sum(amount) as 'amt_left'
    from cte
    Group By user_id
)

#Select * from cte1

Select COALESCE(c1.user_id, u.user_id) as user_id, 
       u.user_name, 
       COALESCE(u.credit + c1.amt_left, u.credit) as credit,
       #u.credit as 'limit',
       CASE
            When u.credit + c1.amt_left < 0 Then 'Yes'
            When u.credit + c1.amt_left > 0 Then 'No'
            Else 'No'
       END as credit_limit_breached
From cte1 as c1 Right Join Users as u
     On c1.user_id = u.user_id
	 
80)

#https://leetcode.com/problems/friday-purchases-ii/description/
2994. Friday Purchases II


Select CASE
            When purchase_date between "2023-11-01" and "2023-11-07" Then 1
            When purchase_date between "2023-11-08" and "2023-11-15" Then 2
            When purchase_date between "2023-11-16" and "2023-11-23" Then 3
            Else 4
       END as week_of_month,
       purchase_date,
       sum(amount_spend) as total_amount

From Purchases

Where DAYNAME(purchase_date) = 'Friday' #and 
#      purchase_date between "2023-11-01" and "2023-11-30"

Group By 
        week_of_month, 
        purchase_date

Having count(user_id) >= 1

Order By week_of_month

or



    WITH RECURSIVE
        T AS (
            SELECT '2023-11-01' AS purchase_date
            UNION
            SELECT purchase_date + INTERVAL 1 DAY
            FROM T
            WHERE purchase_date < '2023-11-30'
        )
    SELECT
        CEIL(DAYOFMONTH(purchase_date) / 7) AS week_of_month,
        purchase_date,
        IFNULL(SUM(amount_spend), 0) AS total_amount
    FROM
        T
        LEFT JOIN Purchases USING (purchase_date)
    WHERE DAYOFWEEK(purchase_date) = 6
    GROUP BY 2
    ORDER BY 1;

or

WITH Fridays AS (
    -- Generate all Fridays in November 2023
    SELECT '2023-11-03' AS friday_date
    UNION ALL SELECT '2023-11-10'
    UNION ALL SELECT '2023-11-17'
    UNION ALL SELECT '2023-11-24'
),
AggregatedPurchases AS (
    -- Aggregate spending on Fridays
    SELECT 
        purchase_date,
        SUM(amount_spend) AS total_amount
    FROM Purchases
    WHERE DAYNAME(purchase_date) = 'Friday'
    AND purchase_date BETWEEN '2023-11-01' AND '2023-11-30'
    GROUP BY purchase_date
)
SELECT 
    WEEK(friday_date, 1) AS week_of_month,
    friday_date AS purchase_date,
    COALESCE(total_amount, 0) AS total_amount
FROM Fridays f
LEFT JOIN AggregatedPurchases ap ON f.friday_date = ap.purchase_date
ORDER BY week_of_month;



/*

Generate dates usig recursive queries and avoid hardcoding

option 1 to generate a table:
	
	With recursive cte as 

	(
		
		Select 1 as i,
			   min(purchase_date) as purchase_date,
				  
		From Purchases 
		
		Union 
		
		Select i+1 as i,
			   DATE_ADD(purchase_date INTERVAL 1 DAY) as purchase_date
		From cte
		Where DATE_ADD(purchase_date INTERVAL 1 DAY) <= (Select max(purchase_date) From Purchases) 
			
	)

option 2 to generate a table:


		WITH RECURSIVE AllDates AS (
			-- 1. Get the starting point
			SELECT MIN(purchase_date) AS purchase_date, 
				   MAX(purchase_date) AS max_date
			FROM Purchases
			
			UNION ALL
			
			-- 2. Add 1 day at a time until the max is reached
			SELECT DATE_ADD(purchase_date, INTERVAL 1 DAY), 
				   max_date
			FROM AllDates
			WHERE purchase_date < max_date
		)

		SELECT purchase_date 
		FROM AllDates;
		
Option 3: add an index:

		WITH RECURSIVE AllDates AS (
			-- Anchor: Get the start, the end, and initialize the index at 1
			SELECT 
				MIN(purchase_date) AS purchase_date, 
				MAX(purchase_date) AS max_date,
				1 AS idx
			FROM Purchases
			
			UNION ALL
			
			-- Recursive member: Increment the date and the index
			SELECT 
				DATE_ADD(purchase_date, INTERVAL 1 DAY), 
				max_date,
				idx + 1
			FROM AllDates
			WHERE purchase_date < max_date
		)

		SELECT 
			idx, 
			purchase_date 
		FROM AllDates;

Use option 3 with the Day of week function on the purchase date
		
		CTE1 as 
		(

			Select purchase_date,
				   sum(amount_spend) 'total_friday_spend'
			From Purchases p
			Where DAYOfWEEK(purchase_date) = 'Friday'
			Group By purchase_date 
		)

	    Join AllDates and CTE1 and get result -

Key Improvements Made:

    UNION ALL: Recursive CTEs in MySQL require UNION ALL. Using just UNION will throw an error.

    Pass the Max Date down: By selecting the MAX(purchase_date) once in the anchor (the first part), you pass it as a constant through the recursion. 
	This avoids running a subquery (Select max(...) From Purchases) hundreds or thousands of times.

    Syntactic Sugar: Added the final SELECT so the query actually returns results.

Why this is a "Staff-Level" approach:

When leading a team, performance and readability matter. This version:

    Reduces I/O: It only scans the Purchases table once to find the min and max.

    Is highly scalable: If your table had millions of rows, the subquery approach in your WHERE clause would cause significant lag as the recursion depth increases.

ALSO:

In MySQL, there are two reasons why you need UNION ALL for recursive CTEs: one is a strict syntax rule, and the other is a logic/performance requirement.
1. The Syntax Rule (Mandatory)

MySQL (and most SQL engines like PostgreSQL or SQL Server) explicitly requires UNION ALL to define a recursive CTE. If you try to use a plain UNION, the database will throw an error.

Why? A recursive CTE works by taking the result of the previous step and running the next step on it. A plain UNION performs a deduplication step (it looks for and removes duplicate rows). This "distinct" check would break the recursive process because the engine needs to keep every iteration moving forward to the next one.
2. Performance: Deduplication is Expensive

Even outside of recursive CTEs, you should prefer UNION ALL unless you specifically need to remove duplicates.

    UNION: The database must sort the combined results and compare every row to every other row to find duplicates. This is an O(nlogn) operation.

    UNION ALL: The database simply appends the second set of results to the first. This is a "pass-through" operation (O(1) per row), making it significantly faster for large datasets.

3. Logic: Why "Duplicates" Matter in Recursion

In your date-generator query, you are adding 1 day at a time. Every row generated is naturally unique because the date is changing (Nov 3, then Nov 4, then Nov 5...).

If you used a plain UNION:

    The database would stop to check if "Nov 4" already exists in the list every single time it generates a new day.

    Since you already know each day is new, this check is a complete waste of processing power.

Comparison Summary
Feature	UNION	UNION ALL
Duplicates	Removes them (Distinct)	Keeps them
Speed	Slower (requires sorting/hashing)	Much Faster (simple append)
Recursive CTEs	Not Allowed	Required

*/

81)

#https://leetcode.com/problems/apples-oranges/description/
1445. Apples & Oranges

/*

	Comparison: Complexity vs. Performance

	In a professional environment or a LeetCode-style interview, the goal is to achieve 
	the same robustness with the least amount of code and processing time.
	
	Feature	                  Your CTE + Union/Full Join	The Optimized Group By
	Handles missing apples?	          Yes	                         Yes
	Handles missing oranges?	      Yes	                         Yes
	Handles multiple rows/day?	      Yes	                         Yes
	Database Passes	               2-3 passes	                    1 pass
	Lines of Code	               ~20 lines	                    5 lines
*/

/*

	Database Passes (Performance)

	A "pass" is every time the database engine has to read the table from the disk.

		Your CTE + Union Approach (2-3 passes):

			Pass 1: Scan Sales to create the CTE.

			Pass 2: Scan the CTE to find all Apples.

			Pass 3: Scan the CTE again to find all Oranges for the UNION.

		The Optimized Group By (1 pass):

			Pass 1: The database reads the table once. As it sees an apple, it adds it to the "apple bucket"; as it sees an 
			orange, it adds it to the "orange bucket."

		Improvement: On a table with 10 million rows, 1 pass is significantly faster and uses much less I/O than 3 passes.
	
*/

-- if there are duplicate rows for a given fruit and sale date

With cte as
(
Select  fruit,
        sale_date, 
        sum(sold_num) as diff
From Sales
Group By fruit, sale_date
),

cte1 as
(
Select a.sale_date,
       a.diff - b.diff as diff       
From cte a Inner Join cte b
     On a.sale_date=b.sale_date
Where a.fruit <> b.fruit     
Group By a.sale_date
)

Select sale_date,
       diff
From cte1
Order by sale_date

or

WITH CTE AS (
    SELECT sale_date,
           SUM(CASE WHEN fruit = 'apples' THEN sold_num ELSE 0 END) AS apples_sold,
           SUM(CASE WHEN fruit = 'oranges' THEN sold_num ELSE 0 END) AS oranges_sold
    FROM Sales
    GROUP BY sale_date
)

SELECT sale_date,
       apples_sold - oranges_sold AS diff
FROM CTE
ORDER BY sale_date ASC;
or
SELECT
    sale_date,
    SUM(IF(fruit = 'apples', sold_num, 0)) - SUM(IF(fruit = 'oranges', sold_num, 0)) AS diff
FROM
    Sales
GROUP BY
    sale_date
ORDER BY
    sale_date;


or
let's address the edge case where either apples or oranges (or both) might be missing for a given sale_date. 
We'll use a FULL OUTER JOIN (or a LEFT JOIN with UNION) and COALESCE to handle this.

Using FULL OUTER JOIN (if your database supports it)
SQL

WITH AggregatedSales AS (
    SELECT
        fruit,
        sale_date,
        SUM(sold_num) AS total_sold
    FROM Sales
    GROUP BY fruit, sale_date
)
SELECT
    COALESCE(apple_sales.sale_date, orange_sales.sale_date) AS sale_date,
    COALESCE(apple_sales.total_sold, 0) - COALESCE(orange_sales.total_sold, 0) AS diff
FROM AggregatedSales AS apple_sales
FULL OUTER JOIN AggregatedSales AS orange_sales
    ON apple_sales.sale_date = orange_sales.sale_date
WHERE COALESCE(apple_sales.fruit, 'apples') = 'apples' AND COALESCE(orange_sales.fruit, 'oranges') = 'oranges'
ORDER BY sale_date;

or

Using LEFT JOIN and UNION (for databases without FULL OUTER JOIN)

SQL

WITH AggregatedSales AS (
    SELECT
        fruit,
        sale_date,
        SUM(sold_num) AS total_sold
    FROM Sales
    GROUP BY fruit, sale_date
)
SELECT
    apple_sales.sale_date,
    COALESCE(apple_sales.total_sold, 0) - COALESCE(orange_sales.total_sold, 0) AS diff
FROM AggregatedSales AS apple_sales
LEFT JOIN AggregatedSales AS orange_sales
    ON apple_sales.sale_date = orange_sales.sale_date AND orange_sales.fruit = 'oranges'
WHERE apple_sales.fruit = 'apples'

UNION
#why was the AND apple_sales.fruit = 'apples' needed in the On clause?
SELECT
    orange_sales.sale_date,
    COALESCE(apple_sales.total_sold, 0) - COALESCE(orange_sales.total_sold, 0) AS diff
FROM AggregatedSales AS orange_sales
LEFT JOIN AggregatedSales AS apple_sales
    ON orange_sales.sale_date = apple_sales.sale_date AND apple_sales.fruit = 'apples'
WHERE orange_sales.fruit = 'oranges' AND apple_sales.sale_date IS NULL
ORDER BY sale_date;

OR 
# just to highlight one example (apple on left, orange on right)

SELECT
    apple_sales.sale_date,
    COALESCE(apple_sales.total_sold, 0) - COALESCE(orange_sales.total_sold, 0) AS diff
FROM AggregatedSales AS apple_sales
LEFT JOIN AggregatedSales AS orange_sales
    ON apple_sales.sale_date = orange_sales.sale_date
WHERE apple_sales.fruit = 'apples' AND (orange_sales.fruit IS NULL OR apple_sales.fruit <> orange_sales.fruit);

82)
https://leetcode.com/problems/class-performance/description/
2989. Class Performance

/*
The group by clause is for when you want to create groups of data, and then calculate aggregate data for those 
groups. Since we want an aggregate on the entire dataset, we do not want to create groups.
*/
Select max(assignment1+assignment2+assignment3) - min(assignment1+assignment2+assignment3) as difference_in_score
From Scores

83)

https://leetcode.com/problems/the-number-of-seniors-and-juniors-to-join-the-company-ii/description/
2010. The Number of Seniors and Juniors to Join the Company II


With cte as

(
    Select 
        employee_id,
        salary,
        experience,
        row_number() Over(Order By experience, salary asc) as turn
    From Candidates c
),

# get higher ranked employee_id's (or Senior's)
cte1 as
(
    Select  employee_id,
            experience,
            salary,
            turn,
                (
                    Select sum(salary)
                    From cte c2
                    Where c2.turn <= c1.turn                 
                )  as 'budget_used',
                70000 -  (
                    Select sum(salary)
                    From cte c2
                    Where c2.turn <= c1.turn                 
                ) as 'remaining_budget'
    From cte c1
    Having budget_used <= 70000
),


#Select COALESCE(min(remaining_budget), 0)
#From cte1 

# get the remaining employee_id's (or Junior's)
cte2 as
(
    Select  employee_id,
            salary,
            experience,
            turn,
            (
                Select COALESCE(min(remaining_budget), 70000)
                From cte1 
            ) as remaining_budget
    From cte a 
    Where a.employee_id not in 
        (
        Select employee_id 
        From cte1     
        )
    Having salary <= remaining_budget
),

cte3 as
(
    Select  employee_id,
            experience,
            salary,
            turn,
            (
                Select sum(salary)
                From cte2 y
                Where y.turn <= x.turn                 
            )  as 'budget_used'       
            ,
            x.remaining_budget -  (
                Select sum(salary)
                From cte2 y
                Where y.turn <= x.turn                 
            ) as 'remaining_budget'

    From cte2 x
    Having remaining_budget >= 0
)

Select employee_id From cte1
Union
Select employee_id From cte3

/*

Option 1: From Feb 2025
========
#70,000
With CTE_senior as
(
	Select employee_id, 
		   experience, 
		   salary,
		   Dense_rank() over(PARTITION BY experience Order By salary asc) as rnk,
		   sum(salary) over (PARTITION BY experience Order By salary asc) as cumulative_salary		   
	From Candidates
	Where experience = 'senior'
),

Select *
From CTE

#11, 2 
CTE_1 as
(
	Select employee_id, experience, salary, rnk, cumulative_salary
	From CTE 
	Where cumulative_salary <= 70000 
), 

CTE_2 as
(
	Select 70000 - max(COALESCE(cumulative_salary,0)  as 'available_junior_budget'
	From CTE_1
),

With CTE_3 as
(
	Select employee_id, 
		   experience, 
		   salary,
		   Dense_rank() over(PARTITION BY experience Order By salary asc) as rnk,
		   sum(salary) over (PARTITION BY experience Order By salary asc) as cumulative_salary
		  
	From Candidates

	Where experience = 'junior'

)

Select * From CTE_3

CTE_4 as
(
	Select employee_id, experience, salary, rnk, cumulative_salary
	From   CTE 
	Where  cumulative_salary <= (Select available_junior_budget from CTE_2)
)

Select employee_id From CTE_2
UNION
Select employee_id from CTE_4

# Option 2: From Dev 2025

WITH senior_query AS (
    SELECT 
        employee_id, 
        SUM(salary) OVER(ORDER BY salary ASC) AS cum_sal,
        70000 - SUM(salary) OVER(ORDER BY salary ASC) AS remaining_budget
    FROM Candidates
    WHERE experience = 'Senior'
),
seniors_hired AS (
    SELECT employee_id, remaining_budget
    FROM senior_query
    WHERE cum_sal <= 70000
),
budget_for_juniors AS (
    -- If no seniors are hired, we use the full 70,000
    SELECT COALESCE(MIN(remaining_budget), 70000) AS val 
    FROM seniors_hired
),
junior_query AS (
    SELECT 
        employee_id, 
        SUM(salary) OVER(ORDER BY salary ASC) AS cum_sal
    FROM Candidates
    WHERE experience = 'Junior'
)
-- Final Output
SELECT employee_id FROM seniors_hired
UNION ALL
SELECT employee_id FROM junior_query
WHERE cum_sal <= (SELECT val FROM budget_for_juniors);

*/

84)

https://leetcode.com/problems/total-sales-amount-by-year/description/
1384. Total Sales Amount by Year

#HARD 
With cte as 
(
        Select s.product_id,
            s.average_daily_sales,
            #p.product_id, 
            p.product_name,
            CASE
                    When year(s.period_end) - year(s.period_start) = 0 Then 0
                    When year(s.period_end) - year(s.period_start) = 1 Then 1
                    When year(s.period_end) - year(s.period_start) = 2 Then 2
            END years_involved,
            DATEDIFF(s.period_end, s.period_start) as num_days,
            s.period_start,
            year(s.period_start) as year_start,
            s.period_end as period_end,
            year(s.period_end) as year_end

        From Sales s Left Join Product p
            On s.product_id = p.product_id
)
#Select * from cte
# Do UNIONS by year range


Select *
From 
(
         # When range is 2

            Select  product_id,
                    product_name,
                    year(period_start) as report_year, 
                    average_daily_sales * (DATEDIFF( "2018-12-31", period_start) + 1) as total_amount
            From cte
            Where years_involved = 2

            Union

            Select  product_id,
                    product_name,
                    '2019' as report_year,
                    average_daily_sales * (DATEDIFF( "2019-12-31", "2019-01-01") + 1) as total_amount
            From cte
            Where years_involved = 2

            Union 

            Select  product_id,
                    product_name,
                    year(period_end) as report_year,
                    average_daily_sales * (DATEDIFF( period_end, "2020-01-01") + 1) as total_amount
            From cte
            Where years_involved = 2

            Union 

            # When range is 0

            Select  product_id,
                    product_name,
                    year(period_end) as report_year,
                    average_daily_sales * (DATEDIFF( period_end, period_start) + 1) as total_amount
            From cte
            Where years_involved = 0


            # When range is 1
            #it can be:
            # 2018-2019 
            # 2019-2020

            Union

            Select  product_id,
                    product_name,
                    year(period_start) as report_year,
                    average_daily_sales * (DATEDIFF("2018-12-31", period_start) + 1) as total_amount
            From cte
            Where years_involved = 1 and year_start = '2018' and year_end = '2019'

            Union 

            Select  product_id,
                    product_name,
                    year(period_end) as report_year,
                    average_daily_sales * (DATEDIFF(period_end, "2019-01-01") + 1) as total_amount
            From cte
            Where years_involved = 1 and year_start = '2018' and year_end = '2019'

            Union

            Select  product_id,
                    product_name,
                    year(period_start) as report_year,
                    average_daily_sales * (DATEDIFF("2019-12-31", period_start) + 1) as total_amount
            From cte
            Where years_involved = 1 and 
			      year_start = '2019' and 
				  year_end = '2020'

            Union 

            Select  product_id,
                    product_name,
                    year(period_end) as report_year,
                    average_daily_sales * (DATEDIFF(period_end, "2020-01-01") + 1) as total_amount
            From cte
            Where years_involved = 1 and 
			      year_start = '2019' and 
				  year_end = '2020'
) x

Order By product_id, report_year

/*
WITH RECURSIVE DateTracker AS (
    -- Step 1: Get the absolute bounds
    SELECT MIN(period_start) AS report_date, 
           MAX(period_end) AS max_date 
    FROM Sales
    
    UNION ALL
    
    -- Step 2: Generate all days in between
    SELECT DATE_ADD(report_date, INTERVAL 1 DAY), 
           max_date
    FROM DateTracker
    WHERE report_date < max_date
)


-- Step 3: Join and Aggregate

SELECT 
    s.product_id,
    p.product_name,
    CAST(YEAR(d.report_date) AS CHAR) AS report_year,
    SUM(s.average_daily_sales) AS total_amount
FROM Sales s
JOIN Product p ON s.product_id = p.product_id
JOIN DateTracker d ON d.report_date BETWEEN s.period_start AND s.period_end
GROUP BY 1, 2, 3
ORDER BY 1, 3;
*/

85)

# 618. Students Report By Geography
# https://leetcode.com/problems/students-report-by-geography/description/

With cte1 As
(
    Select  
            CASE
            When continent = 'America' Then name Else null
            END  America,
    
            CASE
            When continent = 'Europe' Then name Else null
            END Europe,

            CASE
            When continent = 'Asia'   Then name Else null
            END Asia

    From Student 
),

cte2 as 
(
    Select America,
           row_number() Over(Order By America asc) rnum_America
    From cte1
    Where America is not null   # this eliminates conflict in the numbering of rows containing null and the asc order in the row_number() Order By
),

#Select * From cte2

cte3 as 
(
    Select Europe,
           #Asia,
           row_number() Over(Order By Europe asc) rnum_Europe #,
           #row_number() Over(Order By Asia desc) rnum_Asia 
    From cte1   
    Where Europe is not null 
),

#Select * From cte3

cte4 as 
(
    Select #Europe,
           Asia,
           #row_number() Over(Order By Europe desc) rnum_Europe #,
           row_number() Over(Order By Asia asc) rnum_Asia 
    From cte1   
    Where Asia is not null 
)

Select a.America, 
       c.Asia,
       b.Europe       

From cte2 a 
     Left Join cte3 b
     On a.rnum_America = b.rnum_Europe

     Left Join cte4 c
     On a.rnum_America = c.rnum_Asia    
/*
	With CTE_America as (
		Select name, ROW_NUMBER() OVER(ORDER BY name) as rn
		From student Where continent = 'America'
	), 
	-- ... do the same for Asia and Europe ...

	Select a.name as America, asia.name as Asia, e.name as Europe
	From CTE_America a
	Left Join CTE_Asia asia ON a.rn = asia.rn
	Left Join CTE_Europe e ON a.rn = e.rn
*/
86)

https://leetcode.com/problems/hopper-company-queries-iii/description/
1651. Hopper Company Queries III

WITH RECURSIVE cte AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 12
),

cte1 AS
(
    Select n,
        month,
        average_ride_distance,
        average_ride_duration
    From 
    (
            Select  n,
                    month, 
                    sum(average_ride_distance) average_ride_distance,
                    sum(average_ride_duration) average_ride_duration

            From 
            (
                    Select 
                        x.month,
                        cte.n, 
                        x.ride_distance,
                        x.ride_distance/3 average_ride_distance,
                        x.ride_duration,
                        x.ride_duration/3 average_ride_duration,
                        x.year
                    From 
                        (
                            Select a.ride_id, 
                            month(requested_at) as month,
                            sum(a.ride_distance) as ride_distance, 
                            sum(a.ride_duration) as ride_duration,
                            year(requested_at) as year

                            From   AcceptedRides a 
                                Inner Join Rides r
                                On a.ride_id = r.ride_id

                            Where year(requested_at) = '2020'

                            Group By a.ride_id, year(requested_at), month(requested_at)
                        ) x 
                        Right Join cte 
                        On x.month = cte.n
            ) y

            Group By n
    ) z
),

cte2 As 
(
        Select n,
            ifnull(month,n),
            ifnull(average_ride_distance, 0) as average_ride_distance,
            ifnull(average_ride_duration, 0) as average_ride_duration
        From cte1
),

cte3 as
(
SELECT n as 'month',
       sum(average_ride_distance) OVER(ORDER BY n ASC ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) as 'average_ride_distance',
       sum(average_ride_duration) OVER(ORDER BY n ASC ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) as 'average_ride_duration'
FROM cte2)

Select month,
       round(average_ride_distance,2) as average_ride_distance,
       round(average_ride_duration,2) as average_ride_duration
From cte3 
Where month not in (11, 12);

/*
	WITH RECURSIVE cte_MonthList AS (
		-- 1. Create months 1 through 12
		SELECT 1 AS month_num
		UNION ALL
		SELECT month_num + 1 FROM cte_MonthList WHERE month_num < 12
	),
	MonthlyStats AS (
		-- 2. Calculate the SUM for each month individually
		SELECT 
			c.month_num,
			SUM(IFNULL(a.ride_distance, 0)) AS month_dist,
			SUM(IFNULL(a.ride_duration, 0)) AS month_dur
		FROM cte_MonthList c
		LEFT JOIN Rides r 
			ON c.month_num = MONTH(r.requested_at) 
			AND YEAR(r.requested_at) = 2020
		LEFT JOIN AcceptedRides a 
			ON r.ride_id = a.ride_id
		GROUP BY c.month_num
	)

	-- 3. Use Window Functions to get the 3-month rolling average
	SELECT 
		month_num AS month,
		ROUND(SUM(month_dist) OVER(ORDER BY month_num ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) / 3, 2) AS average_ride_distance,
		ROUND(SUM(month_dur) OVER(ORDER BY month_num ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) / 3, 2) AS average_ride_duration
	FROM MonthlyStats
	LIMIT 10; -- Only 10 windows are possible (Jan-Mar through Oct-Dec)
*/
87)

#https://leetcode.com/problems/median-employee-salary/description/
#569. Median Employee Salary


Select y.id,
       y.company,
       y.salary/*,
       y.c_rows,
       y.row_num   */
From 
(
        Select 
            e.id as id, 
            e.company as company, 
            e.salary as salary,        
            x.c_rows as c_rows,
            ROW_NUMBER() OVER(PARTITION BY e.company ORDER BY e.company asc, e.salary asc) as row_num
        From Employee e
            Inner Join 
                (
                    Select company, 
                        count(*) as c_rows,
                        salary
                    From Employee
                    Group By company
                ) x
            On e.company = x.company
) y

Where 
      #Even Case
      (
        mod(c_rows,2) = 0 and 
        (
             c_rows DIV 2      = row_num or
            (c_rows DIV 2) + 1 = row_num
        )
      )
      
      OR    
    
      #Odd Case
      (
        mod(c_rows,2) <> 0 and 
        (
            #div(c_rows,2) = row_num or
            CEIL(c_rows div 2)+1 = row_num #CEIL function in MySQL does not work so need to add 1
        )
      ) 

/*
	# this solution is a hint not a working solution as the id's are not ordered by increasing salary to give correct median 
	
		With CTE as 
		(
			Select Company, 
				   max(id) as max_id, 
				   min(id) as min_id
				   max(id) - min(id) + 1 as num_rows
				   Case 
					When max(id) - min(id) + 1 % 2 == 0 
					Then 'Even'
					Else 'Odd'
				   End Count_type		   
			From Employee
			Group By Company 
		)

		# separate odd and even cases 

		#Odd Case 

		Select e.Id, 
			   e.Company, 
			   e.Salary 
		From Employee e
		Where e.Id = ( Select CEIL(DIV(max_id + min_id, 2))
					   From   CTE 
					   Where  Company = e.Company and 
							  count_type = 'Odd'
					 )
					 
		# Even case 

		Select 
			e.Company, 
			AVG(e.Salary) as MedianSalary
		From Employee e
		Where e.Id IN ( 
						Select DIV(max_id + min_id, 2)
						From   CTE 
						Where  Company = e.Company and 
							   Count_type = 'Even'
					  )
		   OR e.Id IN ( 
						Select DIV(max_id + min_id, 2) + 1
						From   CTE 
						Where  Company = e.Company and 
							   Count_type = 'Even'
					  )
		Group By e.Company;	 

  # a working solution from GPT which does not need separate odd even cases:
   # STEP 1: Rank every employee by salary within their company
		With RankedEmployees as (
			Select 
				Id, 
				Company, 
				Salary,
				ROW_NUMBER() OVER(PARTITION BY Company ORDER BY Salary, Id) as row_num
			From Employee
		),
		# STEP 2: Find the max row number per company to determine middle points
		CTE_Stats as (
			Select 
				Company, 
				MAX(row_num) as total_rows,
				-- The middle point logic (handles both Odd and Even)
				(MAX(row_num) + 1) / 2.0 as middle_index
			From RankedEmployees
			Group By Company
		)

		# STEP 3: Select the average salary for the rows that hit the middle index
		Select 
			r.Company, 
			AVG(r.Salary) as MedianSalary
		From RankedEmployees r
		Join CTE_Stats s ON r.Company = s.Company
		Where r.row_num BETWEEN s.middle_index - 0.5 AND s.middle_index + 0.5
		Group By r.Company;
		
Why does this work for both odd and even cases: 
	1. The Odd Case (Total Rows = 5)

		The Math: (5+1)/2.0=3.0

		The Range: 3.0 - 0.5 to 3.0 + 0.5 → [2.5 to 3.5]

		The Result: Only row_num = 3 falls in this range. The query returns the single middle salary.

	2. The Even Case (Total Rows = 6)

		The Math: (6+1)/2.0=3.5

		The Range: 3.5 - 0.5 to 3.5 + 0.5 → [3.0 to 4.0]

		The Result: Both row_num = 3 and row_num = 4 fall in this range. The query returns both salaries, and AVG() calculates the median.
*/     
88)


Select passenger_id,
       CASE 
          When running_capacity > capacity Then 'Waitlist'
          Else 'Confirmed'
        End as 'Status'

From 

(
	Select passenger_id,
		   p.flight_id,
		   ROW_NUMBER() OVER(PARTITION BY flight_id Order By booking_time asc) as 'running_capacity', #see commented code for different windows function
		   f.capacity,
		   booking_time
	From Passengers p Inner Join Flights f
		 On p.flight_id = f.flight_id
) x

Order By passenger_id asc

/*
Select 

    x.passenger_id, 
    CASE
        When f.capacity >= x.attempted_bookings_so_far Then 'Confirmed'
        Else 'Waitlist'
    END status
    

From Flights f 
     Left Join 
        (
            Select 
                    passenger_id,
                    flight_id,
                    booking_time,
                    count(flight_id) Over(partition by flight_id order by booking_time asc) attempted_bookings_so_far
            From Passengers 
        ) x 
    On f.flight_id = x.flight_id

Where x.flight_id is not null

Order by x.passenger_id asc
*/

/*
https://leetcode.ca/2023-07-14-2783-Flight-Occupancy-and-Waitlist-Analysis/
Select  f.flight_id, 

        Case 
		
         When count(distinct p.passenger_id) >= f.capacity 
		 Then f.capacity 		 
		 
		 Else count(distinct p.passenger_id)
		 
		End booked_cnt,
		
		Case 
		
		 When count(distinct p.passenger_id) > f.capacity 
		 Then count(distinct p.passenger_id) - f.capacity
		 
	     Else 
		 0
		 
		End waitlist_cnt

From Flights f
     Left Join Passengers p 	 
     On f.flight_id = p.flight_id

Group By f.flight_id, f.capacity
*/

89)


Select passenger_id,
       CASE 
          When running_capacity > capacity Then 'Waitlist'
          Else 'Confirmed'
        End as 'Status'

From 

(
Select passenger_id,
       p.flight_id,
       ROW_NUMBER() OVER(PARTITION BY flight_id Order By booking_time asc) as 'running_capacity',
       f.capacity,
       booking_time
From Passengers p Inner Join Flights f
     On p.flight_id = f.flight_id
) x

Order By passenger_id asc


90)

https://leetcode.com/problems/get-the-second-most-recent-activity/description/
1369: 1369. Get the Second Most Recent Activity

Select username, activity, startDate, endDate
From 
(
    Select c1.username, 
           c1.activity, 
           max(c1.startDate) as startDate, 
           max(c1.endDate) as endDate
    From UserActivity c1
         Inner Join UserActivity c2
         On c1.username = c2.username 
    Where c1.startDate < 
        (
            Select max(c2.startDate)
            From UserActivity c2
            Where c1.username = c2.username #and c1.activity = c2.activity            
        )
        and 
        c1.endDate <
        (
            Select max(c2.endDate)
            From UserActivity c2
            Where c1.username = c2.username #and c1.activity = c2.activity            
        ) 
    Group By c1.username
) x

Union 

Select username, activity, startDate, endDate
From UserActivity
Group By username
Having count(username) = 1

/*

Better Solution:

		WITH CTE AS (
			SELECT
				username,
				activity,
				startDate,
				endDate,
				row_number() OVER (PARTITION BY username ORDER BY endDate DESC) AS rn
			FROM UserActivity
		)


		Select  username,
				activity,
				startDate,
				endDate
		From CTE
		Where rn = 2 

		Union 

		Select 
				username,
				activity,
				startDate,
				endDate
		From CTE
		Group By username
		Having count(username) = 1
		
Or this is the Gemini solution:

WITH CTE AS (
    SELECT
        username,
        activity,
        startDate,
        endDate,
        row_number() OVER (PARTITION BY username ORDER BY endDate DESC) AS rn
    FROM UserActivity
)
SELECT username, activity, startDate, endDate
FROM CTE
WHERE rn = 2

UNION ALL

SELECT username, activity, startDate, endDate
FROM CTE
WHERE rn = 1 AND username NOT IN (SELECT username FROM CTE WHERE rn = 2)

Or these two below:


Option 1:

WITH CTE AS (
    SELECT *, 
           DENSE_RANK() OVER(PARTITION BY username ORDER BY startDate DESC) as dr,
           COUNT(*) OVER(PARTITION BY username) as cnt
    FROM UserActivity
)
SELECT username, activity, startDate, endDate
FROM CTE
WHERE (cnt > 1 AND dr = 2) OR (cnt = 1 AND dr = 1);


Option 2:

With CTE as 
(
	Select username, 
		   activity, 
		   startDate,
		   endDate,
		   dense_rank() over(Partition By username order by startDate desc) dr
	From UserActivity
),

CTE1 as 
(
	Select u.username, 
		   u.activity, 
		   u.startDate, 
		   u.endDate
	From CTE u
	Where u.dr = 
				(  # Find the max dr for each username
					 Select max(u1.dr) 
					 From CTE u1
					 Where u1.username = u.username
				)
	Having u.dr = 1 #narrow down to those that have dr of 1
)

Select  username, 
		activity, 
		startDate, 
		endDate
From  CTE
Where dr = 2

Union

Select  username, 
		activity, 
		startDate, 
		endDate
From  CTE1

Option 3:
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY username ORDER BY endDate DESC) as rn,
        COUNT(*) OVER(PARTITION BY username) as total
    FROM UserActivity
)
SELECT username, activity, startDate, endDate
FROM CTE
WHERE rn = 2 OR (total = 1 AND rn = 1);
*/

91)

https://leetcode.com/problems/generate-the-invoice/description/
2362. Generate the Invoice

With CTE as
(
            Select  y.invoice_id,
                    y.product_id,
                    y.quantity,
                    y.total_agg_price,
                    ROW_NUMBER() OVER (Order By y.total_agg_price) as row_num,
                    RANK() OVER (Order By y.total_agg_price desc) as rnk

            From (
                    Select
                        x.invoice_id,
                        x.product_id,
                        x.quantity,
                        sum(x.total_price) as 'total_agg_price'
                    From 
                        (

                            Select 
                                p.invoice_id,
                                p.product_id,
                                p.quantity,
                                #o.price,
                                sum(p.quantity*o.price) as 'total_price'

                            From Purchases p Inner Join Products o 
                                On p.product_id = o.product_id

                            Group By p.invoice_id,
                                    p.product_id,
                                    p.quantity 
                            
                            Order By total_price desc

                        ) x

                    Group By  x.invoice_id

                ) y 

            Order By rnk asc, 
                     y.total_agg_price desc
)

# Based on grouping above, the max price with lowest rank is 

Select p.product_id, 
       p.quantity,
       o.price * p.quantity as price
From Purchases p 
     Inner Join Products o
     On p.product_id = o.product_id
Where p.invoice_id in (
        Select min(invoice_id) as invoice_id
        from cte 
        where rnk = 1
    ) 
	
/*

		# Another possible solution

		With CTE_1 as
		(
			Select  pu.invoice_id,
					p.product_id, 
					p.price,
					pu.quantity,
					pu.quantity * p.price as invoice_value_by_product,
					ROW_NUMBER() Over (partition by invoice_id order by product_id asc) rn
				From Products p
					Left Join Purchases pu
					On p.product_id = pu.product_id   
		),


		CTE_2 as
		(
				Select invoice_id,
					sum(price * quantity) as invoice_value_overall
				From CTE_1
				Group By invoice_id
				Order by sum(quantity) desc
		),

		CTE_3 as
		(
				Select product_id, 
					quantity,
					price,
					price*quantity as val,
					CTE_1.invoice_id,
					invoice_value_overall
				From CTE_1 
					Inner Join CTE_2
					On CTE_1.invoice_id = CTE_2.invoice_id
				Order By invoice_value_overall desc, invoice_id asc
		),

		CTE_4 as
		(
				Select distinct invoice_id
				From CTE_3
				Where invoice_value_overall = (Select max(invoice_value_overall) From CTE_3)
				Order By invoice_id asc
				Limit 1
		)

		Select product_id,
			   quantity,
			   #price,
			   val as price
		From CTE_3
		Where invoice_id = (Select invoice_id From CTE_4)
		Order By price desc

Question about two CTEs CTE1 and cte2
		Description

		Table: Products

		+-------------+------+
		| Column Name | Type |
		+-------------+------+
		| product_id  | int  |
		| price       | int  |
		+-------------+------+
		product_id is the primary key for this table.
		Each row in this table shows the ID of a product and the price of one unit.

		 

		Table: Purchases

		+-------------+------+
		| Column Name | Type |
		+-------------+------+
		| invoice_id  | int  |
		| product_id  | int  |
		| quantity    | int  |
		+-------------+------+
		(invoice_id, product_id) is the primary key for this table.
		Each row in this table shows the quantity ordered from one product in an invoice. 

		 

		Write an SQL query to show the details of the invoice with the highest price. If two or more invoices have the same price, return the details of the one with the smallest invoice_id.

		Return the result table in any order.

		The query result format is shown in the following example.

		Will the two CTE's give the same resume?

		Example 1:

		Input: 
		Products table:
		+------------+-------+
		| product_id | price |
		+------------+-------+
		| 1          | 100   |
		| 2          | 200   |
		+------------+-------+
		Purchases table:
		+------------+------------+----------+
		| invoice_id | product_id | quantity |
		+------------+------------+----------+
		| 1          | 1          | 2        |
		| 3          | 2          | 1        |
		| 2          | 2          | 3        |
		| 2          | 1          | 4        |
		| 4          | 1          | 10       |
		+------------+------------+----------+
		Output: 
		+------------+----------+-------+
		| product_id | quantity | price |
		+------------+----------+-------+
		| 2          | 3        | 600   |
		| 1          | 4        | 400   |
		+------------+----------+-------+
		Explanation: 
		Invoice 1: price = (2 * 100) = $200
		Invoice 2: price = (4 * 100) + (3 * 200) = $1000
		Invoice 3: price = (1 * 200) = $200
		Invoice 4: price = (10 * 100) = $1000

		The highest price is $1000, and the invoices with the highest prices are 2 and 4. We return the details of the o

		#Query 1

		With CTE1 as 
		(
		Select pr.invoice_id, 
			   sum(pr.quantity*p.price) total_invoice_price
			  
		From Products p 
			 Inner Join Purchases pr
			 On p.product_id = pr.product_id 

		Group By pr.invoice_id
		)

		Select * From CTE1

		#Query 2

		With CTE2 as 
		(
		Select pr.invoice_id, 
			   sum(pr.quantity*p.price) Over(Partition By pr.invoice_id) total_invoice_price


		From Products p 
			 Inner Join Purchases pr
			 On p.product_id = pr.product_id 

		)

		Select * From CTE2

		/*
		Key difference: number of rows returned
		✅ Query 1 (GROUP BY)
		WITH CTE1 AS (
			SELECT pr.invoice_id,
				   SUM(pr.quantity * p.price) AS total_invoice_price
			FROM Products p
			JOIN Purchases pr
			  ON p.product_id = pr.product_id
			GROUP BY pr.invoice_id
		)
		SELECT * FROM CTE1;


		Result characteristics

		One row per invoice

		Aggregated at the invoice level

		Perfect for:

		Finding the highest invoice total

		Ranking invoices

		Filtering by max price

		Example output

		invoice_id | total_invoice_price
		-----------+--------------------
		1          | 200
		2          | 1000
		3          | 200
		4          | 1000

		❌ Query 2 (Window Function)
		WITH CTE2 AS (
			SELECT pr.invoice_id,
				   SUM(pr.quantity * p.price)
				   OVER (PARTITION BY pr.invoice_id) AS total_invoice_price
			FROM Products p
			JOIN Purchases pr
			  ON p.product_id = pr.product_id
		)
		SELECT * FROM CTE2;


		Result characteristics

		One row per purchase line

		Invoice total is repeated for each product in that invoice

		Does not reduce rows

		Example output

		invoice_id | total_invoice_price
		-----------+--------------------
		2          | 1000
		2          | 1000
		4          | 1000
		1          | 200
		3          | 200


		(Invoice 2 appears twice because it has two products.)
*/


*/

#479 Sales by Day of the Week
https://leetcode.com/problems/sales-by-day-of-the-week/description/

92)

Select 
      CASE 
        When y.inner_date >= '2023-11-01' and y.inner_date <= '2023-11-07' Then 1
        When y.inner_date >= '2023-11-08' and y.inner_date <= '2023-11-14' Then 2
        When y.inner_date >= '2023-11-15' and y.inner_date <= '2023-11-21' Then 3
        When y.inner_date >= '2023-11-22' and y.inner_date <= '2023-11-28' Then 4
        ELSE 0
      END as week_of_month,

      y.inner_date as purchase_date,   
      
      COALESCE(sum(amount_spend),0) as total_amount

From   (
            Select x.inner_date
            From 
            (
                SELECT STR_TO_DATE("November 3 2023", "%M %d %Y") as inner_date
                Union
                SELECT STR_TO_DATE("November 10 2023", "%M %d %Y") as inner_date
                Union
                SELECT STR_TO_DATE("November 17 2023", "%M %d %Y") as inner_date
                Union
                SELECT STR_TO_DATE("November 24 2023", "%M %d %Y") as inner_date
            ) x
        ) y

       Left Join Purchases p 
       On y.inner_date = p.purchase_date

#Where DAYOFWEEK(purchase_date) = 6 and 
#      Month(purchase_date) = 11 

Group By inner_date, 
         week_of_month, 
         purchase_date

Order By week_of_month asc

93)

# 1479. Sales by Day of the Week
# https://leetcode.com/problems/sales-by-day-of-the-week/description/

Select Category,
       sum(MONDAY) as MONDAY, 
                sum(TUESDAY) as TUESDAY,
                sum(WEDNESDAY) as WEDNESDAY, 
                sum(THURSDAY) as THURSDAY,
                sum(FRIDAY) as FRIDAY, 
                sum(SATURDAY) as SATURDAY,
                sum(SUNDAY) as SUNDAY

From 

(
            
            Select 
                Category,
                sum(MONDAY) as MONDAY, 
                sum(TUESDAY) as TUESDAY,
                sum(WEDNESDAY) as WEDNESDAY, 
                sum(THURSDAY) as THURSDAY,
                sum(FRIDAY) as FRIDAY, 
                sum(SATURDAY) as SATURDAY,
                sum(SUNDAY) as SUNDAY
            From 
                (
                    Select 

                            distinct i.item_category as Category,                            
                            CASE    When DAYOFWEEK(o.order_date) = 2 Then COALESCE(sum(o.quantity),0) ELSE 0 END as MONDAY,
                            CASE    When DAYOFWEEK(o.order_date) = 3 Then COALESCE(sum(o.quantity),0) ELSE 0 END as TUESDAY,
                            CASE    When DAYOFWEEK(o.order_date) = 4 Then COALESCE(sum(o.quantity),0) ELSE 0 END as WEDNESDAY,
                            CASE    When DAYOFWEEK(o.order_date) = 5 Then COALESCE(sum(o.quantity),0) ELSE 0 END as THURSDAY,
                            CASE    When DAYOFWEEK(o.order_date) = 6 Then COALESCE(sum(o.quantity),0) ELSE 0 END as FRIDAY,
                            CASE    When DAYOFWEEK(o.order_date) = 7 Then COALESCE(sum(o.quantity),0) ELSE 0 END as SATURDAY,
                            CASE    When DAYOFWEEK(o.order_date) = 1 Then COALESCE(sum(o.quantity),0) ELSE 0 END as SUNDAY
                    
                    From Orders o 
                            Inner Join Items i 
                            On o.item_id = i.item_id

                    Group By i.item_category, DAYOFWEEK(o.order_date)
                ) x

            Group By Category

            Union 

            Select 

                                distinct i.item_category as Category,            
                                0 as MONDAY, 
                                0 as TUESDAY,
                                0 as WEDNESDAY, 
                                0 as THURSDAY,
                                0 as FRIDAY, 
                                0 as SATURDAY,
                                0 as SUNDAY

            From Items i
                            Left Join Orders o
                            On i.item_id = o.item_id

            Where o.item_id is null

            Group By i.item_category, DAYOFWEEK(o.order_date)

) x 

Group By Category
Order By Category

/*
The simple, correct solution (not over-engineered)
		✅ Start from Items
		✅ LEFT JOIN to Orders
		✅ Conditional aggregation
		✅ One GROUP BY
		SELECT
			i.item_category AS Category,

			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 2 THEN o.quantity ELSE 0 END) AS MONDAY,
			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 3 THEN o.quantity ELSE 0 END) AS TUESDAY,
			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 4 THEN o.quantity ELSE 0 END) AS WEDNESDAY,
			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 5 THEN o.quantity ELSE 0 END) AS THURSDAY,
			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 6 THEN o.quantity ELSE 0 END) AS FRIDAY,
			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 7 THEN o.quantity ELSE 0 END) AS SATURDAY,
			SUM(CASE WHEN DAYOFWEEK(o.order_date) = 1 THEN o.quantity ELSE 0 END) AS SUNDAY

		FROM Items i
		LEFT JOIN Orders o
			ON o.item_id = i.item_id

		GROUP BY i.item_category
		ORDER BY i.item_category;

		Why this version is better
			Aspect	                    Your version	Simplified version
			Number of SELECT layers	         4	               1
			UNION needed	                Yes	        ❌ No
			Multiple GROUP BYs	            Yes	        ❌ No
			Handles zero-order categories	Yes	    ✅ Yes
			Readability	                   Hard	    Clear
			Performance	                   Worse	Better
*/


94)

Option 1:
========
5%

With CTE as 
(
    Select managerId, 
        count(distinct id) as num_reports
    From Employee 
    Where managerId is not null
    Group By managerId
    Having count(managerId) >= 5
)

Select name 
From Employee
Where id in 
(      
    Select managerId
    From CTE
)

Option 2:
=========
11%

With CTE as
(
	Select managerId,
           name,
		   id, 
		   row_number() over (Partition By managerId Order By id asc) rn
	From Employee
	Where managerId is not null
	
)

#Select * From CTE

Select name 
From Employee
Where id in 
    (
        Select managerId  -- this returns 101
        From CTE
        Where rn >= 5
    )

Option 3:
=========
67.59%
======

Select name 
From Employee e
     Inner Join 
     (
            Select managerId, 
                count(id) as num_reports
            From Employee 
            Where managerId in
                    ( 
                        #get just the managerID and their names
                        Select distinct managerId
                        From Employee
                        Where managerId is not null
                    ) 
            Group By managerId
            Having count(id) >= 5
     ) x
     On
     e.id = x.managerId
Order By name asc

95)


#https://leetcode.com/problems/department-top-three-salaries/description/
185. Department Top Three Salaries

Select x.dept_name Department,
       x.emp_name Employee,
       x.Salary
From 
(
    Select e.id,
        e.name as emp_name,
        d.name as dept_name,
        e.salary,
        #ROW_NUMBER() OVER(order by e.salary) as rownumber,
        #RANK()       OVER(Order By e.salary) as rank1,
        DENSE_RANK() OVER(PARTITION BY d.name order by e.salary desc) as denserank

    From Employee e Inner Join Department d
        On e.departmentid = d.id    

    #Group By e.id

    #Order By d.name, e.salary desc
) x

Where x.denserank < 4
Order By Department, Salary desc


/*
#Other option:
With CTE as
(
        Select 
            departmentId,
            name, #Employee name
            salary, 
            rnk
        From 
            (
                Select distinct departmentId,
                                        name, #Employee name
                                        salary,
                                        dense_rank() Over(partition by departmentId Order By salary desc) rnk
                From Employee
            ) x
        Where rnk < 4
)


Select d.name   as Department, #department name
       c.name   as Employee,   #employee name
       c.salary as Salary      #salary
From Department d 
        Inner Join CTE c
         On d.id = c.departmentId
*/

96)

Select 
      id,
     'Root' as type
From Tree
Where p_id is null

Union 

#Both a parent and child node
Select distinct t1.id, 'Inner'
From Tree t1
     Inner Join Tree t2
     On t1.id = t2.p_id
Where t1.p_id is not null

Union 

Select id,
       'Leaf'
From Tree
Where id not in 
(
    Select id
    From Tree
    Where id in (Select p_id From Tree) # nodes that are also parents
)
and p_id is not null

/*

#option 1:
=========

# Write your MySQL query statement below
# root

With Root as
(
    Select id, 
           'Root' as type
    From Tree
    Where p_id is null
),

# Leaf node 
# excludes root and the nodes with kids
Leaf as 
(
    Select  id, 
       'Leaf' as type
    From Tree
    Where id not in 
                (
                        Select distinct p_id From Tree Where p_id is not null # Get all parents to ignore
                        Union
                        Select distinct id From Root 
                        #and exclude the root we found earlier. 
                        #This also handles special case when root and leaf are same i.e a 1-node tree
                ) 
),

# Inner Nodes (everything else - that is not a root or lea)
Inner_Node as 
(
    Select id, 'Inner' as type
    From Tree 
    Where id not in ( 
                      Select id From Root 
                      Union 
                      Select id From Leaf
                    )
)

Select id, type From Root
Union
Select id, type From Leaf
Union
Select id, type From Inner_Node

*/

97)

Market analysis 1: https://leetcode.com/problems/market-analysis-i/description/
1158. Market Analysis I


Table: Users

+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| user_id        | int     |
| join_date      | date    |
| favorite_brand | varchar |
+----------------+---------+
user_id is the primary key (column with unique values) of this table.
This table has the info of the users of an online shopping website where users can sell and buy items.

 

Table: Orders

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| order_id      | int     |
| order_date    | date    |
| item_id       | int     |
| buyer_id      | int     |
| seller_id     | int     |
+---------------+---------+
order_id is the primary key (column with unique values) of this table.
item_id is a foreign key (reference column) to the Items table.
buyer_id and seller_id are foreign keys to the Users table.

 

Table: Items

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| item_id       | int     |
| item_brand    | varchar |
+---------------+---------+
item_id is the primary key (column with unique values) of this table.

 

Write a solution to find for each user, the join date and the number of orders they made as a buyer in 2019.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Users table:
+---------+------------+----------------+
| user_id | join_date  | favorite_brand |
+---------+------------+----------------+
| 1       | 2018-01-01 | Lenovo         |
| 2       | 2018-02-09 | Samsung        |
| 3       | 2018-01-19 | LG             |
| 4       | 2018-05-21 | HP             |
+---------+------------+----------------+
Orders table:
+----------+------------+---------+----------+-----------+
| order_id | order_date | item_id | buyer_id | seller_id |
+----------+------------+---------+----------+-----------+
| 1        | 2019-08-01 | 4       | 1        | 2         |
| 2        | 2018-08-02 | 2       | 1        | 3         |
| 3        | 2019-08-03 | 3       | 2        | 3         |
| 4        | 2018-08-04 | 1       | 4        | 2         |
| 5        | 2018-08-04 | 1       | 3        | 4         |
| 6        | 2019-08-05 | 2       | 2        | 4         |
+----------+------------+---------+----------+-----------+
Items table:
+---------+------------+
| item_id | item_brand |
+---------+------------+
| 1       | Samsung    |
| 2       | Lenovo     |
| 3       | LG         |
| 4       | HP         |
+---------+------------+
Output: 
+-----------+------------+----------------+
| buyer_id  | join_date  | orders_in_2019 |
+-----------+------------+----------------+
| 1         | 2018-01-01 | 1              |
| 2         | 2018-02-09 | 2              |
| 3         | 2018-01-19 | 0              |
| 4         | 2018-05-21 | 0              |
+-----------+------------+----------------+



Select  u.user_id as buyer_id,
        u.join_date,
        SUM(IF (YEAR(o.order_date) = '2019', 1, 0)) as 'orders_in_2019'

From Users u 

     Left Join Orders o 
     On u.user_id = o.buyer_id

     Left Join Items i
     On o.item_id = i.item_id

#Where o.buyer_id is null
#Where u.user_id in (4,5,9,15,17,18)

Group By u.user_id

Order By u.user_id asc

98)

/*

1393. Capital Gain/Loss
https://leetcode.com/problems/capital-gainloss/description/

option 1:
Select stock_name, 
       sum(price) as capital_gain_loss
From
    (
        Select  stock_name, 
                operation,
                operation_day,
                CASE
                    When operation = 'Buy' then -1*price
                    Else price
                END as price
        From Stocks
    ) x
Group By stock_name

option 2:
Select stock_name,
       sum(total_gained) as capital_gain_loss
From
    (
        Select stock_name,
               (-1 * sum(price)) as total_gained
        From Stocks
        Where operation = 'Buy'
        Group By stock_name

        Union

        Select stock_name,
               sum(price) as total_gained
        From Stocks
        Where operation = 'Sell'
        Group By stock_name
    ) x
Group By stock_name

*/

Select x.stock_name,
       x.total_val - y.total_val as 'capital_gain_loss'
From (
            Select stock_name, 
                operation, 
                sum(price) total_val
            From Stocks
            Group By stock_name, 
                    operation
      ) x
      Inner Join 
      (
            Select stock_name, 
                operation, 
                sum(price) total_val
            From Stocks
            Group By stock_name, 
                    operation
      ) y
      On x.stock_name = y.stock_name
Where x.operation = 'Sell' and 
      y.operation = 'Buy'
	  
99)

/*
178. Rank Scores

https://leetcode.com/problems/rank-scores/submissions/1572724829/
INCORRECT APPROACH: 

Using partition means the lowest rank will once again be re-set to 1 for a new sub-group or a new partition.
But we don't want to rank within sub-groups and then reset to 1 and re-rank within the next subgroup.
We want a global ranking. No a local, sub-group based ranking. Therefore, the "Partition By score" in the 
brackets is in-correct."

    So, the follwing solution is in-correct:
    
    Select  score,
        dense_rank() Over (Partition By score  Order By score desc) as 'rank'
    From Scores
	
*/

SELECT
    score,
    DENSE_RANK() OVER (Order By score desc) AS rank
FROM
    Scores;
	
100)

184. Department Highest Salary
https://leetcode.ca/all/184.html


/*

#partition by departmentId, order by salary desc
# from the test cases, it seems if there are departments with no employees (so no salaries), 
# such null cases are good to catch, but for ranking purposes should be ignored:


Output <--- this is good to catch, but to be ignored for ranking purposes
| Department | Employee | Salary |
| ---------- | -------- | ------ |
| Sales      | null     | null   |


Expected <-- for cases like above filter out in the sub-query where clause
| Department | Employee | Salary |
| ---------- | -------- | ------ |

option 1:

	Select Department, 
		   Employee,
		   Salary
	From 
		(
			Select d.name as Department, 
				e.name as Employee, 
				e.salary as Salary, 
				dense_rank() Over (Partition By d.name Order By e.salary desc) as rnk

			From Employee e
				Right Join Department d 
				On e.departmentId = d.id

			Where e.name is not null and e.salary is not null
		) x
	Where x.rnk = 1

option 2:

To understand SQL really well, solve without using windows function...

SELECT
    Department,
    Employee,
    Salary
FROM (
    SELECT
        d.Name AS Department,
        e.Name AS Employee,
        e.Salary,
        DENSE_RANK() OVER (
            PARTITION BY d.Id
            ORDER BY e.Salary DESC
        ) AS rnk
    FROM Department d
    JOIN Employee e
        ON d.Id = e.DepartmentId
) ranked_employees
WHERE rnk = 1;


*/

Select #e1.departmentID, 
        d.name as Department,
       e1.name as Employee, 
       e1.Salary as Salary
From Employee e1 
        Inner Join
           (   #get max salary by name, id, departmentID
               Select max(e2.Salary) as Salary, e2.departmentID
               From Employee e2
               Group By departmentID
           ) e2
        On 
        e1.Salary = e2.Salary and 
        e1.departmentId = e2.departmentID 

        Inner Join Department d
        On 
        e1.departmentId = d.id
#Group By e1.departmentId #, e1.id, e1.name   

Or

101)

# 550. Game Play Analysis IV
/*
This is the wrong answer. Here is why:

Query 2 is indeed overcounting in the context of the problem's requirements.

Here's why we can definitively say Query 2 overcounts:

    Problem Requirement: The problem asks for the fraction of players who logged in on the day after the day they first logged in. This implies a specific sequence: identify the first login, then check for a login on the immediately following day.
    Query 2's Logic: Query  checks for any consecutive login days, regardless of whether the second day is the day immediately following the player's first login.
    Overcounting Scenario: As illustrated in my previous example, a player could have logins on 2024-01-03 and 2024-01-04. Query 2 would count this as a consecutive login, even if the player's first login was on 2024-01-01. This player does not satisfy the problem's condition of logging in on the day after their first login, but Query 2 would still include them in the count.

Therefore, below query includes players in its count who should not be included according to the problem's precise wording, leading to an overcount.

Select 

    round
        (
                x.con_player_count
                    /
                (
                    Select count(distinct player_id) 
                    From Activity
                )
            
        ,
        2
        ) as fraction
From 
    (
        Select count(distinct a1.player_id) as con_player_count      

        From Activity a1
            Inner Join Activity a2
            On a1.player_id = a2.player_id

        Where DATEDIFF(a1.event_date, a2.event_date) = 1 #consecutive days
    ) x

View less

*/

Select round( y.player_con_days
               /
              (
                Select count(distinct player_id) 
                From Activity
              ), 
              2
            ) as 'fraction'
From 
    (
        Select count(distinct a.player_id)  as 'player_con_days'            
        From   Activity a Inner Join 
                    (
                        Select  player_id, 
                                min(event_date) as event_date
                        From Activity                
                        #Where games_played >0 #? Do you need this condition
                        Group By player_id
                    ) x
                On a.player_id = x.player_id        
        Where DATEDIFF(a.event_date, x.event_date) = 1
    ) y
	
102)

# see solution number 29 above for a similar Solution

Select name
From Employee e 
Where e.id in (Select distinct managerID from Employee) #this gets all the managers
      and EXISTS
      (
          Select x.managerID
          From Employee x
          Where x.managerID = e.id F
          Having count(x.managerID) >= 5
      )
	  
103)

/*

1070: Product Sales Analysis III

Table: Sales

+-------------+-------+
| Column Name | Type  |
+-------------+-------+
| sale_id     | int   |
| product_id  | int   |
| year        | int   |
| quantity    | int   |
| price       | int   |
+-------------+-------+
(sale_id, year) is the primary key (combination of columns with unique values) of this table.
product_id is a foreign key (reference column) to Product table.
Each row of this table shows a sale on the product product_id in a certain year.
Note that the price is per unit.

 

Table: Product

+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| product_id   | int     |
| product_name | varchar |
+--------------+---------+
product_id is the primary key (column with unique values) of this table.
Each row of this table indicates the product name of each product.

 

Write a solution to select the product id, year, quantity, and price for the first year of every product sold.

Return the resulting table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Sales table:
+---------+------------+------+----------+-------+
| sale_id | product_id | year | quantity | price |
+---------+------------+------+----------+-------+ 
| 1       | 100        | 2008 | 10       | 5000  |
| 2       | 100        | 2009 | 12       | 5000  |
| 7       | 200        | 2011 | 15       | 9000  |
+---------+------------+------+----------+-------+
Product table:
+------------+--------------+
| product_id | product_name |
+------------+--------------+
| 100        | Nokia        |
| 200        | Apple        |
| 300        | Samsung      |
+------------+--------------+
Output: 
+------------+------------+----------+-------+
| product_id | first_year | quantity | price |
+------------+------------+----------+-------+ 
| 100        | 2008       | 10       | 5000  |
| 200        | 2011       | 15       | 9000  |
+------------+------------+----------+-------+

This query has more data in the join condition so runs slower

Select s.product_id, 
       s.year as first_year,
       s.quantity,
       s.price
From Sales s 
     Inner Join 
        (
            Select product_id, 
                   min(year) as first_year 
            From Sales
            Group By product_id
        ) x
     On s.product_id = x.product_id /*and 
        s.year = x.first_year
		# the join condition could have narrowed down the intermediate dataset more - resulting in less space usage and 
		# faster run time
		
Where s.year = x.first_year
*/ 

# anytime you narrow down the data set more before the Where clause filters out the joined data - results in a faster query 
# but takes up more and takes up less space

Select x.product_id, 
       x.first_year as first_year,
       s1.quantity, 
       s1.price       
From Sales s1 Inner Join 
        (   #Get the first year of every product sold
            Select s.product_id, min(year) as first_year
            From Sales s Inner Join Product p 
                On s.product_id = p.product_id
            Group By s.product_id
            Order by min(year) asc
        ) x    
    On s1.product_id = x.product_id 
    and s1.year = x.first_year
	
104)
/*

	Select s.user_id, 
		   #SUM(IF (c.action = 'timeout', 1, 0)) as num_timeouts,
		   #SUM(IF (c.action = 'confirmed', 1, 0)) as num_confirmations,
		   COALESCE(round
			 (
				SUM(IF (c.action = 'confirmed', 1, 0))
				/
				SUM(IF (c.action = 'timeout', 1, 0) + IF (c.action = 'confirmed', 1, 0))
				,
				2
			 ), 0) confirmation_rate
	From Signups s
		 Left Join Confirmations c
		 On s.user_id = c.user_id
	Group By s.user_id

*/

# https://leetcode.com/problems/confirmation-rate/description/

Select s.user_id, round(count(c.user_id),2) as confirmation_rate
From Signups s Left Join Confirmations c
     On s.user_id = c.user_id
Where c.user_id is null
Group By s.user_id


/*

	“Idiomatic MySQL” means writing SQL the way experienced MySQL users naturally do it—using MySQL’s strengths, common patterns, and 
	concise expressions instead of verbose or overly generic SQL.
 	Think of it as the difference between:
	Correct but clunky
	Clean, natural, and immediately recognizable as MySQL

		Idiomatic MySQL Version of Your Problem

		Here’s how a senior MySQL engineer / interviewer would expect to see it:

		SELECT 
			s.user_id,
			ROUND(COALESCE(AVG(c.action = 'confirmed'), 0), 2) AS confirmation_rate
		FROM Signups s
		LEFT JOIN Confirmations c
			ON s.user_id = c.user_id
		GROUP BY s.user_id;

		Why this is idiomatic

		✔ Uses boolean aggregation
		✔ No CTE needed
		✔ No CASE statements
		✔ Handles missing confirmations automatically
		✔ Concise and expressive

		Interviewer Perception
		Style	Reaction
		Verbose CASE-heavy SQL	“They know SQL basics”
		Idiomatic MySQL	“They’ve used MySQL in production”
		Rule of Thumb

		If your SQL:

		Has many CASE WHEN
		Manually counts booleans
		Feels “procedural”
		…it’s probably not idiomatic.
		
		If it:

		Uses AVG(condition)
		Uses COALESCE
		Reads almost like English
		…it is idiomatic MySQL.
		
		Applied to division
		SUM(x) / NULLIF(SUM(y), 0)

		What happens
		SUM(y)	NULLIF(SUM(y), 0)	Result
		5	5	Normal division
		1	1	Normal division
		0	NULL	Division becomes x / NULL
		Why this avoids the error

		In SQL:

		Division by 0 → runtime error
		Division by NULL → result is NULL (no error)
		So:
		10 / NULL   -- returns NULL, not an error
		That’s the entire trick. NULLIF converts a dangerous 0 into a harmless NULL.


		SELECT 
			s.user_id,
			ROUND(COALESCE(AVG(c.action = 'confirmed'), 0), 2) AS confirmation_rate
		FROM Signups s
		LEFT JOIN Confirmations c
			ON s.user_id = c.user_id
		GROUP BY s.user_id;
		
		Look at: 
		ROUND(COALESCE(AVG(c.action = 'confirmed'), 0), 2)
		
		5️⃣ Interview-Ready One-Liner Explanation

		If asked “Why doesn’t this divide by zero?”, say:

		“AVG() never divides by zero because it only operates on non-NULL values and returns NULL when there are 
		no rows. I then use COALESCE to convert that NULL into 0.”
		
		That answer alone signals strong SQL fundamentals.
		
		When there is no action (i.e., no matching rows after a LEFT JOIN):

		AVG() does not divide by 0.

		What it does instead:

		It sees no non-NULL values
		It returns NULL
		No division is performed at all
		So the direct answer:
		👉 AVG() returns NULL, not an error, and does not attempt division.
		That’s why we then use:
		COALESCE(AVG(...), 0)
		to turn that NULL into 0.
		
*/

105)

#1193. Monthly Transactions I
https://leetcode.com/problems/monthly-transactions-i/description/

Select  DATE_FORMAT(trans_date,'%Y-%m') as 'month',
        country,
        count(distinct id) as 'trans_count',        
        sum(if  (state = 'approved', 1, 0)) as 'approved_count',
        sum(amount) as 'trans_total_amount',
        sum(if  (state = 'approved', amount, 0)) as 'approved_total_amount'      
From Transactions 
Group By DATE_FORMAT(trans_date,'%Y-%m'), 
         country 

/*
That's an excellent question! In the context of the LeetCode problem you linked, using SUM(CASE WHEN ... THEN 1 ELSE 0 END) instead of SUM(IF(...)) would 
achieve the exact same result and is often considered more standard SQL.

Let's break down the difference and why they are equivalent in this specific scenario:

SUM(IF(condition, value_if_true, value_if_false))

    This is a more concise way (in some SQL dialects like MySQL) to perform conditional aggregation within a SUM() function.
    condition: A boolean expression to evaluate.
    value_if_true: The value to add to the sum if the condition is true.
    value_if_false: The value to add to the sum if the condition is false.

SUM(CASE WHEN condition THEN value ELSE 0 END)

    This is the more standard SQL way to handle conditional logic within aggregate functions. It's more portable across different database systems.
    CASE WHEN condition THEN value: If the condition is true, then value is considered for the sum.
    ELSE 0 END: If the condition is false, then 0 is considered for the sum, effectively not adding anything to the total.

Why They Are Equivalent in This Case

In your LeetCode query, you have these two expressions:

    sum(if (state = 'approved', 1, 0)) as 'approved_count'
    sum(if (state = 'approved', amount, 0)) as 'approved_total_amount'

If you were to rewrite these using CASE, they would become:

    sum(CASE WHEN state = 'approved' THEN 1 ELSE 0 END) as 'approved_count'
    sum(CASE WHEN state = 'approved' THEN amount ELSE 0 END) as 'approved_total_amount'

The logic is identical:

    For 'approved_count', when state is 'approved', you add 1 to the sum; otherwise, you add 0. This effectively counts the number of 'approved' transactions.
    For 'approved_total_amount', when state is 'approved', you add the amount to the sum; otherwise, you add 0. This effectively calculates the total amount of 'approved' transactions.

Advantages of CASE WHEN:

    Standard SQL: It's more widely recognized and supported across different SQL database systems (like PostgreSQL, SQL Server, Oracle, etc.). 
	              This makes your queries more portable.
    Readability (for complex conditions): When you have more complex conditions or multiple conditions (using ELSE IF), CASE statements can become 
	        more readable and easier to follow than nested IF functions (if your SQL dialect supports nested IF within SUM).

Disadvantages of CASE WHEN (minor in this context):

    It can be slightly more verbose than IF in simple conditions, but the difference is usually negligible.

In conclusion, for this specific LeetCode problem, using SUM(CASE WHEN ...) is a perfectly valid and often preferred alternative to SUM(IF(...)). 
It achieves the same result with the benefit of being standard SQL. 
You could confidently replace the IF statements with their CASE WHEN equivalents in your solution.
*/

106)
#1045. Customers Who Bought All Products
#https://leetcode.com/problems/customers-who-bought-all-products/description/

/*

	Select x.customer_id
	From 
		(
			Select customer_id,
				   count(distinct product_key) 'num_bought'
			From Customer
			Group By customer_id
			Having num_bought = (Select count(distinct product_key) From Product)
		) x   
	
*/

Select customer_id
From 
    (
    Select x.customer_id as customer_id,
           x.prod_bought
    From (
            Select c.customer_id, 
                   count(distinct c.product_key) as prod_bought
            From Customer c
            Group By c.customer_id
    ) x
    Having x.prod_bought = (Select count(distinct product_key) From Product)
) y;

107)


/*
#176. Second Highest Salary
Select max(salary) as 'SecondHighestSalary'
From Employee
Where salary <
        (
            Select max(salary)
            From Employee
        )
*/

Select COALESCE(max(salary)) SecondHighestSalary
/*CASE 
          When count(salary) = 0 then null Else salary
       End SecondHighestSalary*/
From Employee 
Where salary <
(
    Select max(salary)
    From Employee
    Order By salary desc
)
Order By salary desc;
#Limit 1;

108)

/*

Select round(sum(i.tiv_2016), 2) as tiv_2016 

From Insurance i

Where i.tiv_2015 in 

     (
        Select j.tiv_2015 
        From Insurance j
        Where i.pid <> j.pid
     )

     and (i.lat, i.lon) not in 

     (
        Select k.lat, k.lon
        From Insurance k
        Where i.pid <> k.pid
     )

*/

/*

# 

	SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016
	FROM (
		SELECT *,
			   COUNT(*) OVER(PARTITION BY tiv_2015) AS tiv_count,
			   COUNT(*) OVER(PARTITION BY lat, lon) AS loc_count
		FROM Insurance
	) AS sub
	WHERE tiv_count > 1 AND loc_count = 1;
	
	+-----+----------+----------+-----+-----+-----------+-----------+
	| pid | tiv_2015 | tiv_2016 | lat | lon | tiv_count | loc_count |
	+-----+----------+----------+-----+-----+-----------+-----------+
	| 1   | 10       | 5        | 10  | 10  | 3         | 1         |
	| 2   | 20       | 20       | 20  | 20  | 1         | 2         |
	| 3   | 10       | 30       | 20  | 20  | 3         | 2         |
	| 4   | 10       | 40       | 40  | 40  | 3         | 1         |
	+-----+----------+----------+-----+-----+-----------+-----------+

This query uses Window Functions to analyze the data. Unlike a standard GROUP BY, which collapses multiple rows into one, window 
functions allow you to perform calculations across a set of rows while still keeping every individual row visible.

Here is the breakdown of what each part is doing:

1. The Core Concept: OVER(PARTITION BY ...)

The PARTITION BY clause tells the database to divide the rows into groups (or "windows") based on the values in a specific column. 
The calculation—in this case, COUNT(*)—is then performed separately for each group.

2. COUNT(*) OVER(PARTITION BY tiv_2015)

    What it does: It looks at the tiv_2015 value of the current row.

    The logic: It finds all other rows in the table that have that same tiv_2015 value and counts them.

    The Result (tiv_count): Every row gets a new number.

        If tiv_count > 1, it means this policyholder shares their 2015 investment value with at least one other 
		person (meeting the first criteria of your problem).

3. COUNT(*) OVER(PARTITION BY lat, lon)

    What it does: It looks at the specific "city" (the latitude/longitude pair) of the current row.
	
    The logic: It counts how many rows exist with that exact same lat and lon.
	
    The Result (loc_count): * If loc_count = 1, it means the location is unique—no other policyholder is in that city (meeting 
	the second criteria of your problem).
	
*/

/*

		select round(sum(tiv_2016),2) as tiv_2016
		From Insurance
		Where tiv_2015 in
		(
			Select i.tiv_2015
			From Insurance i
			Where i.tiv_2015 in 
				( 
					Select x.tiv_2015 
					From Insurance x
					Where #i.pid <> x.pid and 
						i.tiv_2015 = x.tiv_2015
					Having count(*) > 1
				)
			Group By i.tiv_2015
		)
		and (lat, lon) in 
		( 
			Select lat, lon 
			From Insurance 
			#Where #i.pid <> x.pid and 
			#        tiv_2015 = x.tiv_2015
			Group By lat, lon # count(*) tells us how many rows exist in this group
			Having count(*) = 1
		)

		In the context of your SQL query, COUNT(*) is an aggregate function that counts the total number of rows within a specific group.

		When you use it with a GROUP BY and a HAVING clause, it acts as a filter for the groups themselves rather than for individual rows.

		Here is exactly how it functions in your two specific cases:
		
		1. HAVING COUNT(*) > 1 (The "Duplicate" Finder)

		In your first subquery, you are looking for tiv_2015 values that are shared by multiple people.

			The Logic: The database groups all rows that have the same tiv_2015 value.

			What COUNT(*) does: It counts how many rows (policyholders) are in each of those groups.

			The Filter: By saying HAVING COUNT(*) > 1, you are telling the database: "Only give me the tiv_2015 values that appear more than once in the table."

		2. HAVING COUNT(*) = 1 (The "Uniqueness" Finder)

		In your second subquery, you are looking for unique locations.

			The Logic: You GROUP BY lat, lon. This creates a group for every unique "city" or coordinate pair.

			What COUNT(*) does: It counts how many rows exist for each specific coordinate pair.

			The Filter: By saying HAVING COUNT(*) = 1, you are telling the database: "Only give me the locations where exactly one person lives."

		Why use * instead of a column name?

			COUNT(*): Counts every row in the group, including those with NULL values (though in your table, the columns are guaranteed to be non-NULL).

			COUNT(column_name): Only counts rows where that specific column is not NULL.

			In your case: Since you just want to know "how many rows exist in this group," COUNT(*) is the standard and most efficient way to write it.

		Visual Summary

		Imagine your data looks like this for lat, lon:
		lat	lon	Group Size (COUNT(*))		Result of HAVING COUNT(*) = 1
		10	10		1							Keep (Unique city)
		20	20		2							Discard (Shared city)
		40	40		1							Keep (Unique city)

*/

109)

#602. Friend Requests II: Who Has the Most Friends

/*

Select x.id, 
       sum(x.num_freinds) as num
From 
(
        Select requester_id as id, 
            count(distinct accepter_id) as num_freinds
        From RequestAccepted
        Group By requester_id

        Union All

        Select accepter_id as id, 
            count(distinct requester_id) as num_friends
        From RequestAccepted
        Group By accepter_id
) x
Group By x.id
Order By num desc
Limit 1
*/
Select x.id as id,
       sum(x.num) as num
        From 
        (
                Select accepter_id as id,
                    count(distinct requester_id) as num
                From RequestAccepted 
                Group By accepter_id

                Union All

                Select requester_id as id,
                    count(distinct accepter_id) as num
                From RequestAccepted 
                Group By requester_id
        ) x
Group By id
Order By num desc
Limit 1;

110)

#https://leetcode.com/problems/restaurant-growth/description/
1321. Restaurant Growth

Select y.visited_on,
       y.amount,
       round((y.amount/7), 2) average_amount
From 
(
    Select c1.visited_on as visited_on,
			(
					Select sum(c2.amount)
					From Customer c2
					Where c2.visited_on between DATE_ADD(c1.visited_on, INTERVAL -6 DAY) and c1.visited_on                         
			) as amount
    From Customer c1
) x Cross Join 
   (
    Select c1.visited_on as visited_on,
        (
                Select sum(c2.amount)
                From Customer c2
                Where c2.visited_on between DATE_ADD(c1.visited_on, INTERVAL -6 DAY) and c1.visited_on                         
        ) as amount
    From Customer c1
   ) y
Where x.visited_on = y.visited_on - interval 6 day
Group By y.visited_on, y.amount

/*
-- calculating moving averages:

SELECT
    visited_on,
    amount,
    average_amount
FROM (
    SELECT
        visited_on,
        SUM(amount) OVER (
            ORDER BY visited_on
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as amount,
        AVG(amount) OVER (
            ORDER BY visited_on
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as average_amount,
        DENSE_RANK() OVER (ORDER BY visited_on) as dr
    FROM
        Customer
) sub
WHERE
    dr > 6;
	
	====
	
for the average calculation part:

option 1:
	
	SELECT 
    c1.visited_on, 
    c1.amount, 
    ROUND(c1.amount / 7, 2) AS average_amount
FROM Customer c1
JOIN Customer c2 
    ON c1.visited_on = DATE_ADD(c2.visited_on, INTERVAL 6 DAY)
GROUP BY c1.visited_on, c1.amount;

option 2:

SELECT 
    c1.visited_on, 
    (SELECT SUM(c2.amount) 
     FROM Customer c2 
     WHERE c2.visited_on BETWEEN DATE_ADD(c1.visited_on, INTERVAL -6 DAY) AND c1.visited_on
    ) AS total_amount, 
    ROUND(
        (SELECT SUM(c2.amount) 
         FROM Customer c2 
         WHERE c2.visited_on BETWEEN DATE_ADD(c1.visited_on, INTERVAL -6 DAY) AND c1.visited_on
        ) / 7, 2
    ) AS average_amount
FROM Customer c1
GROUP BY c1.visited_on;

# this additional line is necessary so that we can only return 
# the sum for rows that have 6 previous rows:

# HAVING COUNT(DISTINCT c2.visited_on) = 7 #Only keep rows where the rolling window (the c2 table contains exactly 7 different calendar days.”)

*/

/*
  use offset:
  
	  WITH daily AS (
		SELECT
			visited_on,
			SUM(amount) AS daily_amount
		FROM Customer
		GROUP BY visited_on
	)
	
	SELECT
		visited_on,
		SUM(daily_amount) OVER (
			ORDER BY visited_on
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
		) AS amount,
		ROUND(
			AVG(daily_amount) OVER (
				ORDER BY visited_on
				ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
			), 2
		) AS average_amount
	FROM daily
	ORDER BY visited_on
	LIMIT OFFSET 6; # or you could have used the dense_rank as used above to get the equivalent functionality 


*/

/*
When there are missing days:
	WITH daily AS (
		SELECT
			visited_on,
			SUM(amount) AS daily_amount
		FROM Customer
		GROUP BY visited_on
		),


	calendar AS (
		SELECT MIN(visited_on) AS visited_on
		FROM daily

		UNION ALL

		SELECT DATE_ADD(visited_on, INTERVAL 1 DAY)
		FROM calendar
		WHERE visited_on < (SELECT MAX(visited_on) FROM daily)
	),

	filled AS (
		SELECT
			c.visited_on,
			COALESCE(d.daily_amount, 0) AS daily_amount
		FROM calendar c
		LEFT JOIN daily d
			ON c.visited_on = d.visited_on
	)

    # this part could use the offset or the dense_rank as Above
	SELECT
		visited_on,
		SUM(daily_amount) OVER (
			ORDER BY visited_on
			ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
		) AS amount,
		ROUND(
			AVG(daily_amount) OVER (
				ORDER BY visited_on
				ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
			), 2
		) AS average_amount
	FROM filled
	WHERE visited_on >= (
		SELECT DATE_ADD(MIN(visited_on), INTERVAL 6 DAY)
		FROM filled
	)
	ORDER BY visited_on;

*/
111)

#1341. Movie Rating
https://leetcode.com/problems/movie-rating/description/

/*
Select results
From 
    (
            (
            Select name as results
            From Users u 
                Left Join 
                    (
                        Select user_id, 
                            count(distinct movie_id) as num_rated,
                            avg(rating) as avg_rating
                        From MovieRating 
                        Group By user_id
                    ) x
                On u.user_id = x.user_id
            Order By x.num_rated desc, u.name asc
            Limit 1
            )

            Union All

            (
            Select m.title as results
            From Movies m
                Left Join 
                (
                        Select  movie_id,
                                avg(rating) as avg_rating
                        From    MovieRating 
                        Where   MONTH(created_at) = '2' and 
                                YEAR(created_at) = '2020'
                        Group By movie_id
                ) x
                On m.movie_id = x.movie_id
            Order By x.avg_rating desc, m.title asc
            Limit 1
            )
    ) x
*/

Select results
From 
(
    (Select u.name as results, 
            count(distinct m.movie_id) as max_rated,
            '' as avg_rating
    From users u 
         Inner Join MovieRating m
        On u.user_id = m.user_id
    Group By u.name
    Order By count(distinct movie_id) desc, u.name asc
    Limit 1)

    Union 

    (Select results,
       max_rated,
       avg_rating
    From 
        (
        Select m.title as results, 
            '' as max_rated,
            avg(mr.rating) as avg_rating
        From Movies m
            Inner Join MovieRating mr
            On m.movie_id = mr.movie_id
        Where created_at between '2020-02-01' and '2020-02-29'
        Group By m.title, max_rated
    ) x
    Group By results,
            max_rated,
            avg_rating
    Order By avg_rating desc, 
            results asc
    Limit 1)

) x;

/*

For the Daniel part:

option 1:

With num_ratings as 
(
	Select user_id, 
		   count(user_id) num_rated
	From MovieRating
	Group By user_id
) 


Select name
From 
(
	Select u.name, 
		   COALESCE(nr.num_rated, 0) as num_rated

	From Users u 
		 Left Join num_ratings nr 
		 on u.user_id = nr.user_id

	Order By num_rated desc, u.name asc #upto here you get a full table
	Limit 1 # return the one single row (first one)

)


option 2:


With num_ratings as 
(
	Select user_id, 
		   count(user_id) num_rated
	From MovieRating
	Group By user_id
) 

With num_ratings as 
(
	Select distinct user_id, # using GroupBy so distinct is redundant 	
		   count(movie_id) as num_rated
	From MovieRating
	Group By user_id
) 


Select name
From 
(
	Select u.name, 
		   COALESCE(nr.num_rated, 0) as num_rated

	From Users u 
		 Left Join num_ratings nr 
		 on u.user_id = nr.user_id

	Order By num_rated desc, u.name asc #upto here you get a full table
	Limit 1 # return the one single row (first one)

)

Select distinct user_id, 
       count(movie_id) as num_rated
From MovieRating
Group By user_id

*/

/*
NOTE:

Best practice / interview-safe version

	SELECT user_id,
		   COUNT(*) AS num_rated
	FROM MovieRating
	GROUP BY user_id;

Why this is best

	Shortest
	Clearest intent
	Immune to NULL-column misunderstandings
	Industry-standard
*/

112)

#1907. Count Salary Categories
#https://leetcode.com/problems/count-salary-categories/description/
/*

With CTE as 
   (
        Select 'Low Salary' as sal_group
        Union
        Select 'Average Salary' as sal_group 
        Union
        Select 'High Salary' as sal_group
    )

Select  
        COALESCE(x.sal_group, c.sal_group) as category,
        count(x.account_id) as accounts_count
From 
    (
        Select  account_id,

                                CASE 
                                    When income < 20000 Then 'Low Salary'
                                    When income >= 20000 and income <= 50000 Then 'Average Salary'
                                    Else 'High Salary'
                                END sal_group

        From Accounts
    ) x 
    Right Join CTE c
    On x.sal_group = c.sal_group
Group By category
*/
Select category,
       count(account_id) as accounts_count
From 
    (
        Select 
            account_id,
            income,
            CASE 
                When income < 20000 Then 'Low Salary' 
                When income >= 20000 and income <= 50000 Then 'Average Salary'
                When income > 50000 Then 'High Salary' 
            End as category
        From Accounts        
    ) x
Group By category;
*/

Select 'Low Salary' as category, 
        sum(if(income < 20000,1,0)) as accounts_count 
From Accounts

Union 

Select 'Average Salary' as category, 
        sum(if(income >= 20000 and income <= 50000,1,0)) as accounts_count 
From Accounts

Union

Select 'High Salary' as category, 
        sum(if(income > 50000,1,0)) as accounts_count 
From Accounts

113)

#1204. Last Person to Fit in the Bus
#https://leetcode.com/problems/last-person-to-fit-in-the-bus/
/*

With CTE as 
(
    Select person_name, 
        weight, 
        sum(weight) Over(order by turn asc) as cumulative_weight
    From Queue
    Group By person_name,weight
)

Select person_name 
From CTE
Where cumulative_weight <= 1000
Order By cumulative_weight desc
Limit 1

*/

/*
With bus_load as 
(
    Select person_name,
           weight,
           turn,
           sum(weight) over (order by turn asc) as total_weight,
           row_number() over (order by turn asc) as rn
    From Queue
)

Select person_name 
From bus_load
Where rn = 
    (
        Select max(rn) 
        From bus_load
        Where total_weight <=1000
    )
*/

Select  person_name
From 
    (
        Select x.person_name as person_name,
               max(turn) as turn
        From 
				(
					SELECT 
					t.person_name,
					t.turn,
						(
							SELECT SUM(x.weight)
							FROM Queue x
							WHERE x.turn <= t.turn
						) AS cumulative_sum
					FROM Queue t
					Having cumulative_sum <= 1000
					ORDER BY t.turn asc
				) x
        Group By x.person_name
        Order By turn desc
    ) y
Limit 1;


#Option 1

With CTE as 
(
	Select 
		   person_name,
		   turn, 
		   weight, 
		   sum(weight) over(order by turn asc) as cumulative_weight
	From Queue
)

Select person_name
From CTE
Where cumulative_weight = (
                           Select max(cumulative_weight) 
                           From CTE
						   Where cumulative_weight <= 1000
						  )


114)

Select p.product_name, sum(o.unit) as unit
From Products p 
       Inner Join Orders o
     On p.product_id = o.product_id
Where o.order_date between '2020-02-01' and '2020-02-29'
Group By p.product_name
Having sum(o.unit) >= 100

115)

#1484. Group Sold Products By The Date
https://leetcode.com/problems/group-sold-products-by-the-date/description/

select 
sell_date, count(distinct product) as num_sold, 
group_concat(distinct product) as products 
from activities 
group by sell_date;

116)

#196. Delete Duplicate Emails
https://leetcode.com/problems/delete-duplicate-emails/description/

Delete t1
From Person t1
     Inner Join Person t2
Where t2.id < t1.id and 
      t2.email = t1.email
	  
117)

Select patient_id, 
       patient_name, 
       conditions
From Patients
Where conditions like 'DIAB1%' or 
      conditions like '% DIAB1%'

118)

#1978. Employees Whose Manager Left the Company
https://leetcode.com/problems/employees-whose-manager-left-the-company/description/

#option 1

Select mgr.employee_id as employee_id 
From Employees mgr
Where mgr.manager_id is not null #old manager is still listed as a manager
      and NOT EXISTS 
            (  # manager does not have a row
                Select employee_id
                From Employees emp
                Where emp.employee_id = mgr.manager_id 
            )
      and mgr.salary < 30000
Order By mgr.employee_id asc 

option 1 feedback: Feedback: "The candidate provided a robust solution using NOT EXISTS, which is the safest way to handle anti-joins in SQL. They correctly identified all three conditions (salary, manager existence, and non-null managers) and included the required sorting logic. Clean and professional."

#option 2
Select e.employee_id
From Employees e 
Where e.manager_id is not null and 
      e.salary < 30000 and 
      e.manager_id not in  
      (
            Select distinct employee_id
            From Employees
      )
Order By  e.employee_id asc

option 2 feedback: "The candidate understood the relational logic but missed the sorting requirement. While NOT IN works here because the ID is a primary key, it is generally riskier than NOT EXISTS. The omission of the ORDER BY clause suggests a slight lack of attention to the final prompt requirements."

option 3: using a left Join

SELECT e1.employee_id
FROM Employees e1
LEFT JOIN Employees e2 ON e1.manager_id = e2.employee_id
WHERE e1.salary < 30000 
  AND e1.manager_id IS NOT NULL 
  AND e2.employee_id IS NULL
ORDER BY e1.employee_id;

119)

1164. Product Price at a Given Date
#https://leetcode.com/problems/product-price-at-a-given-date/

#option 1
With CTE as 
(
    Select x.product_id, 
        p.new_price as price
    From 
        (
            Select product_id, 
                   max(change_date) as latest_on_before_2019_08_16
            From   Products 
            Where change_date <= '2019-08-16'
            Group By product_id
        ) x
        Inner Join Products p 
        On  x.product_id = p.product_id and 
            x.latest_on_before_2019_08_16 = p.change_date
    Order By x.product_id asc
) 

Select *
From CTE 

Union 

Select product_id, 
       10 as price
From Products 
Where change_date > '2019-08-16' 
      and product_id not in (Select distinct product_id From CTE)

/*
#option 2

With CTE as 
(
    Select product_id, 
           new_price as price
    From   Products
    Where (product_id, change_date) in
        (
            Select product_id, 
                   max(change_date) as change_date
            From Products
            Where change_date <= '2019-08-16'
            Group By product_id
        )
)

Select product_id, price
From CTE

Union

Select p1.product_id, 
       10 as price
From Products p1
Where p1.change_date not in (
                              Select p2.change_date 
                              From Products p2 
                              Where p1.product_id = p2.product_id and 
                                    p2.change_date <= '2019-08-16'
                            )
        and p1.product_id not in (Select product_id From CTE)
*/

120)

#180. Consecutive Numbers
#https://leetcode.com/problems/consecutive-numbers/description/

Select distinct one.num as ConsecutiveNums
From Logs one
    Inner Join Logs two
         On one.id = two.id + 1
    Inner Join Logs three
         On two.id+1 = three.id + 2
Where one.num = two.num and two.num = three.num;

/*
	SELECT DISTINCT Num AS ConsecutiveNums
	FROM (
		SELECT Num, 
			   LEAD(Num, 1) OVER (ORDER BY Id) AS next1, 
			   LEAD(Num, 2) OVER (ORDER BY Id) AS next2
		FROM Logs
	) AS Temp
	WHERE Num = next1 AND Num = next2;
*/

/*
	Island and Gaps approach
*/

121)

Select  x,
        y,
        z,
        CASE 
            When (x + y > z and x < z and y < z) Then 'Yes'
            When (x + z > y and x < y and z < y) Then 'Yes'
            When (z + y > x and z < x and y < x) Then 'Yes'
            When (z + y > x and z <= x and y <= x) Then 'Yes'
            Else 'No'
        End as triangle
From Triangle;

122)
#https://leetcode.com/problems/primary-department-for-each-employee/description/
#1789. Primary Department for Each Employee
Select employee_id,
       department_id
From Employee
Group By employee_id
Having count(*) = 1

Union 

Select employee_id,
       department_id
From Employee
Where primary_flag = 'Y'

/*
SELECT employee_id, department_id
FROM (
    SELECT *, 
           COUNT(*) OVER(PARTITION BY employee_id) as dept_count
    FROM Employee
) AS sub
WHERE primary_flag = 'Y' 
   OR dept_count = 1;
*/

123)

#1731. The Number of Employees Which Report to Each Employee
https://leetcode.com/problems/the-number-of-employees-which-report-to-each-employee/description/

Select x.manager_id as employee_id, 
       x.manager_name as name, 
       count(distinct e.employee_id) as reports_count,
       round(avg(e.age)) as average_age
From Employees e 
     Inner Join 
        (
            #All managers
            Select employee_id as manager_id,
                name as manager_name
            From Employees
            Where employee_id in (Select distinct reports_to from Employees Where reports_to is not null)
        ) as x
    On e.reports_to = x.manager_id
Group By x.manager_id, 
         x.manager_name

124)

#619. Biggest Single Number
https://leetcode.com/problems/biggest-single-number/description/

Option 1:
    Select max(x.num) as num
    From 
    (
        Select num, 
            count(num) as num_count
        From MyNumbers
        Group By num
    ) x
    Where x.num_count =  1

/*

Option 2 does not work

From research:

Here, the HAVING happens first.
If no group satisfies COUNT(num) = 1, no row is produced 
no groups survived," and the SELECT doesn't even run.
So you get no output row — not even NULL — nothing.

# This code did not work for the above reason:

Select IF(count(num) = 0, null, num) as num #, count(num) 'freq'
From MyNumber
Group By num
Having count(num) = 1
Order By num desc
Limit 1

*/


/*

Option 3 works:

In SQL, when you SELECT FROM (subquery), the outer SELECT will always run — even if the subquery is 
empty — but things like COUNT(), SUM(), MIN(), etc. behave safely with 0 rows.

✅ COUNT() on no rows = 0.
✅ SUM() on no rows = NULL.
✅ AVG() on no rows = NULL.
✅ MIN(), MAX() = NULL on no rows.

Because COUNT(x.num) = 0, your IF can fire.
Select IF (count(x.num) = 0, null, num) as num
    From
    (
        Select num #IF(count(num) = 0, null, num) as num #, count(num) 'freq'
        From MyNumbers
        Group By num
        Having count(num) = 1
        Order By num desc
        Limit 1
    ) x

*/

125)

Select user_id, 
       count(distinct follower_id) as followers_count
From Followers
Group by user_id;

126)

# https://towardsdatascience.com/practical-sql-puzzles-that-will-level-up-your-skill/

CREATE TABLE ticket_moves (
    ticket_id INT NOT NULL,
    create_date DATE NOT NULL,
    move_date DATE NOT NULL,
    from_stage TEXT NOT NULL,
    to_stage TEXT NOT NULL
);

INSERT INTO ticket_moves (ticket_id, create_date, move_date, from_stage, to_stage)
    VALUES
        -- Ticket 1: Created in "New", then moves to Doing, Review, Done.
        (1, '2024-09-01', '2024-09-03', 'New', 'Doing'),
        (1, '2024-09-01', '2024-09-07', 'Doing', 'Review'),
        (1, '2024-09-01', '2024-09-10', 'Review', 'Done'),
        -- Ticket 2: Created in "New", then moves: New → Doing → Review → Doing again → Review.
        (2, '2024-09-05', '2024-09-08', 'New', 'Doing'),
        (2, '2024-09-05', '2024-09-12', 'Doing', 'Review'),
        (2, '2024-09-05', '2024-09-15', 'Review', 'Doing'),
        (2, '2024-09-05', '2024-09-20', 'Doing', 'Review'),
        -- Ticket 3: Created in "New", then moves to Doing. (Edge case: no subsequent move from Doing.)
        (3, '2024-09-10', '2024-09-16', 'New', 'Doing'),
        -- Ticket 4: Created already in "Doing", then moves to Review.
        (4, '2024-09-15', '2024-09-22', 'Doing', 'Review');

/*
	What LAG really means (precisely)
	LAG(expression, offset, default)

	means:

	“Give me expression from offset rows earlier.
	If that row does not exist, return default.”

	So in your case:

	LAG(move_date, 1, create_date)

	translates to:

	“Give me the previous move_date.
	If there is no previous move_date, give me create_date instead.”

*/

Select  round(sum(days_in_stage)/count(distinct ticket_id), 2) as 'avg_time_per_ticket_time_spent_doing'
From 
(
      SELECT 
	       ticket_id,
           from_stage,
           to_stage,
           LAG(move_date, 1, create_date) OVER (PARTITION BY ticket_id ORDER BY move_date asc) AS lag_column_move_date,
           move_date,
           move_date - LAG(move_date, 1, create_date) OVER (PARTITION BY ticket_id ORDER BY move_date asc) days_in_stage        
      FROM ticket_moves
) x
Where from_stage = 'Doing'

127)

3230. Customer Purchasing Behavior Analysis
https://leetcode.com/problems/customer-purchasing-behavior-analysis/description/
#https://github.com/doocs/leetcode/blob/main/solution/3200-3299/3230.Customer%20Purchasing%20Behavior%20Analysis/README_EN.md


# Write your MySQL query statement below
# part 1

With CTE as
(
    Select t.customer_id,
           p.category,
           count(p.category) as times_bought, #num times customer bought a product      
           MAX(t.transaction_date) as max_tran_date
    From Transactions t 
         Inner Join Products p
         On t.product_id = p.product_id
    Group By t.customer_id, t.product_id
),

cte_1 as 
(
    Select customer_id, 
        category, 
        times_bought,
        max_tran_date,
        row_number() over(partition by customer_id order by times_bought desc, max_tran_date desc) rnk
    From CTE
),

cte_2 as
(
    Select customer_id, 
           category as top_category
    From cte_1
    Where rnk = 1
),

cte_3 as
(
    Select t.customer_id,
        round(sum(t.amount), 2) as total_amount,
        count(transaction_id) as transaction_count, 
        count(p.category) as unique_categories,
        round(avg(t.amount), 2) as avg_transaction_amount,
        ((count(transaction_id) * 10) + (sum(t.amount)/10)) as loyalty_score

    From Transactions t 
        Inner Join Products p 
        On t.product_id = p.product_id

    Group By t.customer_id
)

Select c3.*,
       c2.top_category
From cte_3 c3
     Inner Join cte_2 c2
     On c3.customer_id = c2.customer_id
	 	 

128)

3089. Find Bursty Behavior
#https://leetcode.com/problems/find-bursty-behavior/description/
#https://github.com/doocs/leetcode/blob/main/solution/3000-3099/3089.Find%20Bursty%20Behavior/README_EN.md


#Working solution 2:
#===============

        With CTE as 
        (
            Select user_id, 
                count(post_id)/4 as avg_weekly_posts
            From Posts 
            Group By user_id
        ),

        CTE_1 as
        (
            Select x.user_id,
                max(x.num_posts) as max_7day_posts
            From 
                (
                    Select p1.user_id, 
                        p1.post_date begin_date,
                        DATE_ADD(p1.post_date, INTERVAL 6 DAY) end_date,
                        SUM(
                                CASE 
                                    WHEN p2.post_date between p1.post_date and DATE_ADD(p1.post_date, INTERVAL 6 DAY) 
                                    THEN 1
                                    ELSE 0
                                END
                            ) num_posts
                        #count(p2.post_id) num_posts

                    From Posts p1 
                        Inner Join Posts p2 
                        On p1.user_id = p2.user_id

                    Where DATE_FORMAT(p1.post_date, '%Y-%m') = '2024-02' #and 
                        #p2.post_date between p1.post_date and DATE_ADD(p1.post_date, INTERVAL 6 DAY) 

                    GROUP BY p1.user_id, begin_date, end_date

                ) x
            Group By x.user_id 
        )

        Select c.user_id,
            c1.max_7day_posts,
            c.avg_weekly_posts

        From CTE c
            Inner Join CTE_1 c1
            On c.user_id = c1.user_id

        Where c1.max_7day_posts >= 2* c.avg_weekly_posts

        Order By c.user_id asc



#Working solution 1:
#===============

With CTE as 
(
    Select user_id, 
           count(post_id)/4 as avg_weekly_posts
    From Posts 
    Group By user_id
),

CTE_1 as
(
    Select x.user_id,
        max(x.num_posts) as max_7day_posts
    From 
        (
            Select p1.user_id, 
                p1.post_date begin_date,
                DATE_ADD(p1.post_date, INTERVAL 6 DAY) end_date,
                count(p2.post_id) num_posts

            From Posts p1 
                Inner Join Posts p2 
                On p1.user_id = p2.user_id

            Where DATE_FORMAT(p1.post_date, '%Y-%m') = '2024-02' and 
                p2.post_date between p1.post_date and DATE_ADD(p1.post_date, INTERVAL 6 DAY) 

            GROUP BY p1.user_id, begin_date, end_date

        ) x
    Group By x.user_id 
)

Select c.user_id,
       c1.max_7day_posts,
       c.avg_weekly_posts

From CTE c
     Inner Join CTE_1 c1
     On c.user_id = c1.user_id

Where c1.max_7day_posts >= 2* c.avg_weekly_posts

Order By c.user_id asc



#Non-workign solution below
#close but in-correct
#had to use self-join


With CTE as 
(
    Select user_id, 
           count(post_id)/4 as avg_weekly_posts
    From Posts 
    Group By user_id
), 

CTE_1 as
(
    Select user_id, 
        MAX(total_7_day_posts) as max_7day_posts
    From 
        (
            Select p.user_id,
                p.post_date,
                DATE_ADD(p.post_date, INTERVAL 7 DAY) 'upper_date_val',
                count(p.post_id) 'total_7_day_posts' 

            From Posts p

            Where   p.post_date between p.post_date and DATE_ADD(p.post_date, INTERVAL 7 DAY) 
                and DATE_FORMAT(p.post_date, '%Y-%m') = '2024-02' 
                #and p.user_id = 3

            Group By p.user_id, p.post_date, upper_date_val

        ) x
    Group By user_id
    Order By user_id
)

Select c.user_id, 
       c1.max_7day_posts, 
       c.avg_weekly_posts

From CTE c
     Inner Join CTE_1 c1 
     On c.user_id = c1.user_id

Where c1.max_7day_posts >= 2* c.avg_weekly_posts

Order by c.user_id asc

/*
Another option:

SELECT 
    user_id,
    post_date,
    COUNT(*) OVER (
        PARTITION BY user_id 
        ORDER BY post_date 
        RANGE INTERVAL 7 DAY PRECEDING
    ) AS num_posts_in_7_days
FROM Posts
WHERE DATE_FORMAT(post_date, '%Y-%m') = '2024-02';
*/

/*
ChatGPT said:

Yes, using LEAD or LAG functions to define 7-day windows is more challenging because those functions are designed to access only specific rows that come immediately before or after the current row, without considering a dynamic range (like a 7-day window).

SELECT 
    user_id,
    post_date,
    LEAD(post_date, 1) OVER (PARTITION BY user_id ORDER BY post_date) AS next_post_date,
    DATEDIFF(LEAD(post_date, 1) OVER (PARTITION BY user_id ORDER BY post_date), post_date) AS days_to_next_post
FROM Posts
WHERE DATE_FORMAT(post_date, '%Y-%m') = '2024-02'
-- Filter for only posts where the next post is within 7 days
HAVING days_to_next_post <= 7;
*/

129)


2783. Flight Occupancy and Waitlist Analysis
https://leetcode.com/problems/flight-occupancy-and-waitlist-analysis/description/

Select f.flight_id, 
       CASE
          When COALESCE(x.booked_cnt, 0) <= f.capacity Then COALESCE(x.booked_cnt, 0)
          Else f.capacity
       END as booked_cnt,
       CASE
          When COALESCE(x.booked_cnt, 0) <= f.capacity Then 0
          Else abs(COALESCE(x.booked_cnt, 0) - f.capacity)
       END waitlist_cnt

From Flights f 
     Left Join 
     (
        Select flight_id,
               count(passenger_id) booked_cnt
        From Passengers
        Group By flight_id
     ) x
     On f.flight_id = x.flight_id
Order By f.flight_id asc

130)

# Second Highest Salary II
#3338. Second Highest Salary II
https://leetcode.com/problems/second-highest-salary-ii/description/
#https://leetcode.doocs.org/en/lc/3338/#description
employees table:

+--------+--------+-----------+
| emp_id | salary | dept      |
+--------+--------+-----------+
| 1      | 70000  | Sales     |
| 2      | 80000  | Sales     |
| 3      | 80000  | Sales     |
| 4      | 90000  | Sales     |
| 5      | 55000  | IT        |
| 6      | 65000  | IT        |
| 7      | 65000  | IT        |
| 8      | 50000  | Marketing |
| 9      | 55000  | Marketing |
| 10     | 55000  | HR        |
+--------+--------+-----------+

Output:

+--------+-----------+
| emp_id | dept      |
+--------+-----------+
| 2      | Sales     |
| 3      | Sales     |
| 5      | IT        |
| 8      | Marketing |
+--------+-----------+

+--------+--------+-----------+
| emp_id | salary | dept      |
+--------+--------+-----------+
| 1      | 55000  | HR        |
+--------+--------+-----------+

Difference Between: Empty Result vs NULL Result
🔸 1. Empty Result

Definition: The query runs successfully, but returns no rows.

It means: “No records matched the query conditions.”

The table structure (columns) exists in the output, but no data rows are returned.

MAX() (and all aggregate functions) have a key behavior in SQL:

✅ MAX() Always Returns a Value — Even on Empty Sets
Situation	                  MAX() Returns
At least 1 non-NULL value	That max value
Only NULLs	                NULL
No rows at all	            NULL

Example:
#option 4
NOTE: max(salary) in WHERE is invalid. Aggregate functions cannot be used directly in WHERE.

Select s.emp_id,
       s.dept
From employees s
     Inner Join 
     (
	    Select e.dept,
           max(e.salary) second_max
        From employees e
        Inner Join 
        (
                Select dept,
                    max(salary) as max_salary
                From employees
                Group By dept
        ) x
        On e.dept = x.dept
        Where e.salary < x.max_salary #if there is no second max, no corresponding row is returned
        Group By e.dept    
	 ) c
     On s.dept = c.dept and
        s.salary = c.second_max
Order By s.emp_id asc   

# Option 3


# Get the second max for each department
/*
With CTE as
(
    Select e.dept,
           max(e.salary) second_max
    From employees e
        Inner Join 
        (
                Select dept,
                    max(salary) as max_salary
                From employees
                Group By dept
        ) x
        On e.dept = x.dept
    Where e.salary < x.max_salary #if there is no second max, no corresponding row is returned
    Group By e.dept    
)

Select s.emp_id,
       s.dept
From employees s
     Inner Join CTE c
     On s.dept = c.dept and
        s.salary = c.second_max
Order By s.emp_id asc        
*/

/*

# Option 2

Select e.emp_id,
       e.dept

From employees e
     Inner Join 
     (
            Select emp_id,
                   salary,
                   dept,
                   dense_rank() over(partition by dept order by salary desc) rnk
            From employees
    ) c
    On e.emp_id = c.emp_id and 
       e.dept = c.dept

Where c.rnk = 2

Order By emp_id asc

*/

/*
Option 1:
With CTE as 
(
    Select emp_id,
           salary,
           dept,
           dense_rank() over(partition by dept order by salary desc) rnk
    From employees
)

Select emp_id, 
       dept
From CTE
Where rnk = 2
Order By emp_id asc
*/

131)

# 3475. DNA Pattern Recognition
https://leetcode.com/problems/dna-pattern-recognition/description/

Select sample_id, 

       dna_sequence, 

       species,

       CASE

            When dna_sequence LIKE 'ATG%' Then 1
            Else 0

       END has_start,

       CASE
            
            When dna_sequence LIKE '%TAA' or
                 dna_sequence LIKE '%TAG' or 
                 dna_sequence LIKE '%TGA' 
                 Then 1
            Else 0

       END has_stop,

       CASE

            When dna_sequence LIKE '%ATAT%' Then 1
            Else 0
           
       END has_atat,

       CASE

            When dna_sequence LIKE '%GGG%' Then 1
            Else 0

       END has_ggg

From 

       Samples

Order By sample_id asc

132)

# 3497. Analyze Subscription Conversion
https://leetcode.com/problems/analyze-subscription-conversion/description/

# Option 2

Select x.user_id,
       round(x.trial_avg_duration, 2) as trial_avg_duration,
       round(y.paid_avg_duration, 2) as  paid_avg_duration  

From 
    (
        #distinct below because Windows function results per row results 
        #and to avoid using distinct later as redundant rows multiply
        Select distinct user_id, trial_avg_duration
        From 
        (
            Select 
                user_id,
                avg(activity_duration) Over(Partition By user_id, activity_type) as trial_avg_duration
            From UserActivity
            Where activity_type ='free_trial' 
            #dont use group by with windows CTE - windows fn is run after HAVING in order of operations
        ) a
    ) x 
    Inner Join 
    (
        #distinct below because Windows function results per row results 
        #and to avoid using distinct later as redundant rows multiply
        Select distinct user_id, paid_avg_duration
        From 
        (
            Select 
                user_id,
                avg(activity_duration) Over(Partition By user_id, activity_type) as paid_avg_duration
            From UserActivity
            Where activity_type ='paid'
            #dont use group by with windows CTE - windows fn is run after HAVING in order of operations
        ) b
    ) y
On x.user_id = y.user_id

Order By x.user_id asc


/*
Option 1:
Select x.user_id,
       x.trial_avg_duration,
       y.paid_avg_duration
From 
    (
        Select user_id,
            round(avg(activity_duration), 2) trial_avg_duration 
        From UserActivity
        Where activity_type = 'free_trial'
        Group By user_id 
    ) x
    Inner Join 
    (
        Select user_id,
            round(avg(activity_duration), 2) paid_avg_duration 
        From UserActivity
        Where activity_type = 'paid'
        Group By user_id 
    ) y 
On x.user_id = y.user_id
Order By x.user_id asc
*/

/*
Option 2:

SELECT 
    user_id,
    ROUND(AVG(CASE WHEN activity_type = 'free_trial' THEN activity_duration END), 2) AS trial_avg_duration,
    ROUND(AVG(CASE WHEN activity_type = 'paid' THEN activity_duration END), 2) AS paid_avg_duration
FROM UserActivity
GROUP BY user_id
HAVING 
    SUM(activity_type = 'free_trial') > 0
    AND SUM(activity_type = 'paid') > 0
ORDER BY user_id;
*/

133)

3220. Odd and Even Transactions
https://leetcode.com/problems/odd-and-even-transactions/description/

# Option 2

With CTE_odd as
(
        #use distinct as the row based windows CTE will duplicate the sum for each transaction amount 
        #dont use Group By - will get strange results
        Select distinct transaction_date,
            sum(amount) over(Partition By transaction_date) as odd_sum
        From transactions 
        Where amount mod 2 <> 0
        #Group By transaction_date -- Dont use
),

CTE_even as
(
        #use distinct as the row based windows CTE will duplicate the sum for each transaction amount 
        #dont use Group By - will get strange results
        Select distinct transaction_date,
            sum(amount) over(Partition By transaction_date) as even_sum
        From transactions 
        Where amount mod 2 = 0
        #Group By transaction_date -- Dont use
)

Select transaction_date,
       odd_sum,
       even_sum
From 
        (
            Select x.transaction_date as transaction_date,
                x.odd_sum as odd_sum,
                COALESCE(y.even_sum,0) as even_sum       
            From 
                CTE_odd x
                Left Join CTE_even y
                on x.transaction_date = y.transaction_date

            Union 

            Select y.transaction_date as transaction_date,
                COALESCE(x.odd_sum, 0) as odd_sum,
                y.even_sum as even_sum       
            From 
                CTE_odd x
                Right Join CTE_even y
                on x.transaction_date = y.transaction_date
        ) x
Order By transaction_date asc


/*

# Option 1:

 Select 
        transaction_date,
        SUM(
            CASE 
            WHEN amount mod 2 <> 0 
            Then amount 
            Else 0 
            END) AS odd_sum,
        SUM(
            CASE 
            WHEN amount mod 2 = 0  
            Then amount 
            Else 0 
            END
            ) AS even_sum
From transactions
Group By transaction_date
Order by transaction_date asc
*/

/*

#needed to capture missing dates
With recursive_CTE as 
(
    Select min(transaction_date) as transaction_date
    From Transactions

    Union All

    Select DATE_ADD(transaction_date, INTERVAL 1 Day) as transaction_date
    From recursive_CTE
    Where transaction_date < (Select max(transaction_date) From Transactions)

),

CTE as 
(
    Select  transaction_date, 
            SUM(CASE WHEN amount mod 2 = 0 THEN amount Else 0 END) as even_sum, 
            SUM(CASE WHEN amount mod 2 <> 0 THEN amount Else 0 END) as odd_sum

    From transactions 

    Group By transaction_date
)

Select c1.transaction_date, 
       COALESCE(c2.odd_sum, 0) as odd_sum,
       COALESCE(c2.even_sum, 0) as even_sum

From recursive_cte c1
     left join CTE c2
     On c1.transaction_date = c2.transaction_date 

Order By c1.transaction_date asc

*/

134)

1549. The Most Recent Orders for Each Product
https://leetcode.com/problems/the-most-recent-orders-for-each-product/description/

With CTE as 
(
    Select o.product_id, 
        p.product_name, 
        dense_rank() over(Partition By o.product_id Order by o.order_date desc) rnk_by_order_date,
        o.order_date,
        o.order_id
    From Orders o
        Inner Join Products p 
        On o.product_id = p.product_id
    #Order By p.product_name asc, p.product_name asc
)

Select product_name,
       product_id,
       order_id,
       order_date
From CTE
Where rnk_by_order_date = 1
Order By product_name asc, product_id asc, order_id asc

/*

In SQL, when you use an aggregate function like MAX(), you should group by the columns that define the "category" you want the maximum for.
If you group by order_id, the result will return every row from the Orders table (joined with Products), which is why your result table 
doesn't actually filter down to just the "most recent" ones.

WITH CTE as (
    SELECT 
        p.product_name,
        o.product_id,
        MAX(o.order_date) as max_date -- Renamed for clarity
    FROM Orders o 
    INNER JOIN Products p ON o.product_id = p.product_id 
    GROUP BY p.product_name, o.product_id
)

SELECT 
    c.product_name, 
    c.product_id, 
    o.order_id,    -- We get this from the 'o' table
    c.max_date as order_date
FROM CTE c 
INNER JOIN Orders o 
    ON c.product_id = o.product_id 
    AND c.max_date = o.order_date 
ORDER BY c.product_name asc, c.product_id asc, o.order_id asc;
*/


135)

# https://leetcode.com/problems/symmetric-coordinates/
#2978. Symmetric Coordinates

#Option 4:

With CTE as 
    (
        Select 
            X, 
            Y, 
            row_number() Over() as r_num
        From Coordinates
    )

Select distinct c1.x, c1.y
From CTE c1
     Inner join CTE c2
     On c1.X = c2.Y and 
        c2.X = c1.Y and 
        (c1.x <= c1.y and 
         c1.r_num <> c2.r_num)
#Where   c1.r_num <> c2.r_num #and 
        #c1.x <= c1.y
Order By c1.x, c1.y

/*
#Option 3:

With CTE as 
    (
        Select 
            X, 
            Y, 
            row_number() Over() as r_num
        From Coordinates
    )

Select distinct c1.x, c1.y
From CTE c1
     Inner join CTE c2
     On c1.X = c2.Y and 
        c2.X = c1.Y
Where   c1.r_num <> c2.r_num and 
        c1.x <= c1.y
Order By c1.x, c1.y
*/

/*

# Option 2:

With CTE as 
    (
        Select X, 
            Y, 
            row_number() Over() as r_num
        From Coordinates
    )

Select distinct c1.x, c1.y
From CTE c1
        cross join CTE c2
Where c1.X = c2.Y and 
        c2.X = c1.Y and 
        c1.r_num <> c2.r_num and 
        c1.x <= c1.y
Order By c1.x, c1.y

*/


/*

#Option 1:

    With CTE as 
    (
        Select X, 
            Y, 
            row_number() Over() as r_num
        From Coordinates
    )

    Select distinct c1.x, c1.y
    From CTE c1
        cross join CTE c2
    Where c1.X = c2.Y and 
        c2.X = c1.Y and 
        c1.r_num <> c2.r_num 
        #and 
        #c1.X <> c2.X and
        #c1.Y <> c2.Y
    Having c1.x <= c1.y
    Order By c1.x, c1.y
*/

136:

#2922. Market Analysis III
https://leetcode.com/problems/market-analysis-iii/

#get the itemid of the favorite brand to exclude later on
With CTE_fav_brand as 
(
    Select u.seller_id,
           u.join_date,
           u.favorite_brand,
           i.item_id as fav_brand_item_id

    From Users u 
         Inner Join Items i 
         On u.favorite_brand = i.item_brand
),

cte1 as
(
    Select o1.seller_id,
        count(distinct o1.item_id) num_items
    From Orders o1 
    Where o1.item_id not in 
        ( # exclude the favotite brand using the item id from previous step
            Select cfb.fav_brand_item_id
            From CTE_fav_brand cfb
            Where o1.seller_id = cfb.seller_id
        )
    Group By o1.seller_id
    #Order By num_items desc
)

Select c2.seller_id, 
       c2.num_items
From cte1 c2
Where c2.num_items = 
      (
        Select max(c1.num_items)
        From cte1 c1
        #Where c1.seller_id = c2.seller_id
      )
Order By c2.seller_id asc

/*

With CTE as 
(
	Select o.*,
	       u.favorite_brand,
		   i.item_brand       
	
	From Orders o 
	     Inner Join Users u 
		 On o.seller_id = u.seller_id
		 
		 Inner Join Items i 
		 On O.item_id = i.item_id # to get the item_name
),

CTE1 as 
(
	Select seller_id, 
		   count(distinct item_id) as num_items 
	From CTE
	Where favorite_brand <> item_brand
	Group By seller_id
)

Select seller_id,
       num_items
From CTE1 
Where num_items = (Select max(num_items) From CTE1)
*/



137)

2688. Find Active Users
# https://leetcode.com/problems/find-active-users/description/

with cte as 
(
    Select row_number() over(order by user_id asc) row_num,
        user_id, 
        item, 
        created_at, 
        amount
    From Users
)

Select distinct c1.user_id #the two purchases are made on the same day, the user_id is included twice 

From cte c1 
     Inner Join cte c2
     On c1.user_id = c2.user_id
        and c1.row_num <> c2.row_num

Where DATEDIFF(c1.created_at, c2.created_at) <= 7 #in DATEDIFF, first date is bigger than second date
      and c1.created_at >= c2.created_at 


138)

1843. Suspicious Bank Accounts
#https://leetcode.com/problems/suspicious-bank-accounts/description/
	  
With CTE as 
(
    Select account_id,
        DATE_FORMAT(day, '%Y-%m') as yr_mnth,
        sum(amount) as total_income_by_month
    From Transactions 
    Where type = 'creditor'
    Group By account_id, yr_mnth
    Order By account_id asc
),

CTE1 as
(
    Select 
        c.account_id,
        c.yr_mnth,
        c.total_income_by_month,
        a.max_income,
        CASE
            When c.total_income_by_month > a.max_income Then 'Y'
            Else 'N'
        END as income_exceeds_max

    From CTE c 
        Inner Join Accounts a
        On c.account_id = a.account_id

    Order By c.account_id asc, 
            c.yr_mnth asc, 
            c.total_income_by_month asc
)

Select distinct c1.account_id

From CTE1 c1
     Inner Join CTE1 c2
     On c1.account_id = c2.account_id
        
Where c1.income_exceeds_max = 'Y' 
      and c2.income_exceeds_max = 'Y' 
      and TIMESTAMPDIFF(
                                MONTH, 
                                STR_TO_DATE(CONCAT(c2.yr_mnth, '-01'), '%Y-%m-%d'),
                                STR_TO_DATE(CONCAT(c1.yr_mnth, '-01'), '%Y-%m-%d')
                                ) = 1
/*

		WITH monthly_income AS (
			SELECT
				t.account_id,
				DATE_FORMAT(t.day, '%Y-%m-01') AS month_start,
				SUM(t.amount) AS total_income
			FROM Transactions t
			WHERE t.type = 'Creditor'
			GROUP BY t.account_id, DATE_FORMAT(t.day, '%Y-%m-01')
		),
		
		exceeded AS (
			SELECT
				m.*,
				a.max_income
			FROM monthly_income m
			JOIN Accounts a
				ON m.account_id = a.account_id
			WHERE m.total_income > a.max_income
		),
		
		with_next AS (
			SELECT
				account_id,
				month_start,
				LEAD(month_start) OVER (
					PARTITION BY account_id
					ORDER BY month_start
				) AS next_month
			FROM exceeded
		)
		
		SELECT DISTINCT account_id
		FROM with_next
		WHERE TIMESTAMPDIFF(MONTH, month_start, next_month) = 1
		ORDER BY account_id;

*/								

139)

2228. Users With Two Purchases Within Seven Days
# https://leetcode.com/problems/users-with-two-purchases-within-seven-days/

Select distinct p1.user_id

From Purchases p1
     Inner Join Purchases p2
     On p1.user_id = p2.user_id

Where p1.purchase_id <> p2.purchase_id and 
      DATEDIFF(p1.purchase_date, p2.purchase_date) between 0 and 7 and
      #DATEDIFF(p1.purchase_date, p2.purchase_date) >= 0 and
      #DATEDIFF(p1.purchase_date, p2.purchase_date) <= 7 and 
      p1.purchase_date >= p2.purchase_date

Order By p1.user_id asc


/*
	Select distinct 
	
	From Purchases p1 
	     Inner Join Purchases p2 
		 On p1.user_id = p2.user_id 
		 
	Where p1.purchase_id <> p2.purchase_id and 
	      DATEDIFF(p1.purchase_date, p2.purchase_date) between 0 and 7 and 
		  p1.purchase_date >= p2.purchase_date
	      

    OR 
	 
	WITH cte AS (
    SELECT  user_id,
            purchase_date,
            LAG(purchase_date) OVER (
                PARTITION BY user_id 
                ORDER BY purchase_date
            ) AS prev_purchase_date
    FROM Purchases
	)

	SELECT DISTINCT user_id
	FROM cte
	WHERE DATEDIFF(purchase_date, prev_purchase_date) BETWEEN 0 AND 7
	ORDER BY user_id ASC;
	
	OR 
	
	SELECT DISTINCT user_id
    FROM (
    SELECT  user_id,
            purchase_date,
            LAG(purchase_date) OVER (
                PARTITION BY user_id 
                ORDER BY purchase_date
            ) AS prev_purchase_date,
            DATEDIFF(
                purchase_date,
                LAG(purchase_date) OVER (
                    PARTITION BY user_id 
                    ORDER BY purchase_date
                )
            ) AS diff_days
    FROM Purchases
	) t
	WHERE diff_days BETWEEN 0 AND 7
	ORDER BY user_id ASC;
	
*/

140)

3421. Find Students Who Improved
# https://leetcode.com/problems/find-students-who-improved/


With CTE as
(
    Select 
        student_id,
        subject,
        score,
        exam_date,
        dense_rank() over(partition by student_id, subject order by exam_date asc) test_date_sequence_l_to_h
    From Scores
),

CTE1 as
(
    Select  student_id,
            subject,
            min(test_date_sequence_l_to_h) as first_test,
            max(test_date_sequence_l_to_h) as last_test
    From CTE
    Group By student_id, subject
    #Having max(test_date_sequence_l_to_h) > min(test_date_sequence_l_to_h) 
)

Select c.student_id, 
       c.subject,
       c.score as first_score,
       c2.score as latest_score

From CTE c
    Inner Join CTE1 c1 
    On  c.student_id = c1.student_id and 
        c.subject = c1.subject and 
        c.test_date_sequence_l_to_h = c1.first_test

    Left Join CTE c2 
    On  c.student_id = c2.student_id and 
        c.subject = c2.subject and 
        c2.test_date_sequence_l_to_h = c1.last_test

Where c.score < c2.score


/*
Option 1:

		With student_sub_ranking as 
		(

			Select 

				student_id,
				subject, 
				score,
				exam_date,
				dense_rank() over (Partition By student_id, subject Order By exam_date asc) rnk 
				#why use dense_rank if ties can not occur? use row_number() 

			From Scores

		),

		max_min_groups as 
		(
			Select 
				   student_id,
				   subject, 
				   min(rnk) as first_score,
				   max(rnk) as latest_score
			
			From student_sub_ranking

			Group By student_id, subject

			Having max(rnk) > min(rnk) #more than one test date

		)

		Select a.student_id, 
			   a.subject, 
			   b.score as first_score,
			   c.score as latest_score

		From max_min_groups a
			 Inner Join student_sub_ranking b 
			 On a.student_id = b.student_id and 
				a.subject = b.subject and 
				a.first_score = b.rnk 
				
			 Inner Join student_sub_ranking c 
				
			 On a.student_id = c.student_id and 
				a.subject = c.subject and 
				a.latest_score =  c.rnk 

		# Where c.exam_date > b.exam_date - not needed as the rnk covers this
		Order By a.student_id asc, 
				 a.subject asc
				 
Option 2:

A better solution - from chatGPT - because it is not over engineered using ranking logic:

WITH bounds AS (
SELECT
    student_id,
    subject,
    MIN(exam_date) first_date,
    MAX(exam_date) last_date
FROM Scores
GROUP BY student_id, subject
HAVING MIN(exam_date) <> MAX(exam_date)
)

SELECT
    b.student_id,
    b.subject,
    s1.score AS first_score,
    s2.score AS latest_score
FROM bounds b
JOIN Scores s1
  ON s1.student_id=b.student_id
 AND s1.subject=b.subject
 AND s1.exam_date=b.first_date
JOIN Scores s2
  ON s2.student_id=b.student_id
 AND s2.subject=b.subject
 AND s2.exam_date=b.last_date
WHERE s2.score > s1.score
ORDER BY b.student_id, b.subject;

*/