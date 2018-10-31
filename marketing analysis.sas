/*formating the dataset*/
DATA F500;
SET xihui.F500(rename=(Total_Return_to_Investors = Total_Return_to_Investors_c));
  	Total_Return_to_Investors = input(Total_Return_to_Investors_c,best.);
  	Market_Val_March_31_2014=input(Market_Value_on_March_31__2014__, best.);
	Profit_change_from_prev_yr=input(Profit____change_from_previous_y, best.);
	Profit_pct_of_Assets=input(Profit_as_a___of_Assets, best.);
	Profit_pct_of_Sales=input(Profit_as_a___of_Sales, best.);
	Profit_pct_of_Stockholders_Eqty=input(Profit_as_a___of_Stockholders__E, best.);
	Revenue_change_from_prev_yr=input(Revenue____change_from_previous, best.);
	Total_Return_to_Investors_10_yr=input(Total_Return_to_Investors__10_ye, best.);
	Total_Return_to_Investors_5_yr=input(Total_Return_to_Investors__5_yea, best.);
	Total_Shareholder_Equity=input(Total_Shareholder_Equity____Mill, best.);
	Revenue=input(VAR8, best.);
	Profit=input(VAR10, best.);
	Tot_asset=input(VAR12, best.);
	EPS=input(VAR18, best.);
	/*EPS_change_from_2012=input(VAR19, best.);
	EPS_change_5_yr=input(VAR20, best.);
	EPS_change_10_yr=input(VAR21, best.);*/

drop Total_Return_to_Investors_c Market_Value_on_March_31__2014__ Profit____change_from_previous_y
Profit_as_a___of_Assets Profit_as_a___of_Sales Profit_as_a___of_Stockholders__E Revenue____change_from_previous
Total_Return_to_Investors__10_ye Total_Return_to_Investors__5_yea Total_Shareholder_Equity____Mill
VAR8 VAR10 VAR12 VAR18 VAR19 VAR20 VAR21
;
run;

proc sql;
create table summary as 
select a.company_name,
a.total_return_to_investors,
sum(b.revenue) as sum_revenue
from xihui.F500 a
inner join xihui. _Revenue b
on a.company_id=b.company_id
group by 1
order by 2 desc;
quit;


/* _Revenue*/
/*Q1:  what's the total revenue did wells gain from each company betwen 2014 and 2016?*/
proc sql;
select distinct year from xihui. _revenue
;
quit;
/*2014,2015,2016*/

proc sql;
select 
sum(revenue) into: total_sum
from  xihui.Revenue;
quit;

proc sql;
create table xihui.revenue_summary as 
select company_id,company_name,
sum(revenue) as sum_revenue,
sum(case when year=2014 then revenue else 0 end) format dollar20. as sum_revenue_2014,
sum(case when year=2015 then revenue else 0 end) format dollar20. as sum_revenue_2015,
sum(case when year=2016 then revenue else 0 end) format dollar20. as sum_revenue_2016,
calculated sum_revenue_2015/calculated sum_revenue_2014-1 format percent7.2 as increase_14_to_15,
calculated sum_revenue_2016/calculated sum_revenue_2015-1 format percent7.2 as increase_15_to_16,
calculated sum_revenue_2016/calculated sum_revenue_2014-1 format percent7.2 as increase_14_to_16
from xihui. _Revenue 
group by 1,2
order by sum_revenue desc;
quit;

/*Q1.1 what the total revenue did wells gain from each sector between 2014 and 2016*/
proc sql;
create table xihui.revenue_sec_summary as 
select b.GICS_sector,
count(distinct a.company_id) as company_cnt,
sum(a.revenue) format dollar20. as sum_revenue,
calculated sum_revenue/&total_sum. format percent7.2 as per_revenue,
sum(case when year=2014 then a.revenue else 0 end) format dollar20. as sum_revenue_2014,
sum(case when year=2015 then a.revenue else 0 end) format dollar20. as sum_revenue_2015,
sum(case when year=2016 then a.revenue else 0 end) format dollar20. as sum_revenue_2016,
calculated sum_revenue_2015/calculated sum_revenue_2014-1 format percent7.2 as increase_14_to_15,
calculated sum_revenue_2016/calculated sum_revenue_2015-1 format percent7.2 as increase_15_to_16
from xihui.Revenue a
inner join xihui.F500 b
on a.company_id=b.company_id
group by 1
order by 3 desc;
quit;
/*observation: 
Out of 11 sectors,
1. top 3 sector: IT, Financial, Healthcare occupies about half of the total revenue, but revenue increase becomes flat in 2016
	they deserve more marketing resources in the coming years.  
2. Utilitie,Telecommunication Services,Materials,Consumer Staples shows significant increase from 2015-2016. */

/*Research: The company that shows decrease in   revenue but shows good profit gain and return to investor in F500 deserve our attention for marketing?
Ideally, the bank should earn more money from the company which is getting better profit in recent years. 
Let's prove it check correlation!
*/


proc sql;
create table xihui.F500_revenue_summary as
select a.*,b.*,c.EOP_commitment, c.EOP_outstanding, sum_revenue/c.eop_outstanding as ROI
from xihui. _revenue_summary A
inner join F500 B
on a.company_id=b.company_id
inner join xihui.exposure c
on a.company_id=c.legal_entity_id
;
quit;
/*500*/

ods graphics on;
title 'Correlation between   Revenue & F500';
proc corr data=xihui.F500_ _revenue_summary nomiss;
   var Profit_change_from_prev_yr Revenue_change_from_prev_yr EPS Profit_pct_of_Assets Total_Return_to_Investors
   increase_14_to_15 increase_15_to_16 increase_14_to_16 sum_revenue EOP_commitment EOP_outstanding /*roi*/;
run;
ods graphics off;
/*Observation 1. Profit_change_from_prev_yr and increase_14_to_15 shows strong positive relationship
which proves good profit of the F500 company should suggests good revenue   can earn from the company!*/
/*Observation 2. EOP_oustanding and sum_of_revenue shows some positive relationship
which indicates Exposure helps to increase to the Revenue */


/*If the opposite of Observation 1 is observed, it may indicate our product is losing competition power against our peers */
DATA counter_exmamples;
SET xihui.F500_revenue_summary;
WHERE Profit_change_from_prev_yr between 5 and 50 
and increase_14_to_15<0
;
run;


/*draw scatterplot*/
proc sgplot data = xihui.F500_ _revenue_summary; *STARTS THE PROC; 
scatter x = EOP_outstanding y = sum_revenue / group=GICS_sector; *CREATES A PLOT, NOTE THE USE OF X = AND Y =; 
run;

proc reg data=xihui.F500_ _revenue_summary;
   model  sum_revenue = EOP_outstanding;
   ods output ParameterEstimates=PE;
run;
/*1. shows EOP outstanding contributes to sum_revenue siginificantly given the slope is 0.01. 
IN other words, it proves more money invest on marketing, the more revenue is expected
2. 5-6 clusters can be obsersed. using hierachical clustering or based on observation
*/

data _null_;
   set PE;
   if _n_ = 1 then call symput('Int', put(estimate, BEST6.));    
   else            call symput('Slope', put(estimate, BEST6.));  
run;

proc sgplot data=xihui.F500_ _revenue_summary noautolegend;
   title "Regression Line with Slope and Intercept";
   reg y=sum_revenue x=EOP_outstanding;
   inset "Intercept = &Int" "Slope = &Slope" / 
         border title="Parameter Estimates" position=topleft;
run;
/*Move to Tableau to further visualize regression and cluster analysis*/



/*what's the total revenue did wells gain from each product between 2014 and 2016?*/
/*proc sql;
create table xihui.prod_revenue_summary as 
select product_family,product,
count(distinct a.company_id) as company_cnt,
count(distinct b.gics_sector) as sector_cnt,
sum(a.revenue) format dollar20. as sum_revenue,
calculated sum_revenue/&total_sum. format percent7.2 as per_revenue,
sum(case when year=2014 then a.revenue else 0 end) format dollar20. as sum_revenue_2014,
sum(case when year=2015 then a.revenue else 0 end) format dollar20. as sum_revenue_2015,
sum(case when year=2016 then a.revenue else 0 end) format dollar20. as sum_revenue_2016,
calculated sum_revenue_2015/calculated sum_revenue_2014-1 format percent7.2 as increase_14_to_15,
calculated sum_revenue_2016/calculated sum_revenue_2015-1 format percent7.2 as increase_15_to_16
from xihui.Revenue a
inner join xihui.F500 b
on a.company_id=b.company_id
group by 1,2
order by sum_revenue desc;
quit;
/*Observation:
Out of 53 products, 
1. Lines of Credit is most widely used products and consists about 1 quarter of the overall revenue, shows big increase from 2015 to 2016
*/



