# **RFM Analysis With PostgreSQL** :hourglass: :bar_chart: :moneybag:

![png-rfm](https://rfmcube.com/wp-content/uploads/2021/07/1_HiwX6vul8c4PBEueq3yBMw-750x350.png)

* :pushpin: Dataset ; https://www.kaggle.com/nathaniel/uci-online-retail-ii-data-set
* You can review the RFM analysis with a detailed explanation in my Python project, which involves different years of the same dataset.
* [RFM Analysis With Python](https://github.com/hamzaugursumer/RFMAnalysisWithPython)
* (There are two pages in the dataset covering different years. I utilized the second sheet that encompasses the years 2010 - 2011.)

## Since the data set is old, the maximum invoice number in the data is taken as today.
````sql
-- Last invoicing date in the data set	
select 
	max(invoice_date) as last_invoice(today)
from e_commerce_data
where customer_id != 'NULL'
````
|   | last_invoice(today)|
|---|--------------------|
| 1 |        373         |
