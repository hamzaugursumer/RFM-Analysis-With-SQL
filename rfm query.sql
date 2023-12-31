-- Last invoicing date in the data set	
select 
	max(invoice_date)
from e_commerce_data
where customer_id != 'NULL'

"2011-12-09 12:50:00"
;

-------------------------------------------------------------------------------------------------------
-- The query containing the RFM values and scores of each customer is as follows.

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
;


-----------------------------------------------------------------------------------------------------

-- The query containing the RFM values, scores and segmentation groups of each customer is as follows.


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
from segment;

