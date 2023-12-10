
//=============================================================================================================
**Step 1: Downloading data from the website in txt form. There are two datasets, one for first visit and the other one for revists. In the analysis, I have used first visit data.**
*I downloaded the datatset and all the suppoting files such as the readme pdf and the shedules for the visit and the data layout excel file as well.


*Step 2: Extracting of data*
*Step 2a: We know that the data is encoded based on the codes in the data layout file so I executed a simple concantenate code in excel to make the extraction easier. I have attached the excel file for the reference.
*Step 2b: I have then used stata to create a dictionary in stata and saved it. 
*Step 2c: I have then used a code in stata to make a dictionary. I am attaching the dictionary as well in the mail. 


*Step 3: Using the dictionary, I am importing the data
 infile using "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\dic_visit1.do"
 save "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\level_1"

 
*Step 4: Preparing the data for analysis
label variable a36 "MLTS-Sub-sample wise Multiplier" // for clarity as these variables will be used later. 
label variable a34 "NSS-Ns count for sector x stratum x substratum x sub-sample"
label variable a35 "NSC-Ns count for sector x stratum x substratum"

destring a35 a34 a36, replace //converting the variables from string to byte
gen weight = a36/100 if a34 == a35 // Applying weights
replace weight = a36/200 if a34!= a35
gen HHID = a13+ a14+ a15 +a16 // generating HHID 
gen comb_religion_caste= a23+ a24 // generating combined ID for religion and social group


*Step 5: Analysis 
tab a24 
label define a24 1 ST 2 SC 3 OBC 9 others // Naming the categorical variable of social group
destring a24, replace
label values a24 a24
tab a24

label define a23 1 Hinduism 2 Islam 3 Christianity 4 Sikhism 5 Jainism 6 Buddhism 7 Zoroastrianism 9 others // naming categorical variable of religion
destring a23, replace
label values a23 a23
tab a23

tab a8 // For the state, we have NSS region
gen str state1=substr( a8,1,2) // We need to extract the first two numbers which denotes the state code

//Labelling the state code 
label define state1 1 "Jammu & Kashmir" 2 "Himachal Pradesh" 3 "Punjab" 4 "Chandigarh" 5 "Uttarakhand" 6 "Haryana" 7 "Delhi" 8 "Rajasthan" 9 "Uttar Pradesh" 10 "Bihar" 11 "Sikkim" 12 "Arunachal Pradesh" 13 "Nagaland" 14 "Manipur" 15 "Mizoram" 16 "Tripura" 17 "Meghalaya" 18 "Assam" 19 "West Bengal" 20 "Jharkhand" 21 "Orissa" 22 "Chattisgarh" 23 "Madhya Pradesh" 24 "Gujrat" 25 "Daman and Diu" 26 "Dadra and Nagar Haveli" 27 "Maharashtra" 28 "Andhra Pradesh" 29 "Karnataka" 30 "Goa" 31 "Lakshadweep" 32 "Kerela" 33 "TN" 34 "Puducherry" 35 "A&NIsland" 36 "Telangana"  
destring state1, replace
label values state1 state1
tab state1


*Step 6: Running the regression*
*The household comsumption is the dependent variable and the state, religion, and social group are the independent variable. I will be regressing the household consumption on the 3 categorical variables.
* This will give us a clear picture regrading the consumption based on the religion, social group, and state which would help highlight disparities on basis of caste and religion and among the states too. 
reg a30 i.a24 i.a23 i.state1

 
*Step 7: Bar chart of average average househld per capita consumption across different states in ascending order. 
graph bar (mean) a30 , over( state1 )
graph display Graph, xsize(10)//resizing it
graph export "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\Graph.png", as(png) replace //saving thr graph as png
drop a1 a2 a3 a4 a5 a6 a7 a8 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 a22 a25 a25 a26 a27 a28 a29 a31 a32 a33 a34 a35 a36 a37 weight HHID
comb_religion_caste a24 a30 a23 // dropping unnecessary variables


*Step 8: Modifying the data to facilate the merger with price data
destring a21, replace
table state1 , contents(sum a21 ) row replace
rename table1 sum_of_hhh_memebers
drop if missing( state1 )
recast long state1// encoding state variable from string to long to facilitate merger 
save "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\level_1_new"
clear

//===========================================================================================================

*Step 9: Working with price data
*I saved the excel file as TXT file and then imported it to stata
import delimited "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\prices.txt", clear 
drop jan20 feb20 mar20 apr20 may20 jun2020 jul21 aug21 sep21 oct21 nov21 dec21 jan22 feb22 mar22 apr22 may22//As the PLFS data is from July 2020-June 2021, I am dropping of all the other monthly prices of rice.

egen avg_price = rmean(jul20 aug20 sep20 oct20 nov20 dec20 jan21 feb21 mar21 apr21 may21 jun2021)// average price for each city over these months
table state , contents(mean avg_price ) row replace // average price for every state and replacing the data with new data to facilitate merger with hh data
rename table1 avg_price_in_state
drop if missing( state )
encode state, generate(state1)// encoding the state variable from byte to long variable to facilitate merger
drop state
save "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\price_new"
clear

//=============================================================================================================

*Step 10: Merging the data
use "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\level_1_new.dta" //using the  "level_1_new" that I have saved earlier and merging it with the price data
merge 1:1 state1 using "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\price_new.dta"// merging the price data with hh data
drop _merge state
gen Total_exp = avg_price_in_state* sum_of_hhh_memebers*2 // generating total expenditure
table state1, contents(mean Total_exp)// a table showing total expenditure of every state
outsheet state1 Total_exp using "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\consum_expen.csv", replace comma// saving the table as csv 
save "C:\Users\USer\OneDrive\Desktop\World Bank\Test\Final documents\merged_data.dta"

//==============================================END============================================================
