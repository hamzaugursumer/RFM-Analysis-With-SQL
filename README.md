# **RFM Analysis With PostgreSQL** :hourglass: :bar_chart: :moneybag:

![png-rfm](https://rfmcube.com/wp-content/uploads/2021/07/1_HiwX6vul8c4PBEueq3yBMw-750x350.png)

* :pushpin: Dataset ; https://www.kaggle.com/nathaniel/uci-online-retail-ii-data-set
* You can review the RFM analysis with a detailed explanation in my Python project, which involves different years of the same dataset.
* [RFM Analysis With Python](https://github.com/hamzaugursumer/RFMAnalysisWithPython)
* (There are two pages in the dataset covering different years. I utilized the second sheet that encompasses the years 2010 - 2011.)

## 📌 **Since the data set is old, the maximum invoice number in the data is taken as today.**
````sql
-- Last invoicing date in the data set	
select 
	max(invoice_date) as last_invoice_today
from e_commerce_data
where customer_id != 'NULL'
````
|   | last_invoice_today     |
|---|------------------------|
| 1 |   2011-12-09 12:50:00  |
        
## 📌 **The query containing the RFM values and scores of each customer is as follows.**
````sql
with recency as
(
with last_invoice_date as 
(
select 
	   distinct customer_id,
	   max(invoice_date) as last_invoice_date
from e_commerce_data as e
where customer_id != 'NULL'	
and invoice_no not like 'C%'
and quantity > 0
group by 1
)
select 
		customer_id,
		last_invoice_date,
	    extract (day from ('2011-12-09 12:50:00'-last_invoice_date)) as recency 
from last_invoice_date   
order by 3 desc
),
frequency as 
(
select 
		customer_id,
		count(invoice_no) as frequency 
from e_commerce_data
where customer_id != 'NULL'	
and invoice_no not like 'C%'
and quantity > 0
group by 1
order by 2 desc
),
monetary as 
(
select 
		customer_id,
	    sum(quantity*unit_price) as monetary
from e_commerce_data
where customer_id != 'NULL'	
and invoice_no not like 'C%'
and quantity > 0
group by 1
order by 2
)
select 
		r.customer_id,
	    r.recency,
	    f.frequency,
	    m.monetary,
	    ntile(5) over (order by recency desc) as recency_point,
	    ntile(5) over (order by frequency asc) as frequency_point,
	    ntile(5) over (order by monetary asc) as monetary_point
from recency as r
left join frequency as f 
ON f.customer_id = r.customer_id
left join monetary as m 
ON m.customer_id = f.customer_id
````

|       | customer_id | recency | frequency | monetary | recency_point | frequency_point | monetary_point |
|-------|-------------|---------|-----------|----------|---------------|-----------------|----------------|
|     1 |       13747 |     373 |         1 |    79.60 |             1 |               1 |              1 |
|     2 |       18074 |     373 |        13 |   489.60 |             1 |               1 |              2 |
|     3 |       12791 |     373 |         2 |   192.60 |             1 |               1 |              1 |
|     4 |       17908 |     373 |        58 |   243.28 |             1 |               3 |              1 |
|     5 |       16583 |     373 |        14 |   233.45 |             1 |               2 |              1 |
|     6 |       14729 |     373 |        71 |   313.49 |             1 |               4 |              2 |
|     7 |       17968 |     373 |        85 |   277.35 |             1 |               4 |              2 |
|     8 |       17925 |     372 |         1 |   244.08 |             1 |               1 |              1 |
|     9 |       15923 |     372 |        21 |   127.08 |             1 |               2 |              1 |
|    10 |       17732 |     372 |        18 |   303.97 |             1 |               2 |              2 |

* **Only the first 10 lines of 4339 lines are displayed.**

## 📌 **The query containing the RFM values, scores and segmentation groups of each customer is as follows.**
````sql
with recency as (
    with last_invoice_date as (
        select 
            distinct customer_id,
            max(invoice_date) as last_invoice_date
        from e_commerce_data as e
        where customer_id != 'NULL'	
            and invoice_no not like 'C%'
            and quantity > 0
        group by 1
    )
    select 
        customer_id,
        last_invoice_date,
        extract(day from (timestamp '2011-12-09 12:50:00' - last_invoice_date)) as recency
    from last_invoice_date
    order by 3 desc
),
frequency as (
    select 
        customer_id,
        count(invoice_no) as frequency
    from e_commerce_data
    where customer_id != 'NULL'	
        and invoice_no not like 'C%'
        and quantity > 0
    group by 1
),
monetary as (
    select 
        customer_id,
        sum(quantity * unit_price) as monetary
    from e_commerce_data
   where customer_id != 'NULL'	
        and invoice_no not like 'C%'
        and quantity > 0
    group by 1
),
segment as (
    select 
        r.customer_id,
        r.recency,
        f.frequency,
        m.monetary,
        ntile(5) over (order by recency desc) as recency_point,
        ntile(5) over (order by frequency asc) as frequency_point,
        ntile(5) over (order by monetary asc) as monetary_point
    from recency as r
    left join frequency as f on f.customer_id = r.customer_id
    left join monetary as m on m.customer_id = f.customer_id
)
select 
    customer_id,
    recency,
    frequency,
    monetary,
    recency_point,
    frequency_point,
    monetary_point,
    case 
        when recency_point <= 2 and frequency_point <= 2 then 'Hibernating'
        when recency_point <= 2 and 3 <= frequency_point and frequency_point <= 4 then 'At risk'
        when recency_point <= 2 and frequency_point = 5 then 'Cant lose'
        when recency_point = 3 and frequency_point <= 2 then 'About to sleep'
        when recency_point = 3 and frequency_point = 3 then 'Need attention'
        when 3 <= recency_point and recency_point <= 4 and 4 <= frequency_point and frequency_point <= 5 then 'Loyal customers'
        when recency_point = 4 and frequency_point = 1 then 'Promising'
        when recency_point = 5 and frequency_point = 1 then 'New customers'
        when 4 <= recency_point and recency_point <= 5 and 2 <= frequency_point and frequency_point <= 3 then 'Potential loyalists'
        when recency_point = 5 and 4 <= frequency_point and frequency_point <= 5 then 'Champions'
    end as customer_segment
from segment
````
|       | customer_id | recency | frequency | monetary | recency_point | frequency_point | monetary_point | customer_segment |
|-------|-------------|---------|-----------|----------|---------------|-----------------|----------------|-----------------|
|     1 |       13747 |     373 |         1 |    79.60 |             1 |               1 |              1 |     Hibernating |
|     2 |       18074 |     373 |        13 |   489.60 |             1 |               1 |              2 |     Hibernating |
|     3 |       12791 |     373 |         2 |   192.60 |             1 |               1 |              1 |     Hibernating |
|     4 |       17908 |     373 |        58 |   243.28 |             1 |               3 |              1 |         At risk |
|     5 |       16583 |     373 |        14 |   233.45 |             1 |               2 |              1 |     Hibernating |
|     6 |       14729 |     373 |        71 |   313.49 |             1 |               4 |              2 |         At risk |
|     7 |       17968 |     373 |        85 |   277.35 |             1 |               4 |              2 |         At risk |
|     8 |       17925 |     372 |         1 |   244.08 |             1 |               1 |              1 |     Hibernating |
|     9 |       15923 |     372 |        21 |   127.08 |             1 |               2 |              1 |     Hibernating |
|    10 |       17732 |     372 |        18 |   303.97 |             1 |               2 |              2 |     Hibernating |
* **Only the first 10 lines of 4339 lines are displayed.**

## 📌 **Treemap Graph of RFM analysis**

![image](https://github.com/hamzaugursumer/RFM-Analysis-With-SQL/assets/127680099/c40b046d-cb95-4fa2-b043-9c49be205df7)


## 📌 **Insights and Suggestions**

* **Hibernating (Hibernation):** Customers in this segment are generally inactive and make rare purchases. Their last purchases happened a while ago, and special strategies may be required to re-engage them.

* **At Risk:** Customers in the At Risk segment were active in the past but have shown a decline in recent times. Efforts may be needed to retain their loyalty and re-engage them.

* **Loyal Customers:** This segment includes customers who shop frequently and regularly, and they are of high value to the business. It's important to reward and incentivize them.

* **Promising:** Customers in the Promising segment may have made infrequent purchases, but they have significant potential. Developing strategies to encourage them to shop more frequently is crucial.

* **New Customers:** This segment typically consists of customers who have made their first purchases. Attracting them and converting them into loyal customers requires specific strategies.

* **Potential Loyalists:** The Potential Loyalists segment includes customers who have made a few purchases and have the potential to become loyal customers. Developing strategies to earn their loyalty is important.

* **Champions**: Customers in the Champions segment are both frequent and high-value shoppers, and they are loyal to the business. Using motivating strategies to keep them satisfied and conducting more business with them is crucial.


**Hibernating (Hibernation) Customer Segment:**

* The Hibernating customer segment signifies significant potential for businesses, but it often requires special attention to increase conversion rates. Customers in this segment tend to be inactive and make infrequent purchases. Their last purchases occurred some time ago, and efforts to re-engage them can contribute to the growth of businesses.
* Various marketing strategies can be employed to reactivate this customer segment and regain their loyalty. Here are some suggestions:
* Special Discounts and Offers: Encourage Hibernating customers to shop again by offering them exclusive discounts and special offers. For example, you can provide greater discounts or advantageous packages compared to their previous purchases.
* Personalized Communication: Remind customers by sending them personalized emails or notifications. Offering recommendations based on their past purchases and interests can highlight products that may capture their attention.
* Loyalty Programs: Create loyalty programs to incentivize customers to shop more frequently. Rewarding their loyalty with loyalty points, discount coupons, or free products can be effective.
* Collect Feedback: Gather feedback from customers to learn how you can improve your service and products. Understanding their expectations can assist in providing a better experience.
