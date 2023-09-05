# **RFM Analysis With PostgreSQL** :hourglass: :bar_chart: :moneybag:

![png-rfm](https://rfmcube.com/wp-content/uploads/2021/07/1_HiwX6vul8c4PBEueq3yBMw-750x350.png)

* :pushpin: Dataset ; https://www.kaggle.com/nathaniel/uci-online-retail-ii-data-set
* You can review the RFM analysis with a detailed explanation in my Python project, which involves different years of the same dataset.
* [RFM Analysis With Python](https://github.com/hamzaugursumer/RFMAnalysisWithPython)
* (There are two pages in the dataset covering different years. I utilized the second sheet that encompasses the years 2010 - 2011.)

## * **Since the data set is old, the maximum invoice number in the data is taken as today.**
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
        
## * **The query containing the RFM values and scores of each customer is as follows.**
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
