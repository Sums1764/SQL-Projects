select * from Credit_Card_transactions
where amount>50000 and gender='F';

select * from Credit_Card_transactions
where amount>100000 and card_type='Silver';

select distinct exp_type from Credit_Card_transactions;

select * from Credit_Card_transactions
where exp_type='entertainment' and amount>50000;


select distinct city from Credit_Card_transactions where city  like 'D%';


-- Problem :1 -- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with A as (select city, sum(amount) as Amount_Spent 
from Credit_Card_Transactions
group by city)
, B as(
select *,
sum(amount_spent) over() as total_amount_spent
from A)

select top 5 City,amount_spent, round((amount_spent/total_amount_spent)*100,2) as percentage_con from B
order by Amount_Spent desc;


-- Question 2:
With CTE1 as (
select  DATEPART(year,transaction_date) as Year_TD, DATEPART(Month, transaction_date) as Month_TD , 
		Sum(amount) as Month_Amt
from Credit_Card_transactions
group by DATEPART(year,transaction_date), DATEPART(Month,transaction_date))
,CTE2 as(
Select *,
RANK() Over(order by Month_Amt desc) as Rank_TD
from CTE1)
Select Card_type, 
	Sum(amount) as Amount 
from Credit_Card_transactions
where DATEPART(year,transaction_date) =(Select Year_TD from CTE2 where Rank_TD=1) and
	DATEPART(Month, transaction_date) = (Select Month_TD from CTE2 where Rank_TD=1)
group by card_type

-- Problem (2)- original question:write a query to print highest spend month and amount spent in that month for each card type
with CTE as (select card_type, sum(amount) as amount_spent, 
datepart(month,transaction_date) as month,
datepart(year, transaction_date) as year
from credit_card_transactions
group by card_type, datepart(month,transaction_Date), datepart(year,transaction_date))
, B as(
select *,
rank() over(partition by card_type order by amount_spent desc) as rnk
from CTE)

select * from B
where rnk=1;

--Problem No.3:write a query to find city which had lowest percentage spend for gold card type
with CTE1 as (select *,
sum(amount) over(partition by card_type order by transaction_Date, transaction_id) as Cumulativeamount
from credit_card_transactions)

,CTE2 as(select *,
rank() over(partition by card_type order by cumulativeamount) as rnk
from CTE1
where cumulativeamount>=1000000)

select * from CTE2 where rnk=1

--Problem no.4
-- personal choice_1
with CTE1 as(select city, sum(amount) as amount_spent
from credit_card_transactions
where card_type='gold'
group by city)

,CTE2 as (select min(amount_spent) as min_spent from CTE1)
select city from CTE1
inner join CTE2 on amount_spent=min_spent

--write a query to find city which had lowest percentage spend for gold card type
with CTE1 as (select city, sum(amount) as total_spent, 
sum(case when card_type='Gold' then amount else 0 end) as gold_spent
from credit_Card_transactions
group by city)
select top 1 city, (sum(gold_spent)/sum(total_spent))*100 as gold_per
from cte1
group by city 
having (sum(gold_spent)/sum(total_spent))*100>0
order by gold_per asc;

-- Problem No.5
--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as (select city, exp_type, sum(amount) as exptype_amt
from credit_Card_transactions
group by city,exp_type)

, CTE2 as(select *,
max(exptype_amt) over(partition by city) as max_amt,
min(exptype_amt) over(partition by city) as min_amt
from cte1)

select city, max(case when exptype_amt=max_amt then exp_type end) as highest, min(case when exptype_amt=min_amt then exp_type end) as lowest
from cte2
group by city;
--  to group the cities we need an aggregation function on a string we can use only min or max aggreegation functions


with cte1 as (select city, exp_type, sum(amount) as exptype_amt
from credit_Card_transactions
group by city,exp_type)

, cte2 as (select *,
rank() over(partition by city order by exptype_amt desc) as rn_desc,
rank() over(partition by city order by exptype_amt asc) as rn_asc
from cte1)

select city, max(case when rn_asc=1 then exp_type end ) as lowest_expense,
min(case when rn_desc=1 then exp_type end) as highest_expense
from cte2
group by city

-- problem --6
-- write a query to find percentage contribution of spends by females for each expense type

select exp_type,(Fem_exp_amount/total_amount) as Fem_Con from
(select exp_type,sum(amount) as total_amount, sum(case when gender='F' then amount end) as Fem_exp_amount from
credit_card_transactions
group by exp_type) A
order by Fem_Con desc

-- Problem --7
--which card and expense type combination saw highest month over month growth in Jan-2014

with A as(
select card_type, exp_type, sum(amount) as totalamount, datepart(month,transaction_date) as mth , datepart(year,transaction_date) as year
from credit_Card_transactions
group by card_type, exp_type,  datepart(month,transaction_date), datepart(year,transaction_date))
, B as(
select *,
lag(totalamount,1) over(partition by card_type,exp_type order by year,mth) as lag_1
from A)


select top 1 *, totalamount-lag_1 as mom_growth
from B
where lag_1 is not null and year=2014 and mth=1
order by mom_growth desc;


-- Problem-8-during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city, sum(amount)/count(1) as transaction_ratio
from Credit_Card_transactions
where datename(DW,transaction_Date) in('Saturday','Sunday')
group by city
order by transaction_ratio desc
-- we can do problem 8 using datepart it gives faster because it is easy to make a filter on it


-- Problem-9-which city took least number of days to reach its 500th transaction after the first transaction in that city
With CTE as (
select *,
ROW_NUMBER() over(partition by city order by transaction_date, transaction_id) as rn
from Credit_Card_transactions)
select city, datediff(day,min(transaction_date), max(transaction_date)) as diff_days
from CTE
where rn=1 or rn=500
group by city
having count(1)=2
order by diff_days