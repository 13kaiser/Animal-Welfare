* Replication code for
* "Do Animals Matter? The Value of Animal Welfare Information to Consumers"
*
* Input:  data/merged_data.dta
* Output: tables and figures in output/
*
* Requires Stata 18 or newer and the user-written packages estout, coefplot,
* cibar and blindschemes (ssc install <name>). The margins grids and the
* bootstrap of the welfare inputs take a while to run.

clear

* Run from the repository folder, or set the path here.
global root "`c(pwd)'"
global data    "$root/data"
global out     "$root/output"
global welfare "$out/welfare"

capture mkdir "$out"
capture mkdir "$out/contour"
capture mkdir "$welfare"
cd "$out"

set scheme plotplain

use "$data/merged_data.dta", clear

* Drops implausible values of years of education; missing values are dropped as well.
drop if yearseducation>30

* Value labels

label define diet ///
    1 "[1] Never (vegan)" ///
    2 "[2] Infrequently (vegetarian – eggs/dairy, no meat)" ///
    3 "[3] Occasionally (really like veggies – occasional meat, eggs/dairy)" ///
    4 "[4] Often (balanced meat/veggies – meat a few times a week, eggs/dairy almost daily)" ///
    5 "[5] Very often (meat daily)"
label values Diet diet

label define yesno ///
    1 "[1] Yes" ///
    2 "[2] No"
label values Pets yesno
label values Org yesno
label values labelcuriosity yesno

label define whichrel ///
    1 "[1] Christianity" ///
    2 "[2] Judaism" ///
    3 "[3] Islam" ///
    4 "[4] Hinduism" ///
    5 "[5] Buddhism" ///
    6 "[6] Another religion" ///
    7 "[7] I am not religious" ///
    99 "[99] Prefer not to say"
label values whichrel whichrel

label define howrel ///
    1 "[1] Not religious at all" ///
    2 "[2]" ///
    3 "[3]" ///
    4 "[4]" ///
    5 "[5]" ///
    6 "[6]" ///
    7 "[7] Very religious" ///
    99 "[99] Prefer not to say"
label values howrel howrel

label define epvq ///
    1 "[1] Not at all like me" ///
    2 "[2]" ///
    3 "[3]" ///
    4 "[4]" ///
    5 "[5]" ///
    6 "[6]" ///
    7 "[7] Very much like me"
label values EPVQ_1 epvq
label values EPVQ_2 epvq
label values EPVQ_3 epvq
label values EPVQ_5 epvq

gen bioval= (EPVQ_1 + EPVQ_2 + EPVQ_3 + EPVQ_5 )/4

label define lookforlabels ///
    1 "[1] Yes, most of the time" ///
    2 "[2] Yes, sometimes" ///
    3 "[3] No, or very rarely" ///
    4 "[4] No, never" ///
    5 "[5] I didn't know these labels existed" ///
    6 "[6] Don't know" ///
    7 "[7] Not applicable - I don't purchase animal products"
label values Lookforlabels lookforlabels

label define currchoice ///
    1 "[1] Yes, certainly" ///
    2 "[2] Yes, probably" ///
    3 "[3] No, probably not" ///
    4 "[4] No, certainly not" ///
    5 "[5] Don't know"
label values Currchoice currchoice

label define regularcontacts1 ///
    0 "[0] Not selected" ///
    1 "[1] Yes, with my own companion animal(s)"
label values Regularcontacts_1 regularcontacts1

label define regularcontacts2 ///
    0 "[0] Not selected" ///
    1 "[1] Yes, with other companion animal(s)"
label values Regularcontacts_2 regularcontacts2

label define regularcontacts3 ///
    0 "[0] Not selected" ///
    1 "[1] Yes, with farming animals"
label values Regularcontacts_3 regularcontacts3

label define regularcontacts4 ///
    0 "[0] Not selected" ///
    1 "[1] Yes, with other animals"
label values Regularcontacts_4 regularcontacts4

label define age_yks ///
    1 "[1] 18-29" ///
    2 "[2] 30-44" ///
    3 "[3] 45-64" ///
    4 "[4] 65+"
label values age_yks age_yks

label define gender ///
    1 "[1] Male" ///
    2 "[2] Female"
label values gender gender

label define income_quartile ///
    1 "[1] Lowest 25%" ///
    2 "[2] 25% to 50%" ///
    3 "[3] 50% to 75%" ///
    4 "[4] Highest 25%"
label values income_quartile income_quartile

label define married ///
    0 "[0] Not married" ///
    1 "[1] Married"
label values married married

label define workfulltime ///
    0 "[0] Not full time" ///
    1 "[1] Full time"
label values workfulltime workfulltime

gen countr=.

replace countr=1 if country=="Denmark"
replace countr=2 if country=="France"
replace countr=3 if country=="Germany"
replace countr=4 if country=="Netherlands"
replace countr=5 if country=="UK"
replace countr=6 if country=="US"

label define countr ///
    1 "[1] Denmark" ///
    2 "[2] France" ///
    3 "[3] Germany" ///
    4 "[4] Netherlands" ///
    5 "[5] UK" ///
    6 "[6] USA"
label values countr countr

drop country
rename countr country

* Control variables
glo sociodemo i.age_yks i.gender i.married i.country
glo values i.whichrel i.howrel bioval
glo lifestyle i.Diet i.Pets i.Org i.labelcuriosity i.Lookforlabels i.Regularcontacts_1 i.Regularcontacts_2  i.Regularcontacts_3  i.Regularcontacts_4  labelscore i.Currchoice
glo socioeco i.income_quartile i.workfulltime yearseducation i.workfulltime

* Recalled prices in euros; 0 = category not bought
rename PRICE1x_euros prc_meat
replace prc_meat=. if prc_meat==0

rename PRICE2x_euros prc_egg
replace prc_egg=. if prc_egg==0

rename PRICE3x_euros prc_milk
replace prc_milk=. if prc_milk==0

rename PRICE4x_euros prc_fur
replace prc_fur=. if prc_fur==0

rename PRICE5x_euros prc_leather
replace prc_leather=. if prc_leather==0

rename PRICE6x_euros prc_cosmetic
replace prc_cosmetic=. if prc_cosmetic==0

rename PRICE7x_euros prc_pfood
replace prc_pfood=. if prc_pfood==0

rename PRICE8x_euros prc_otc
replace prc_otc=. if prc_otc==0

* Willingness to know (WTK): 0 no, 1 yes, 2 already knew the information
label define wtk 0 "No" 1 "Yes" 2 "Knew info"

rename INF1PREF wtk_meat
recode wtk_meat (2 = 0) (3 =2)
label values wtk_meat wtk

rename INFPREF2 wtk_egg
recode wtk_egg (2 = 0) (3 =2)
label values wtk_egg wtk

rename INFOPREF3 wtk_milk
recode wtk_milk (2 = 0) (3 =2)
label values wtk_milk wtk

rename INFOPREF4 wtk_fur
recode wtk_fur (2 = 0) (3 =2)
label values wtk_fur wtk

rename INFOPREF5 wtk_leather
recode wtk_leather (2 = 0) (3 =2)
label values wtk_leather wtk

rename INFOPREF6 wtk_cosmetic
recode wtk_cosmetic (2 = 0) (3 =2)
label values wtk_cosmetic wtk

rename INFOPREF7 wtk_pfood
recode wtk_pfood (2 = 0) (3 =2)
label values wtk_pfood wtk

rename INFOPREF8 wtk_otc
recode wtk_otc (2 = 0) (3 =2)
label values wtk_otc wtk

* WTP / WTPn as % of the recalled price
rename  WTP1 wtp_meat_prct
rename  WTP2 wtp_egg_prct
rename  WTP3 wtp_milk_prct
rename  WTP4 wtp_fur_prct
rename  WTP5 wtp_leather_prct
rename  WTP6 wtp_cosmetic_prct
rename  WTP7 wtp_pfood_prct
rename  WTP8 wtp_otc_prct

rename  WTPn1 wtpn_meat_prct
rename  WTPn2 wtpn_egg_prct
rename  WTPn3 wtpn_milk_prct
rename  WTPn4 wtpn_fur_prct
rename  WTPn5 wtpn_leather_prct
rename  WTPn6 wtpn_cosmetic_prct
rename  WTPn7 wtpn_pfood_prct
rename  WTPn8 wtpn_otc_prct

* WTP / WTPn in euros
gen wtp_meat     = prc_meat     * wtp_meat_prct  / 100
gen wtp_egg      = prc_egg      * wtp_egg_prct         / 100
gen wtp_milk     = prc_milk     * wtp_milk_prct        / 100
gen wtp_fur      = prc_fur      * wtp_fur_prct         / 100
gen wtp_leather  = prc_leather  * wtp_leather_prct     / 100
gen wtp_cosmetic = prc_cosmetic * wtp_cosmetic_prct    / 100
gen wtp_pfood    = prc_pfood    * wtp_pfood_prct       / 100
gen wtp_otc      = prc_otc      * wtp_otc_prct         / 100

gen wtpn_meat     = prc_meat     * wtpn_meat_prct      / 100
gen wtpn_egg      = prc_egg      * wtpn_egg_prct       / 100
gen wtpn_milk     = prc_milk     * wtpn_milk_prct      / 100
gen wtpn_fur      = prc_fur      * wtpn_fur_prct       / 100
gen wtpn_leather  = prc_leather  * wtpn_leather_prct   / 100
gen wtpn_cosmetic = prc_cosmetic * wtpn_cosmetic_prct  / 100
gen wtpn_pfood    = prc_pfood    * wtpn_pfood_prct     / 100
gen wtpn_otc      = prc_otc      * wtpn_otc_prct       / 100

gen id=[_n]

* Information-value scale: affective, instrumental and cognitive items
rename Q4_1 aff_1
rename Q4_2 aff_2
rename Q4_3 inst_1
rename Q4_4 inst_2
rename Q4_5 cogn_1
rename Q4_6 cogn_2
rename Q4_7 cogn_3

* Reliability and confirmatory factor analysis
alpha aff_1 aff_2
alpha inst_1 inst_2
alpha cogn_1 cogn_2 cogn_3

sem (Aff -> aff_1 aff_2) (Inst -> inst_1 inst_2) (Cogn -> cogn_1 cogn_2 cogn_3), vce(sbentler)
estat gof, stats(all)
sem, standardized

gen aff_mean=(aff_1 + aff_2)/2

gen inst_mean=(inst_1+inst_2)/2

gen cogn_mean=(cogn_1+cogn_2+cogn_3)/3

* =============================================================
* Willingness to know (WTK)
* =============================================================

* --- WTK average over the categories, excluding "already knew" ---
foreach v in wtk_meat wtk_egg wtk_milk wtk_fur wtk_leather wtk_cosmetic wtk_pfood wtk_otc {
    gen `v'_aux = `v'
    replace `v'_aux = . if `v'==2
}

egen  wtk_mean=rowmean( wtk_meat_aux wtk_egg_aux wtk_milk_aux wtk_fur_aux wtk_leather_aux wtk_cosmetic_aux wtk_pfood_aux wtk_otc_aux)

egen wtk_confidence_score=rowtotal(wtk_meat_aux wtk_egg_aux wtk_milk_aux wtk_fur_aux wtk_leather_aux wtk_cosmetic_aux wtk_pfood_aux wtk_otc_aux)

drop wtk_meat_aux wtk_egg_aux wtk_milk_aux wtk_fur_aux wtk_leather_aux wtk_cosmetic_aux wtk_pfood_aux wtk_otc_aux

* --- Eligibility dummies: in the market for category X & not already informed ---
gen elig_meat     = (prc_meat<.     & wtk_meat!=2)
gen elig_egg      = (prc_egg<.      & wtk_egg!=2)
gen elig_milk     = (prc_milk<.     & wtk_milk!=2)
gen elig_fur      = (prc_fur<.      & wtk_fur!=2)
gen elig_leather  = (prc_leather<.  & wtk_leather!=2)
gen elig_cosmetic = (prc_cosmetic<. & wtk_cosmetic!=2)
gen elig_pfood    = (prc_pfood<.    & wtk_pfood!=2)
gen elig_otc      = (prc_otc<.      & wtk_otc!=2)

* --- WTK logits (one per product category) ---
eststo clear

eststo meat:     logit wtk_meat     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if    wtk_meat!=2     , vce(ro)
eststo egg:      logit wtk_egg      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if    wtk_egg!=2     , vce(ro)
eststo milk:     logit wtk_milk     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if   wtk_milk!=2     , vce(ro)
eststo fur:      logit wtk_fur      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if    wtk_fur!=2      , vce(ro)
eststo leather:  logit wtk_leather  aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if  wtk_leather!=2  , vce(ro)
eststo cosmetic: logit wtk_cosmetic aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if     wtk_cosmetic!=2 , vce(ro)
eststo pfood:    logit wtk_pfood    aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco  if    wtk_pfood!=2    , vce(ro)
eststo otc:      logit wtk_otc      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco   if    wtk_otc!=2     , vce(ro)

* --- WTK overall index (OLS) ---
eststo wtkmean: reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

esttab meat egg milk fur leather cosmetic pfood otc wtkmean using "wtk_results.rtf", replace ///
    mtitles("Meat" "Eggs" "Milk" "Fur" "Leather" "Cosmetics" "Pet food" "OTC" "WTK index") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2_p r2, fmt(0 3 3) labels("Observations" "Pseudo R-sq." "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to know about animal welfare")

* --- Country-specific WTK index regressions ---
* controls without the country dummies
eststo clear

eststo wtkmean_denm: reg wtk_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc if country==1, vce(ro)

eststo wtkmean_fran: reg wtk_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc if country==2, vce(ro)

eststo wtkmean_germ: reg wtk_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc if country==3, vce(ro)

eststo wtkmean_neth: reg wtk_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc if country==4, vce(ro)

eststo wtkmean_uk:   reg wtk_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc if country==5, vce(ro)

eststo wtkmean_us:   reg wtk_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc if country==6, vce(ro)

esttab wtkmean_denm wtkmean_fran wtkmean_germ wtkmean_neth wtkmean_uk wtkmean_us using "wtk_country_results.rtf", replace ///
    mtitles("Denmark" "France" "Germany" "Netherlands" "UK" "US") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to know about animal welfare, by country")

* --- Predicted WTK over instrumental x cognitive value, at low (1) and high (7) affective value ---

reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

margins, at(inst_mean=(1(0.25)7) cogn_mean=(1(0.25)7) aff_mean=(1 2 3 4 5 6 7)) ///
    saving("$out/contour/margins_grid.dta", replace)

preserve
use "$out/contour/margins_grid.dta", clear

local opts ccuts(0.5) ///
           crule(intensity) scolor(white) ecolor(navy) ///
           ytitle("") xtitle("") ylabel(1 4 7) xlabel(1 4 7)

twoway contour _margin _at3 _at2 if _at1==1, `opts' clegend(off) ///
    title("Low affective value", size(medium)) name(aff_low, replace)

twoway contour _margin _at3 _at2 if _at1==7, `opts' clegend(off) ///
    title("High affective value", size(medium)) name(aff_high, replace)

graph combine aff_low aff_high, ///
    rows(1) ///
    l1title("Cognitive value") b1title("Instrumental value") ///
    imargin(small)

graph export "$out/contour/wtk_contour_lowhigh.png", ///
    replace width(2800)

restore

* --- Predicted WTK over each value component ---

reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)
margins, at(aff_mean=(1(1)7)) post
est store Affective

reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)
margins, at(inst_mean=(1(1)7)) post
est store Instrumental

reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)
margins, at(cogn_mean=(1(1)7)) post
est store Cognitive

coefplot Affective Instrumental Cognitive, ///
    at recast(line) lwidth(*1) noci ///
    p1(lcolor(navy)   mcolor(navy)) ///
    p2(lcolor(maroon) mcolor(maroon)) ///
    p3(lcolor(dkgreen) mcolor(dkgreen)) ///
    ytitle("Predicted WTK") xtitle("Predictor value") ///
    legend(order(1 "Affective" 2 "Instrumental" 3 "Cognitive") rows(1) position(6) size(small))

graph export "$out/wtk_predictions.png", ///
    replace width(2800)

* =============================================================
* WTP percentage  (willingness to pay to RECEIVE information, % of price)
* =============================================================
* WTP eligibility = answered the receive-question (i.e. said Yes & bought)
gen elig_wtp_meat     = (wtp_meat<.)
gen elig_wtp_egg      = (wtp_egg<.)
gen elig_wtp_milk     = (wtp_milk<.)
gen elig_wtp_fur      = (wtp_fur<.)
gen elig_wtp_leather  = (wtp_leather<.)
gen elig_wtp_cosmetic = (wtp_cosmetic<.)
gen elig_wtp_pfood    = (wtp_pfood<.)
gen elig_wtp_otc      = (wtp_otc<.)

egen wtp_prct_mean = rowmean(wtp_meat_prct wtp_egg_prct wtp_milk_prct wtp_fur_prct wtp_leather_prct wtp_cosmetic_prct wtp_pfood_prct wtp_otc_prct)
egen wtp_prct_ncat = rownonmiss(wtp_meat_prct wtp_egg_prct wtp_milk_prct wtp_fur_prct wtp_leather_prct wtp_cosmetic_prct wtp_pfood_prct wtp_otc_prct)

* --- WTP (%) single-item OLS (one per category) ---
eststo clear
eststo wtp_meat_prct:     reg wtp_meat_prct     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_egg_prct:      reg wtp_egg_prct      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_milk_prct:     reg wtp_milk_prct     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_fur_prct:      reg wtp_fur_prct      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_leather_prct:  reg wtp_leather_prct  aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_cosmetic_prct: reg wtp_cosmetic_prct aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_pfood_prct:    reg wtp_pfood_prct    aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_otc_prct:      reg wtp_otc_prct      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)

* --- WTP (%) index OLS ---
eststo wtp_prct_index: reg wtp_prct_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

esttab wtp_meat_prct wtp_egg_prct wtp_milk_prct wtp_fur_prct wtp_leather_prct wtp_cosmetic_prct wtp_pfood_prct wtp_otc_prct wtp_prct_index using "wtp_prct_results.rtf", replace ///
    mtitles("Meat" "Eggs" "Milk" "Fur" "Leather" "Cosmetics" "Pet food" "OTC" "WTP index") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to pay (% of price) for animal welfare information")

* --- Country-specific WTP (% of price) index regressions ---
* controls without the country dummies
eststo clear

eststo wtpprct_denm: reg wtp_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc if country==1, vce(ro)

eststo wtpprct_fran: reg wtp_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc if country==2, vce(ro)

eststo wtpprct_germ: reg wtp_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc if country==3, vce(ro)

eststo wtpprct_neth: reg wtp_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc if country==4, vce(ro)

eststo wtpprct_uk:   reg wtp_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc if country==5, vce(ro)

eststo wtpprct_us:   reg wtp_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc if country==6, vce(ro)

esttab wtpprct_denm wtpprct_fran wtpprct_germ wtpprct_neth wtpprct_uk wtpprct_us using "wtp_prct_country_results.rtf", replace ///
    mtitles("Denmark" "France" "Germany" "Netherlands" "UK" "US") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to pay (% of price) for animal welfare information, by country")

* =============================================================
* WTPn percentage  (willingness to pay to AVOID information, % of price)
* =============================================================
egen wtpn_prct_mean = rowmean(wtpn_meat_prct wtpn_egg_prct wtpn_milk_prct wtpn_fur_prct wtpn_leather_prct wtpn_cosmetic_prct wtpn_pfood_prct wtpn_otc_prct)
egen wtpn_prct_ncat = rownonmiss(wtpn_meat_prct wtpn_egg_prct wtpn_milk_prct wtpn_fur_prct wtpn_leather_prct wtpn_cosmetic_prct wtpn_pfood_prct wtpn_otc_prct)

* WTPn eligibility = answered the avoid-question (i.e. said No & bought)
gen elig_wtpn_meat     = (wtpn_meat<.)
gen elig_wtpn_egg      = (wtpn_egg<.)
gen elig_wtpn_milk     = (wtpn_milk<.)
gen elig_wtpn_fur      = (wtpn_fur<.)
gen elig_wtpn_leather  = (wtpn_leather<.)
gen elig_wtpn_cosmetic = (wtpn_cosmetic<.)
gen elig_wtpn_pfood    = (wtpn_pfood<.)
gen elig_wtpn_otc      = (wtpn_otc<.)

* --- WTPn (%) single-item OLS (one per category) ---
eststo clear
eststo wtpn_meat_prct:     reg wtpn_meat_prct     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_egg_prct:      reg wtpn_egg_prct      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_milk_prct:     reg wtpn_milk_prct     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_fur_prct:      reg wtpn_fur_prct      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_leather_prct:  reg wtpn_leather_prct  aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_cosmetic_prct: reg wtpn_cosmetic_prct aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_pfood_prct:    reg wtpn_pfood_prct    aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_otc_prct:      reg wtpn_otc_prct      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)

* --- WTPn (%) index OLS ---
eststo wtpn_prct_index: reg wtpn_prct_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

esttab wtpn_meat_prct wtpn_egg_prct wtpn_milk_prct wtpn_fur_prct wtpn_leather_prct wtpn_cosmetic_prct wtpn_pfood_prct wtpn_otc_prct wtpn_prct_index using "wtpn_prct_results.rtf", replace ///
    mtitles("Meat" "Eggs" "Milk" "Fur" "Leather" "Cosmetics" "Pet food" "OTC" "WTPn index") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to pay to avoid (% of price) animal welfare information")

* --- Country-specific WTPn (% of price) index regressions ---
* controls without the country dummies
eststo clear

eststo wtpnprct_denm: reg wtpn_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc if country==1, vce(ro)

eststo wtpnprct_fran: reg wtpn_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc if country==2, vce(ro)

eststo wtpnprct_germ: reg wtpn_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc if country==3, vce(ro)

eststo wtpnprct_neth: reg wtpn_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc if country==4, vce(ro)

eststo wtpnprct_uk:   reg wtpn_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc if country==5, vce(ro)

eststo wtpnprct_us:   reg wtpn_prct_mean aff_mean inst_mean cogn_mean i.age_yks i.gender i.married $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc if country==6, vce(ro)

esttab wtpnprct_denm wtpnprct_fran wtpnprct_germ wtpnprct_neth wtpnprct_uk wtpnprct_us using "wtpn_prct_country_results.rtf", replace ///
    mtitles("Denmark" "France" "Germany" "Netherlands" "UK" "US") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to pay to avoid (% of price) animal welfare information, by country")

* --- WTK by product category, excluding "already knew", sorted ---
preserve

gen long _pid = _n
keep _pid wtk_meat wtk_egg wtk_milk wtk_fur wtk_leather wtk_cosmetic wtk_pfood wtk_otc
reshape long wtk_, i(_pid) j(cat) string
rename wtk_ wtk

drop if wtk >= 2 | missing(wtk)          // drop "already knew"

collapse (mean) m = wtk (semean) se = wtk (count) n = wtk, by(cat)
gen lb = 100*(m - 1.96*se)
gen ub = 100*(m + 1.96*se)
replace m  = 100*m

gen str10 catlab = ""
replace catlab = "Meat"      if cat == "meat"
replace catlab = "Eggs"      if cat == "egg"
replace catlab = "Milk"      if cat == "milk"
replace catlab = "Fur"       if cat == "fur"
replace catlab = "Leather"   if cat == "leather"
replace catlab = "Cosmetics" if cat == "cosmetic"
replace catlab = "Pet food"  if cat == "pfood"
replace catlab = "OTC"       if cat == "otc"

gsort -m
gen pos = _n

local xlab ""
forvalues i = 1/`=_N' {
    local l = catlab[`i']
    local xlab `"`xlab' `i' "`l'""'
}

list catlab m lb ub n, noobs sep(0)

twoway ///
    (bar m pos, barwidth(0.6) color(navy*0.8) lcolor(navy)) ///
    (rcap ub lb pos, lcolor(gs6) lwidth(medthin)), ///
    ytitle("WTK (% wanting the information)") ///
    xtitle("Product category") ///
    xlabel(`xlab', noticks) ///
    ylabel(0(10)80, grid glpattern(dash) glcolor(gs13) angle(horizontal)) ///
    legend(off) scheme(plotplain) name(wtk_product, replace)

graph export "$out/D_wtk_product_sorted.png", replace width(2400)

restore

* --- Test of equal WTK shares across product categories (clustered by respondent) ---
preserve
gen long _pid = _n
keep _pid wtk_meat wtk_egg wtk_milk wtk_fur wtk_leather wtk_cosmetic wtk_pfood wtk_otc
reshape long wtk_, i(_pid) j(cat) string
rename wtk_ wtk
drop if wtk >= 2 | missing(wtk)
encode cat, gen(catn)

reg wtk i.catn, vce(cluster _pid)
testparm i.catn                                          // H0: all shares equal
pwcompare catn, effects mcompare(bonferroni)             // pairwise, clustered
restore

* =============================================================
* Log specification: ln(WTP+1) on ln(price)
* =============================================================

* --- logged outcomes and prices (single categories) ---
foreach p in meat egg milk fur leather cosmetic pfood otc {
    gen ln_wtp_`p'  = ln(wtp_`p'  + 1)
    gen ln_wtpn_`p' = ln(wtpn_`p' + 1)
    gen ln_prc_`p'  = ln(prc_`p')
}

* --- averages of the logged outcomes ---
egen ln_wtp_mean  = rowmean(ln_wtp_meat ln_wtp_egg ln_wtp_milk ln_wtp_fur ln_wtp_leather ln_wtp_cosmetic ln_wtp_pfood ln_wtp_otc)
egen ln_wtpn_mean = rowmean(ln_wtpn_meat ln_wtpn_egg ln_wtpn_milk ln_wtpn_fur ln_wtpn_leather ln_wtpn_cosmetic ln_wtpn_pfood ln_wtpn_otc)

* --- mean log price over the categories entering the respective outcome average ---
foreach p in meat egg milk fur leather cosmetic pfood otc {
    gen ln_prc_`p'_w  = ln_prc_`p' if wtp_`p'<.
    gen ln_prc_`p'_wn = ln_prc_`p' if wtpn_`p'<.
}
egen ln_prc_wtp_mean  = rowmean(ln_prc_meat_w ln_prc_egg_w ln_prc_milk_w ln_prc_fur_w ln_prc_leather_w ln_prc_cosmetic_w ln_prc_pfood_w ln_prc_otc_w)
egen ln_prc_wtpn_mean = rowmean(ln_prc_meat_wn ln_prc_egg_wn ln_prc_milk_wn ln_prc_fur_wn ln_prc_leather_wn ln_prc_cosmetic_wn ln_prc_pfood_wn ln_prc_otc_wn)
drop ln_prc_*_w ln_prc_*_wn

* =============================================================
* WTP (log euros)
* =============================================================
eststo clear
eststo wtp_meat:     reg ln_wtp_meat     ln_prc_meat     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_egg:      reg ln_wtp_egg      ln_prc_egg      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_milk:     reg ln_wtp_milk     ln_prc_milk     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_fur:      reg ln_wtp_fur      ln_prc_fur      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_leather:  reg ln_wtp_leather  ln_prc_leather  aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_cosmetic: reg ln_wtp_cosmetic ln_prc_cosmetic aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_pfood:    reg ln_wtp_pfood    ln_prc_pfood    aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtp_otc:      reg ln_wtp_otc      ln_prc_otc      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)

eststo wtp_average: reg ln_wtp_mean ln_prc_wtp_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

esttab wtp_meat wtp_egg wtp_milk wtp_fur wtp_leather wtp_cosmetic wtp_pfood wtp_otc wtp_average using "wtp_log_results.rtf", replace ///
    mtitles("Meat" "Eggs" "Milk" "Fur" "Leather" "Cosmetics" "Pet food" "OTC" "WTP average") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to pay for animal welfare information (log euros)") ///
    addnotes("Outcome: ln(WTP+1). Price enters in logs. The average column uses the mean of logged prices over the categories entering the outcome average.")

* =============================================================
* WTPn (log euros)
* =============================================================
eststo clear
eststo wtpn_meat:     reg ln_wtpn_meat     ln_prc_meat     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_egg:      reg ln_wtpn_egg      ln_prc_egg      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_milk:     reg ln_wtpn_milk     ln_prc_milk     aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_fur:      reg ln_wtpn_fur      ln_prc_fur      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_leather:  reg ln_wtpn_leather  ln_prc_leather  aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_cosmetic: reg ln_wtpn_cosmetic ln_prc_cosmetic aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_pfood:    reg ln_wtpn_pfood    ln_prc_pfood    aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
eststo wtpn_otc:      reg ln_wtpn_otc      ln_prc_otc      aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)

eststo wtpn_average: reg ln_wtpn_mean ln_prc_wtpn_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

esttab wtpn_meat wtpn_egg wtpn_milk wtpn_fur wtpn_leather wtpn_cosmetic wtpn_pfood wtpn_otc wtpn_average using "wtpn_log_results.rtf", replace ///
    mtitles("Meat" "Eggs" "Milk" "Fur" "Leather" "Cosmetics" "Pet food" "OTC" "WTPn average") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Determinants of the willingness to pay to avoid animal welfare information (log euros)") ///
    addnotes("Outcome: ln(WTPn+1). Price enters in logs. The average column uses the mean of logged prices over the categories entering the outcome average.")

* --- Standardize all continuous variables (dummies left raw) ---
egen wtk_mean_std       = std(wtk_mean)
egen wtp_prct_mean_std  = std(wtp_prct_mean)
egen wtpn_prct_mean_std = std(wtpn_prct_mean)

egen aff_mean_std  = std(aff_mean)
egen inst_mean_std = std(inst_mean)
egen cogn_mean_std = std(cogn_mean)

egen bioval_std        = std(bioval)
egen labelscore_std    = std(labelscore)
egen yearseducation_std = std(yearseducation)

* --- Controls with standardized continuous variables ---
glo sociodemo_std i.age_yks i.gender i.married i.country
glo values_std    i.whichrel i.howrel bioval_std
glo lifestyle_std i.Diet i.Pets i.Org i.labelcuriosity i.Lookforlabels i.Regularcontacts_1 i.Regularcontacts_2 i.Regularcontacts_3 i.Regularcontacts_4 labelscore_std i.Currchoice
glo socioeco_std  i.income_quartile i.workfulltime yearseducation_std

* --- Standardized regressions ---
eststo clear

eststo wtk_stand: reg wtk_mean_std aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

eststo wtp_stand: reg wtp_prct_mean_std aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

eststo wtpn_stand: reg wtpn_prct_mean_std aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

esttab wtk_stand wtp_stand wtpn_stand using "standardized_results.rtf", replace ///
    mtitles("WTK index" "WTP index (%)" "WTPn index (%)") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Standardized determinants of WTK, WTP and WTPn")

* --- Value components (H1-H3) ---

coefplot ///
    (wtk_stand,  keep(aff_mean_std inst_mean_std cogn_mean_std) mcolor(navy)        msymbol(O) ciopts(lcolor(navy))) ///
    (wtp_stand,  keep(aff_mean_std inst_mean_std cogn_mean_std) mcolor(maroon)      msymbol(D) ciopts(lcolor(maroon))) ///
    (wtpn_stand, keep(aff_mean_std inst_mean_std cogn_mean_std) mcolor(dkgreen)     msymbol(S) ciopts(lcolor(dkgreen))) ///
    , xline(0, lcolor(gs8) lpattern(dash)) ///
    coeflabels(aff_mean_std = "Affective" ///
               inst_mean_std = "Instrumental" ///
               cogn_mean_std = "Cognitive", labsize(small)) ///
    xtitle("Standardized coefficient", size(small)) ///
    legend(order(2 "WTK" 4 "WTP (%)" 6 "WTPn (%)") rows(1) position(6) size(small))

graph export "cp_h1h3_combined.png", replace width(2600)

* --- Individual characteristics (H4) ---

coefplot ///
    (wtk_stand,  mcolor(navy)    msymbol(O) ciopts(lcolor(navy))) ///
    (wtp_stand,  mcolor(maroon)  msymbol(D) ciopts(lcolor(maroon))) ///
    (wtpn_stand, mcolor(dkgreen) msymbol(S) ciopts(lcolor(dkgreen))) ///
    , keep(2.age_yks 3.age_yks 4.age_yks ///
           2.Diet 3.Diet 4.Diet 5.Diet ///
           2.Lookforlabels 3.Lookforlabels 4.Lookforlabels 5.Lookforlabels 6.Lookforlabels 7.Lookforlabels ///
           2.whichrel 3.whichrel 4.whichrel 5.whichrel 6.whichrel 7.whichrel 99.whichrel ///
           2.howrel 3.howrel 4.howrel 5.howrel 6.howrel 7.howrel 99.howrel ///
           yearseducation_std) ///
    xline(0, lcolor(gs8) lpattern(dash)) ///
    coeflabels(2.age_yks = "Age 30-44" 3.age_yks = "Age 45-64" 4.age_yks = "Age 65+" ///
               2.Diet = "Diet: vegetarian" 3.Diet = "Diet: occasional" 4.Diet = "Diet: often" 5.Diet = "Diet: daily meat" ///
               2.Lookforlabels = "Labels: sometimes" 3.Lookforlabels = "Labels: rarely" 4.Lookforlabels = "Labels: never" 5.Lookforlabels = "Labels: unaware" 6.Lookforlabels = "Labels: don't know" 7.Lookforlabels = "Labels: N/A" ///
               2.whichrel = "Judaism" 3.whichrel = "Islam" 4.whichrel = "Hinduism" 5.whichrel = "Buddhism" 6.whichrel = "Other religion" 7.whichrel = "Not religious" 99.whichrel = "Religion: PNS" ///
               2.howrel = "Religiosity 2" 3.howrel = "Religiosity 3" 4.howrel = "Religiosity 4" 5.howrel = "Religiosity 5" 6.howrel = "Religiosity 6" 7.howrel = "Very religious" 99.howrel = "Religiosity: PNS" ///
               yearseducation_std = "Years of education (z)", labsize(vsmall)) ///
    legend(order(2 "WTK" 4 "WTP (%)" 6 "WTPn (%)") rows(1) position(6) size(small)) ///
    xtitle("Coefficient", size(small)) ///
    ysize(12) xsize(8)

graph export "cp_h4.png", replace width(2200)

* =============================================================
* H5: category-specific WTK logits with standardized predictors
* =============================================================
eststo clear
eststo meat:     logit wtk_meat     aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_meat!=2,     vce(ro)
eststo egg:      logit wtk_egg      aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_egg!=2,      vce(ro)
eststo milk:     logit wtk_milk     aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_milk!=2,     vce(ro)
eststo fur:      logit wtk_fur      aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_fur!=2,      vce(ro)
eststo leather:  logit wtk_leather  aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_leather!=2,  vce(ro)
eststo cosmetic: logit wtk_cosmetic aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_cosmetic!=2, vce(ro)
eststo pfood:    logit wtk_pfood    aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_pfood!=2,    vce(ro)
eststo otc:      logit wtk_otc      aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std if wtk_otc!=2,      vce(ro)

coefplot ///
    (meat egg milk fur leather cosmetic pfood otc, keep(aff_mean_std)  mcolor(navy)    msymbol(O) ciopts(lcolor(navy))    label("Affective")) ///
    (meat egg milk fur leather cosmetic pfood otc, keep(inst_mean_std) mcolor(maroon)  msymbol(D) ciopts(lcolor(maroon))  label("Instrumental")) ///
    (meat egg milk fur leather cosmetic pfood otc, keep(cogn_mean_std) mcolor(dkgreen) msymbol(S) ciopts(lcolor(dkgreen)) label("Cognitive")) ///
    , coeflabels(aff_mean_std = " " inst_mean_std = " " cogn_mean_std = " ") ///
    xline(0, lcolor(gs8) lpattern(dash)) ///
    legend(order(2 "Affective" 4 "Instrumental" 6 "Cognitive") rows(1) position(6) size(small)) ///
xtitle("Standardized log-odds coefficient", size(small)) xlabel(-1.5(0.5)1.5) ///
    title("", size(medsmall)) ///
    name(cp_h5, replace)

graph export "cp_h5.png", replace width(2400)

* =============================================================
* H6: country differences (reference: Denmark), standardized average models
* =============================================================
eststo wtk_stand: reg wtk_mean_std aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

eststo wtp_stand: reg wtp_prct_mean_std aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

eststo wtpn_stand: reg wtpn_prct_mean_std aff_mean_std inst_mean_std cogn_mean_std $sociodemo_std $values_std $lifestyle_std $socioeco_std ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

coefplot ///
    (wtk_stand,  keep(2.country 3.country 4.country 5.country 6.country) mcolor(navy)    msymbol(O) ciopts(lcolor(navy))) ///
    (wtp_stand,  keep(2.country 3.country 4.country 5.country 6.country) mcolor(maroon)  msymbol(D) ciopts(lcolor(maroon))) ///
    (wtpn_stand, keep(2.country 3.country 4.country 5.country 6.country) mcolor(dkgreen) msymbol(S) ciopts(lcolor(dkgreen))) ///
    , xline(0, lcolor(gs8) lpattern(dash)) ///
    coeflabels(2.country = "France" 3.country = "Germany" 4.country = "Netherlands" ///
               5.country = "UK" 6.country = "US", labsize(small)) ///
    legend(order(2 "WTK" 4 "WTP (%)" 6 "WTPn (%)") rows(1) position(6) size(small)) ///
    xtitle("Estimated coefficients (ref: Denmark)", size(small)) ///
    title("", size(medsmall)) ///
    name(cp_h6, replace)

graph export "cp_h6.png", replace width(3000)

* =============================================================
* Descriptive statistics by country
* =============================================================

dtable ///
    i.age_yks i.gender i.married ///
    i.whichrel i.howrel bioval ///
    i.Diet i.Pets i.Org i.labelcuriosity i.Lookforlabels ///
    i.Regularcontacts_1 i.Regularcontacts_2 i.Regularcontacts_3 i.Regularcontacts_4 ///
    labelscore i.Currchoice ///
    i.income_quartile i.workfulltime yearseducation ///
    aff_mean inst_mean cogn_mean ///
    i.wtk_meat i.wtk_egg i.wtk_milk i.wtk_fur i.wtk_leather i.wtk_cosmetic i.wtk_pfood i.wtk_otc ///
    wtp_meat_prct wtp_egg_prct wtp_milk_prct wtp_fur_prct wtp_leather_prct wtp_cosmetic_prct wtp_pfood_prct wtp_otc_prct ///
    wtpn_meat_prct wtpn_egg_prct wtpn_milk_prct wtpn_fur_prct wtpn_leather_prct wtpn_cosmetic_prct wtpn_pfood_prct wtpn_otc_prct ///
    , by(country) nolistwise ///
    continuous(, statistics(mean)) ///
    factor(, statistics(fvpercent)) ///
    nformat(%9.3f mean) ///
    nformat(%9.1f fvpercent) ///
    title("Table D. Descriptive statistics by country") ///
    note("Means for continuous variables, column percentages for categorical variables; each variable on its own non-missing base. WTK as three categories (0 = No, 1 = Yes, 2 = Knew). WTP/WTPn as % of price.") ///
    export("Table_D_descriptives.docx", replace)

* =============================================================
* Descriptive figures
* =============================================================

* --- Inter-item correlations of the information-value items ---
correlate aff_1 aff_2 inst_1 inst_2 cogn_1 cogn_2 cogn_3
graph matrix aff_1 aff_2 inst_1 inst_2 cogn_1 cogn_2 cogn_3, ///
    title("Figure D1. Inter-item correlations (information-value items)")
graph export "D1_corr.png", replace width(2600)

* --- Mean recalled price by product, buyers only ---

preserve
tempfile pm
tempname pf
postfile `pf' prod mean lo hi using "`pm'", replace

local p = 1
foreach v in prc_meat prc_egg prc_milk prc_fur prc_leather prc_cosmetic prc_pfood prc_otc {
    quietly summarize `v'
    local m  = r(mean)
    local se = r(sd)/sqrt(r(N))
    post `pf' (`p') (`m') (`m'-1.96*`se') (`m'+1.96*`se')
    local ++p
}
postclose `pf'

use "`pm'", clear
twoway (bar mean prod, barwidth(0.6) color(navy)) ///
       (rcap hi lo prod, lcolor(gs6)), ///
    legend(off) ///
    xlabel(1 "Meat" 2 "Eggs" 3 "Milk" 4 "Fur" 5 "Leather" 6 "Cosmetics" 7 "Pet food" 8 "OTC", noticks) xtitle("Product category")  ///
    ylabel(0(50)200, angle(0)) yscale(range(0 .)) ///
	ytitle("Mean price (euros)") ///
    title("")
graph export "D2_price_product.png", replace width(2600)
restore

* --- WTK responses (no / yes / already knew) by product, with Wald CIs ---
preserve

tempfile props
tempname pf
postfile `pf' prod cat phat lo hi using "`props'", replace

local p = 1
foreach v in wtk_meat wtk_egg wtk_milk wtk_fur wtk_leather wtk_cosmetic wtk_pfood wtk_otc {
    quietly count if !missing(`v')
    local n = r(N)
    forvalues c = 0/2 {
        quietly count if `v'==`c'
        local phat = r(N)/`n'
        local me   = 1.96*sqrt(`phat'*(1-`phat')/`n')
        post `pf' (`p') (`c') (`phat') (`phat'-`me') (`phat'+`me')
    }
    local ++p
}
postclose `pf'

use "`props'", clear

gen xpos = prod + (cat-1)*0.22

twoway ///
    (bar phat xpos if cat==0, barwidth(0.20) color(navy)) ///
    (bar phat xpos if cat==1, barwidth(0.20) color(maroon)) ///
    (bar phat xpos if cat==2, barwidth(0.20) color(dkgreen)) ///
    (rcap hi lo xpos if cat==0, lcolor(gs6)) ///
    (rcap hi lo xpos if cat==1, lcolor(gs6)) ///
    (rcap hi lo xpos if cat==2, lcolor(gs6)) ///
    , legend(order(1 "No" 2 "Yes" 3 "Knew info") rows(1) position(6)) ///
    xlabel(1 "Meat" 2 "Eggs" 3 "Milk" 4 "Fur" 5 "Leather" 6 "Cosmetics" 7 "Pet food" 8 "OTC", noticks) xtitle("Product category")  ///
    ylabel(0(0.2)1) ytitle("Proportion")  ///
    title("")

graph export "wtk_categories.png", replace width(3000)

restore

* --- WTP by product (% of price) ---
preserve
tempfile pm
tempname pf
postfile `pf' prod mean lo hi using "`pm'", replace

local p = 1
foreach v in wtp_meat_prct wtp_egg_prct wtp_milk_prct wtp_fur_prct wtp_leather_prct wtp_cosmetic_prct wtp_pfood_prct wtp_otc_prct {
    quietly summarize `v'
    local m  = r(mean)
    local se = r(sd)/sqrt(r(N))
    post `pf' (`p') (`m') (`m'-1.96*`se') (`m'+1.96*`se')
    local ++p
}
postclose `pf'

use "`pm'", clear
twoway (bar mean prod, barwidth(0.6) color(navy)) ///
       (rcap hi lo prod, lcolor(gs6)), ///
    legend(off) ///
    xlabel(1 "Meat" 2 "Eggs" 3 "Milk" 4 "Fur" 5 "Leather" 6 "Cosmetics" 7 "Pet food" 8 "OTC", noticks) xtitle("Product category") ylabel(0(5)25, angle(0))  ///
    ytitle("WTP (% of price)") ///
    title("")
graph export "D4_wtp_product.png", replace width(2600)

restore

* --- WTP by product (euros) ---
preserve
tempfile pm
tempname pf
postfile `pf' prod mean lo hi using "`pm'", replace

local p = 1
foreach v in wtp_meat wtp_egg wtp_milk wtp_fur wtp_leather wtp_cosmetic wtp_pfood wtp_otc {
    quietly summarize `v'
    local m  = r(mean)
    local se = r(sd)/sqrt(r(N))
    post `pf' (`p') (`m') (`m'-1.96*`se') (`m'+1.96*`se')
    local ++p
}
postclose `pf'

use "`pm'", clear
twoway (bar mean prod, barwidth(0.6) color(navy)) ///
       (rcap hi lo prod, lcolor(gs6)), ///
    legend(off) ///
    xlabel(1 "Meat" 2 "Eggs" 3 "Milk" 4 "Fur" 5 "Leather" 6 "Cosmetics" 7 "Pet food" 8 "OTC", noticks) xtitle("Product category") ylabel(0(5)25, angle(0))  ///
    ytitle("WTP (% of price)") ///
    title("")
graph export "D4_wtp_product_absolute.png", replace width(2600)

restore

* --- WTPn by product (% of price) ---
preserve
tempfile pm
tempname pf
postfile `pf' prod mean lo hi using "`pm'", replace

local p = 1
foreach v in wtpn_meat_prct wtpn_egg_prct wtpn_milk_prct wtpn_fur_prct wtpn_leather_prct wtpn_cosmetic_prct wtpn_pfood_prct wtpn_otc_prct {
    quietly summarize `v'
    local m  = r(mean)
    local se = r(sd)/sqrt(r(N))
    post `pf' (`p') (`m') (`m'-1.96*`se') (`m'+1.96*`se')
    local ++p
}
postclose `pf'

use "`pm'", clear
twoway (bar mean prod, barwidth(0.6) color(navy)) ///
       (rcap hi lo prod, lcolor(gs6)), ///
    legend(off) ///
    xlabel(1 "Meat" 2 "Eggs" 3 "Milk" 4 "Fur" 5 "Leather" 6 "Cosmetics" 7 "Pet food" 8 "OTC", noticks) xtitle("Product category") ylabel(0(5)15, angle(0))  ///
    ytitle("WTPn (% of price)") ///
    title("")
graph export "D5_wtpn_product.png", replace width(2600)
restore

* --- WTP by country (% of price) ---
cibar wtp_prct_mean, over(country) ///
    bargap(20) barcolor(navy) ciopts(lcolor(gs6)) ///
    graphopts( ///
        ytitle("WTP (% of price)") ///
        ylabel(0(5)25, angle(0)) ///
        title("Figure D8. Willingness to pay, by country") ///
    )
graph export "D8_wtp_country.png", replace width(2600)

* --- WTPn by country (% of price) ---
cibar wtpn_prct_mean, over(country) ///
    bargap(20) barcolor(navy) ciopts(lcolor(gs6)) ///
    graphopts( ///
        ytitle("WTPn (% of price)") ///
        ylabel(0(5)15, angle(0)) ///
        title("Figure D9. Willingness to pay to avoid, by country") ///
    )
graph export "D9_wtpn_country.png", replace width(2600)

* =============================================================
* Welfare effects: inputs for the welfare calculation
*   welfare_inputs_country_category.csv   shares, WTP/WTPn in euros, prices
*   welfare_inputs_bootstrap.csv          bootstrap draws of the same inputs
*   predictions_values_*.csv              predicted WTK/WTP/WTPn over the value grid
* =============================================================

cd "$welfare"

* --- (1) Average predictions of the three index models ---
putexcel set "welfare_margins.xlsx", sheet("overall") modify

eststo wtkmean: reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)
margins
matrix M_wtk = r(table)'
putexcel A1 = "WTK"  A2 = matrix(M_wtk), names

eststo wtp_prct_index: reg wtp_prct_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)
margins
matrix M_wtp = r(table)'
putexcel A5 = "WTP (%)" A6 = matrix(M_wtp), names

eststo wtpn_prct_index: reg wtpn_prct_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)
margins
matrix M_wtpn = r(table)'
putexcel A9 = "WTPn (%)" A10 = matrix(M_wtpn), names

* --- (2) Welfare inputs by country x category ---
preserve

* --- harmonise names so reshape finds the stubs --------------
rename wtp_meat_prct      wtppct_meat
rename wtp_egg_prct       wtppct_egg
rename wtp_milk_prct      wtppct_milk
rename wtp_fur_prct       wtppct_fur
rename wtp_leather_prct   wtppct_leather
rename wtp_cosmetic_prct  wtppct_cosmetic
rename wtp_pfood_prct     wtppct_pfood
rename wtp_otc_prct       wtppct_otc

rename wtpn_meat_prct     wtpnpct_meat
rename wtpn_egg_prct      wtpnpct_egg
rename wtpn_milk_prct     wtpnpct_milk
rename wtpn_fur_prct      wtpnpct_fur
rename wtpn_leather_prct  wtpnpct_leather
rename wtpn_cosmetic_prct wtpnpct_cosmetic
rename wtpn_pfood_prct    wtpnpct_pfood
rename wtpn_otc_prct      wtpnpct_otc

rename wtk_meat     wtkc_meat
rename wtk_egg      wtkc_egg
rename wtk_milk     wtkc_milk
rename wtk_fur      wtkc_fur
rename wtk_leather  wtkc_leather
rename wtk_cosmetic wtkc_cosmetic
rename wtk_pfood    wtkc_pfood
rename wtk_otc      wtkc_otc

gen long _id = _n
keep _id country wtkc_* wtppct_* wtpnpct_* prc_*

reshape long wtkc_ wtppct_ wtpnpct_ prc_, i(_id) j(product) string
rename (wtkc_ wtppct_ wtpnpct_ prc_) (wtk wtppct wtpnpct prc)

* buyer   : recalled price > 0
* knew    : buyer & wtk == 2 (already informed)
* decider : buyer & wtk in (0,1)
* want    : decider & wtk == 1;  avoid : decider & wtk == 0
* Each indicator is missing outside its parent group, so the collapse returns conditional shares.
gen byte buyer   = (prc > 0 & !missing(prc))
gen byte knew    = (wtk == 2)             if buyer   == 1
gen byte decider = inlist(wtk, 0, 1)      if buyer   == 1
gen byte want    = (wtk == 1)             if decider == 1
gen byte avoid   = (wtk == 0)             if decider == 1

* --- individual-level euro valuations ------------------------
gen double wtp_eur  = (wtppct  / 100) * prc if want  == 1
gen double wtpn_eur = (wtpnpct / 100) * prc if avoid == 1

* --- collapse to country x category --------------------------
collapse (mean) consuming_share  = buyer     ///  share of adults buying p
         (mean) knew_share       = knew      ///  share of buyers already informed
         (mean) decider_share_b  = decider   ///  = 1 - knew_share
         (mean) pi_plus          = want      ///  P(want | decider)
         (mean) pi_minus         = avoid     ///  = 1 - pi_plus
         (mean) mu_plus          = wtp_eur   ///  mean WTP  (EUR) among wanters
         (mean) mu_minus         = wtpn_eur  ///  mean WTPn (EUR) among avoiders
         (mean) price_mean       = prc       ///  buyers-only mean recalled price
         (mean) wtppct_mean      = wtppct    ///
         (mean) wtpnpct_mean     = wtpnpct   ///
         (sum)  n_buyer          = buyer     ///
         (sum)  n_decider        = decider   ///
         (count) n_want          = wtp_eur   ///
         (count) n_avoid         = wtpn_eur  ///
         , by(country product)

* --- N_pk scaling factor: share of ADULTS who face the disclosure
gen double decider_share_pop = consuming_share * decider_share_b

* --- sanity checks -------------------------------------------
assert abs(pi_plus + pi_minus - 1) < 1e-6
assert abs(knew_share + decider_share_b - 1) < 1e-6

label var consuming_share    "share of adults buying category p"
label var knew_share         "share of buyers already informed"
label var decider_share_pop  "share of adults facing the disclosure = N_pk / adult pop"
label var pi_plus            "P(want info | decider)"
label var pi_minus           "P(avoid info | decider) = 1 - pi_plus"
label var mu_plus            "mean WTP  in EUR among wanters"
label var mu_minus           "mean WTPn in EUR among avoiders"
label var price_mean         "mean recalled price in EUR, buyers only"

order country product n_buyer n_decider n_want n_avoid       ///
      consuming_share knew_share decider_share_b decider_share_pop ///
      pi_plus pi_minus mu_plus mu_minus                      ///
      price_mean wtppct_mean wtpnpct_mean
sort country product

export delimited using "welfare_inputs_country_category.csv", replace
export excel using "welfare_margins.xlsx", sheet("welfare_inputs") ///
    sheetmodify firstrow(variables)

restore

* --- (2b) Bootstrap of the welfare inputs: respondents resampled within country ---
preserve

* --- same preparation as in (2), done once ---
foreach p in meat egg milk fur leather cosmetic pfood otc {
    rename wtp_`p'_prct  wtppct_`p'
    rename wtpn_`p'_prct wtpnpct_`p'
    rename wtk_`p'       wtkc_`p'
}
gen long _id = _n
keep _id country wtkc_* wtppct_* wtpnpct_* prc_*
reshape long wtkc_ wtppct_ wtpnpct_ prc_, i(_id) j(product) string
rename (wtkc_ wtppct_ wtpnpct_ prc_) (wtk wtppct wtpnpct prc)

gen byte buyer   = (prc > 0 & !missing(prc))
gen byte decider = inlist(wtk, 0, 1)      if buyer   == 1
gen byte want    = (wtk == 1)             if decider == 1
gen double wtp_eur  = (wtppct  / 100) * prc if want == 1
gen double wtpn_eur = (wtpnpct / 100) * prc if want == 0

keep _id country product buyer decider want wtp_eur wtpn_eur
tempfile base boot
save `base'

* --- bootstrap loop ---
local B = 1000
set seed 20261110
forvalues b = 1/`B' {
    use `base', clear
    bsample, strata(country) cluster(_id)      // whole respondents, within country
    collapse (mean) consuming_share = buyer   ///
             (mean) decider_share_b = decider ///
             (mean) pi_plus         = want    ///
             (mean) mu_plus         = wtp_eur ///
             (mean) mu_minus        = wtpn_eur ///
             , by(country product)
    gen double decider_share_pop = consuming_share * decider_share_b
    gen double pi_minus          = 1 - pi_plus
    gen int draw = `b'
    if `b' > 1 append using `boot'
    save `boot', replace
}

sort draw country product
export delimited using "welfare_inputs_bootstrap.csv", replace
restore

* --- (3) Predictions over the 7x7x7 value grid, pooled and by country ---
reg wtk_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)
margins, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtk_all.dta", replace)
margins country, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtk_cty.dta", replace)

reg wtp_prct_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)
margins, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtp_all.dta", replace)
margins country, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtp_cty.dta", replace)

reg wtpn_prct_mean aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)
margins, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtpn_all.dta", replace)
margins country, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtpn_cty.dta", replace)

* --- merge: pooled grid (343 rows) ---------------------------
preserve
use "grid_wtk_all.dta", clear
keep _at1 _at2 _at3 _margin
rename (_at1 _at2 _at3 _margin) (aff inst cogn pred_wtk)
tempfile g_all
save `g_all'

use "grid_wtp_all.dta", clear
keep _at1 _at2 _at3 _margin
rename (_at1 _at2 _at3 _margin) (aff inst cogn pred_wtp)
merge 1:1 aff inst cogn using `g_all', nogen
save `g_all', replace

use "grid_wtpn_all.dta", clear
keep _at1 _at2 _at3 _margin
rename (_at1 _at2 _at3 _margin) (aff inst cogn pred_wtpn)
merge 1:1 aff inst cogn using `g_all', nogen

order aff inst cogn pred_wtk pred_wtp pred_wtpn
sort aff inst cogn
count   // must be 343

save "predictions_values_all.dta", replace
export delimited using "predictions_values_all.csv", replace
export excel using "welfare_margins.xlsx", sheet("value_grid_all") ///
    sheetmodify firstrow(variables)

* --- (4) Value grid by country (6 x 343 rows) ---
use "grid_wtk_cty.dta", clear
keep _m1 _at1 _at2 _at3 _margin
rename (_m1 _at1 _at2 _at3 _margin) (country aff inst cogn pred_wtk)
tempfile g_cty
save `g_cty'

use "grid_wtp_cty.dta", clear
keep _m1 _at1 _at2 _at3 _margin
rename (_m1 _at1 _at2 _at3 _margin) (country aff inst cogn pred_wtp)
merge 1:1 country aff inst cogn using `g_cty', nogen
save `g_cty', replace

use "grid_wtpn_cty.dta", clear
keep _m1 _at1 _at2 _at3 _margin
rename (_m1 _at1 _at2 _at3 _margin) (country aff inst cogn pred_wtpn)
merge 1:1 country aff inst cogn using `g_cty', nogen

order country aff inst cogn pred_wtk pred_wtp pred_wtpn
sort country aff inst cogn
count   // must be 2058

save "predictions_values_country.dta", replace
export delimited using "predictions_values_country.csv", replace
export excel using "welfare_margins.xlsx", sheet("value_grid_country") ///
    sheetmodify firstrow(variables)

restore

* --- (5) Value grids by product category ---
foreach p in meat egg milk fur leather cosmetic pfood otc {

    logit wtk_`p' aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco ///
        if wtk_`p' != 2, vce(ro)
    margins, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtk_`p'.dta", replace)

    reg wtp_`p'_prct aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
    margins, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtp_`p'.dta", replace)

    reg wtpn_`p'_prct aff_mean inst_mean cogn_mean $sociodemo $values $lifestyle $socioeco, vce(ro)
    margins, at(aff_mean=(1(1)7) inst_mean=(1(1)7) cogn_mean=(1(1)7)) saving("grid_wtpn_`p'.dta", replace)
}

* --- merge to one long file: 8 x 343 = 2,744 rows ------------
preserve
tempfile grids
local first = 1

foreach p in meat egg milk fur leather cosmetic pfood otc {

    use "grid_wtk_`p'.dta", clear
    keep _at1 _at2 _at3 _margin
    rename (_at1 _at2 _at3 _margin) (aff inst cogn pred_wtk)
    tempfile g_`p'
    save `g_`p''

    use "grid_wtp_`p'.dta", clear
    keep _at1 _at2 _at3 _margin
    rename (_at1 _at2 _at3 _margin) (aff inst cogn pred_wtp)
    merge 1:1 aff inst cogn using `g_`p'', nogen
    save `g_`p'', replace

    use "grid_wtpn_`p'.dta", clear
    keep _at1 _at2 _at3 _margin
    rename (_at1 _at2 _at3 _margin) (aff inst cogn pred_wtpn)
    merge 1:1 aff inst cogn using `g_`p'', nogen

    gen product = "`p'"
    order product aff inst cogn pred_wtk pred_wtp pred_wtpn
    sort aff inst cogn
    count   // must be 343

    if `first' == 1 {
        save `grids', replace
        local first = 0
    }
    else {
        append using `grids'
        save `grids', replace
    }
}

use `grids', clear
sort product aff inst cogn
count   // must be 2744

save "predictions_values_product.dta", replace
export delimited using "predictions_values_product.csv", replace
export excel using "welfare_margins.xlsx", sheet("value_grid_product") ///
    sheetmodify firstrow(variables)
restore

cd "$out"

* =============================================================
* High negative affect (aff_mean > 4): wanting vs. avoiding information, by category
*   1 want & WTP>0    2 want & WTP=0    3 avoid & WTPn>0    4 avoid & WTPn=0
* =============================================================

cap drop grp_*
label define grp 1 "Want & WTP>0" 2 "Want & WTP=0" 3 "Avoid & WTPn>0" 4 "Avoid & WTPn=0", replace

gen grp_meat = .
replace grp_meat = 1 if aff_mean>4 & !missing(aff_mean) & wtk_meat==1 & wtp_meat>0  & !missing(wtp_meat)
replace grp_meat = 2 if aff_mean>4 & !missing(aff_mean) & wtk_meat==1 & wtp_meat==0
replace grp_meat = 3 if aff_mean>4 & !missing(aff_mean) & wtk_meat==0 & wtpn_meat>0 & !missing(wtpn_meat)
replace grp_meat = 4 if aff_mean>4 & !missing(aff_mean) & wtk_meat==0 & wtpn_meat==0
label values grp_meat grp

gen grp_egg = .
replace grp_egg = 1 if aff_mean>4 & !missing(aff_mean) & wtk_egg==1 & wtp_egg>0  & !missing(wtp_egg)
replace grp_egg = 2 if aff_mean>4 & !missing(aff_mean) & wtk_egg==1 & wtp_egg==0
replace grp_egg = 3 if aff_mean>4 & !missing(aff_mean) & wtk_egg==0 & wtpn_egg>0 & !missing(wtpn_egg)
replace grp_egg = 4 if aff_mean>4 & !missing(aff_mean) & wtk_egg==0 & wtpn_egg==0
label values grp_egg grp

gen grp_milk = .
replace grp_milk = 1 if aff_mean>4 & !missing(aff_mean) & wtk_milk==1 & wtp_milk>0  & !missing(wtp_milk)
replace grp_milk = 2 if aff_mean>4 & !missing(aff_mean) & wtk_milk==1 & wtp_milk==0
replace grp_milk = 3 if aff_mean>4 & !missing(aff_mean) & wtk_milk==0 & wtpn_milk>0 & !missing(wtpn_milk)
replace grp_milk = 4 if aff_mean>4 & !missing(aff_mean) & wtk_milk==0 & wtpn_milk==0
label values grp_milk grp

gen grp_fur = .
replace grp_fur = 1 if aff_mean>4 & !missing(aff_mean) & wtk_fur==1 & wtp_fur>0  & !missing(wtp_fur)
replace grp_fur = 2 if aff_mean>4 & !missing(aff_mean) & wtk_fur==1 & wtp_fur==0
replace grp_fur = 3 if aff_mean>4 & !missing(aff_mean) & wtk_fur==0 & wtpn_fur>0 & !missing(wtpn_fur)
replace grp_fur = 4 if aff_mean>4 & !missing(aff_mean) & wtk_fur==0 & wtpn_fur==0
label values grp_fur grp

gen grp_leather = .
replace grp_leather = 1 if aff_mean>4 & !missing(aff_mean) & wtk_leather==1 & wtp_leather>0  & !missing(wtp_leather)
replace grp_leather = 2 if aff_mean>4 & !missing(aff_mean) & wtk_leather==1 & wtp_leather==0
replace grp_leather = 3 if aff_mean>4 & !missing(aff_mean) & wtk_leather==0 & wtpn_leather>0 & !missing(wtpn_leather)
replace grp_leather = 4 if aff_mean>4 & !missing(aff_mean) & wtk_leather==0 & wtpn_leather==0
label values grp_leather grp

gen grp_cosmetic = .
replace grp_cosmetic = 1 if aff_mean>4 & !missing(aff_mean) & wtk_cosmetic==1 & wtp_cosmetic>0  & !missing(wtp_cosmetic)
replace grp_cosmetic = 2 if aff_mean>4 & !missing(aff_mean) & wtk_cosmetic==1 & wtp_cosmetic==0
replace grp_cosmetic = 3 if aff_mean>4 & !missing(aff_mean) & wtk_cosmetic==0 & wtpn_cosmetic>0 & !missing(wtpn_cosmetic)
replace grp_cosmetic = 4 if aff_mean>4 & !missing(aff_mean) & wtk_cosmetic==0 & wtpn_cosmetic==0
label values grp_cosmetic grp

gen grp_pfood = .
replace grp_pfood = 1 if aff_mean>4 & !missing(aff_mean) & wtk_pfood==1 & wtp_pfood>0  & !missing(wtp_pfood)
replace grp_pfood = 2 if aff_mean>4 & !missing(aff_mean) & wtk_pfood==1 & wtp_pfood==0
replace grp_pfood = 3 if aff_mean>4 & !missing(aff_mean) & wtk_pfood==0 & wtpn_pfood>0 & !missing(wtpn_pfood)
replace grp_pfood = 4 if aff_mean>4 & !missing(aff_mean) & wtk_pfood==0 & wtpn_pfood==0
label values grp_pfood grp

gen grp_otc = .
replace grp_otc = 1 if aff_mean>4 & !missing(aff_mean) & wtk_otc==1 & wtp_otc>0  & !missing(wtp_otc)
replace grp_otc = 2 if aff_mean>4 & !missing(aff_mean) & wtk_otc==1 & wtp_otc==0
replace grp_otc = 3 if aff_mean>4 & !missing(aff_mean) & wtk_otc==0 & wtpn_otc>0 & !missing(wtpn_otc)
replace grp_otc = 4 if aff_mean>4 & !missing(aff_mean) & wtk_otc==0 & wtpn_otc==0
label values grp_otc grp

* --- group counts by category ---
preserve

label define prodlab 1 "Meat" 2 "Eggs" 3 "Milk" 4 "Fur" 5 "Leather" 6 "Cosmetics" 7 "Pet food" 8 "OTC"

tempfile grptab
tempname pf
postfile `pf' prod want_pay want_nopay avoid_pay avoid_nopay n_dec pct_want_pay pct_avoid_pay g1_gt_g3 ///
    using "`grptab'", replace

local i = 0
foreach p in meat egg milk fur leather cosmetic pfood otc {
    local ++i
    quietly count if grp_`p'==1
    local n1 = r(N)
    quietly count if grp_`p'==2
    local n2 = r(N)
    quietly count if grp_`p'==3
    local n3 = r(N)
    quietly count if grp_`p'==4
    local n4 = r(N)
    local tot  = `n1' + `n2' + `n3' + `n4'
    local p1   = cond(`tot'>0, 100*`n1'/`tot', .)
    local p3   = cond(`tot'>0, 100*`n3'/`tot', .)
    local flag = (`n1' > `n3')
    post `pf' (`i') (`n1') (`n2') (`n3') (`n4') (`tot') (`p1') (`p3') (`flag')
}
postclose `pf'

use "`grptab'", clear
label values prod prodlab
format pct_want_pay pct_avoid_pay %5.1f

list prod want_pay want_nopay avoid_pay avoid_nopay n_dec pct_want_pay pct_avoid_pay g1_gt_g3, ///
    noobs sep(0) abbrev(14)

quietly count if g1_gt_g3==1
di as txt _n "Categories where 'want & pay' > 'avoid & pay-to-avoid': " as res r(N) as txt " of 8"

export excel using "affect_direction_groups.xlsx", firstrow(variables) replace

restore

* =============================================================
* Interactions: affective group (low: aff_mean<=3, high: aff_mean>=5)
* with instrumental and cognitive value
* =============================================================

* --- affect group (binary) ---
gen aff_grp2 = .
replace aff_grp2 = 0 if aff_mean<=3 & !missing(aff_mean)
replace aff_grp2 = 1 if aff_mean>=5 & !missing(aff_mean)
label define aff_grp2 0 "Low affect" 1 "High affect"
label values aff_grp2 aff_grp2

* --- WTK ---
eststo clear
eststo wtk_c: reg wtk_mean c.cogn_mean##i.aff_grp2 inst_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

eststo wtk_i: reg wtk_mean c.inst_mean##i.aff_grp2 cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

eststo wtk_b: reg wtk_mean c.cogn_mean##i.aff_grp2 c.inst_mean##i.aff_grp2 $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)

* --- WTP (% of price) ---
eststo wtp_c: reg wtp_prct_mean c.cogn_mean##i.aff_grp2 inst_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

eststo wtp_i: reg wtp_prct_mean c.inst_mean##i.aff_grp2 cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

eststo wtp_b: reg wtp_prct_mean c.cogn_mean##i.aff_grp2 c.inst_mean##i.aff_grp2 $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)

* --- WTPn (% of price) ---
eststo wtpn_c: reg wtpn_prct_mean c.cogn_mean##i.aff_grp2 inst_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

eststo wtpn_i: reg wtpn_prct_mean c.inst_mean##i.aff_grp2 cogn_mean $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

eststo wtpn_b: reg wtpn_prct_mean c.cogn_mean##i.aff_grp2 c.inst_mean##i.aff_grp2 $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)

esttab wtk_c wtk_i wtk_b wtp_c wtp_i wtp_b wtpn_c wtpn_i wtpn_b using "interactions_results.rtf", replace ///
    keep(cogn_mean inst_mean 1.aff_grp2 ///
         1.aff_grp2#c.cogn_mean 1.aff_grp2#c.inst_mean) ///
    mtitles("WTK a×c" "WTK a×i" "WTK both" "WTP a×c" "WTP a×i" "WTP both" "WTPn a×c" "WTPn a×i" "WTPn both") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-sq.")) ///
    label nonumbers ///
    title("Affective group (low vs high) interactions with instrumental and cognitive value")

* --- Predicted outcomes over cognitive / instrumental value, by affect group ---

* --- WTK x cognitive ---
est restore wtk_c
margins aff_grp2, at(cogn_mean=(1(1)7))
marginsplot, ///
    plot1opts(lcolor(navy) mcolor(navy)) plot2opts(lcolor(maroon) mcolor(maroon)) ///
    ci1opts(lcolor(navy)) ci2opts(lcolor(maroon)) ///
    ytitle("Predicted WTK") xtitle("Cognitive value") ///
    legend(order(1 "Low affect" 2 "High affect") rows(1) position(6)) title("")
graph export "int_wtk_cogn.png", replace width(2600)

* --- WTK x instrumental ---
est restore wtk_i
margins aff_grp2, at(inst_mean=(1(1)7))
marginsplot, ///
    plot1opts(lcolor(navy) mcolor(navy)) plot2opts(lcolor(maroon) mcolor(maroon)) ///
    ci1opts(lcolor(navy)) ci2opts(lcolor(maroon)) ///
    ytitle("Predicted WTK") xtitle("Instrumental value") ///
    legend(order(1 "Low affect" 2 "High affect") rows(1) position(6)) title("")
graph export "int_wtk_inst.png", replace width(2600)

* --- WTP x cognitive ---
est restore wtp_c
margins aff_grp2, at(cogn_mean=(1(1)7))
marginsplot, ///
    plot1opts(lcolor(navy) mcolor(navy)) plot2opts(lcolor(maroon) mcolor(maroon)) ///
    ci1opts(lcolor(navy)) ci2opts(lcolor(maroon)) ///
    ytitle("Predicted WTP (% of price)") xtitle("Cognitive value") ///
    legend(order(1 "Low affect" 2 "High affect") rows(1) position(6)) title("")
graph export "int_wtp_cogn.png", replace width(2600)

* --- WTP x instrumental ---
est restore wtp_i
margins aff_grp2, at(inst_mean=(1(1)7))
marginsplot, ///
    plot1opts(lcolor(navy) mcolor(navy)) plot2opts(lcolor(maroon) mcolor(maroon)) ///
    ci1opts(lcolor(navy)) ci2opts(lcolor(maroon)) ///
    ytitle("Predicted WTP (% of price)") xtitle("Instrumental value") ///
    legend(order(1 "Low affect" 2 "High affect") rows(1) position(6)) title("")
graph export "int_wtp_inst.png", replace width(2600)

* --- WTPn x cognitive ---
est restore wtpn_c
margins aff_grp2, at(cogn_mean=(1(1)7))
marginsplot, ///
    plot1opts(lcolor(navy) mcolor(navy)) plot2opts(lcolor(maroon) mcolor(maroon)) ///
    ci1opts(lcolor(navy)) ci2opts(lcolor(maroon)) ///
    ytitle("Predicted WTPn (% of price)") xtitle("Cognitive value") ///
    legend(order(1 "Low affect" 2 "High affect") rows(1) position(6)) title("")
graph export "int_wtpn_cogn.png", replace width(2600)

* --- WTPn x instrumental ---
est restore wtpn_i
margins aff_grp2, at(inst_mean=(1(1)7))
marginsplot, ///
    plot1opts(lcolor(navy) mcolor(navy)) plot2opts(lcolor(maroon) mcolor(maroon)) ///
    ci1opts(lcolor(navy)) ci2opts(lcolor(maroon)) ///
    ytitle("Predicted WTPn (% of price)") xtitle("Instrumental value") ///
    legend(order(1 "Low affect" 2 "High affect") rows(1) position(6)) title("")
graph export "int_wtpn_inst.png", replace width(2600)

* =============================================================
* Additivity of the value components: centred pairwise interactions, joint Wald test
* =============================================================

foreach v in aff inst cogn {
    capture drop `v'_c
    quietly summarize `v'_mean
    gen `v'_c = `v'_mean - r(mean)          // centred: main effects at the sample mean
}
label var aff_c  "Affective value"
label var inst_c "Instrumental value"
label var cogn_c "Cognitive value"

local main c.aff_c c.inst_c c.cogn_c
local ix   c.aff_c#c.inst_c c.aff_c#c.cogn_c c.inst_c#c.cogn_c

eststo clear
eststo r35_wtk: reg wtk_mean `main' `ix' $sociodemo $values $lifestyle $socioeco ///
    i.elig_meat i.elig_egg i.elig_milk i.elig_fur i.elig_leather i.elig_cosmetic i.elig_pfood i.elig_otc, vce(ro)
testparm `ix'
estadd scalar F_int = r(F)
estadd scalar p_int = r(p)

eststo r35_wtp: reg wtp_prct_mean `main' `ix' $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtp_meat i.elig_wtp_egg i.elig_wtp_milk i.elig_wtp_fur i.elig_wtp_leather i.elig_wtp_cosmetic i.elig_wtp_pfood i.elig_wtp_otc, vce(ro)
testparm `ix'
estadd scalar F_int = r(F)
estadd scalar p_int = r(p)

eststo r35_wtpn: reg wtpn_prct_mean `main' `ix' $sociodemo $values $lifestyle $socioeco ///
    i.elig_wtpn_meat i.elig_wtpn_egg i.elig_wtpn_milk i.elig_wtpn_fur i.elig_wtpn_leather i.elig_wtpn_cosmetic i.elig_wtpn_pfood i.elig_wtpn_otc, vce(ro)
testparm `ix'
estadd scalar F_int = r(F)
estadd scalar p_int = r(p)

esttab r35_wtk r35_wtp r35_wtpn using "R3_5_interactions.rtf", replace ///
    keep(aff_c inst_c cogn_c c.aff_c#c.inst_c c.aff_c#c.cogn_c c.inst_c#c.cogn_c) ///
    mtitles("WTK average" "WTP average (%)" "WTPn average (%)") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) interaction(" × ") ///
    stats(F_int p_int N r2, fmt(2 3 0 3) ///
          labels("Joint test of interactions (F)" "p-value" "Observations" "R-sq.")) ///
    label nonumbers ///
    title("Test of additivity: pairwise interactions of the information-value components")

* =============================================================
* Mean value components by WTK / WTP / WTPn group (raw means, fixed cutoffs)
* =============================================================

capture drop wtk_ter wtp_ter wtpn_ter

* WTK average: <=0.25 low, 0.25-0.625 mid, >0.625 high
gen wtk_ter = .
replace wtk_ter = 1 if wtk_mean<=2/8                & !missing(wtk_mean)
replace wtk_ter = 2 if wtk_mean>2/8 & wtk_mean<=5/8 & !missing(wtk_mean)
replace wtk_ter = 3 if wtk_mean>5/8                 & !missing(wtk_mean)

* WTP (% of price): 0-33 low, 34-66 mid, >66 high
gen wtp_ter = .
replace wtp_ter = 1 if wtp_prct_mean<=33                        & !missing(wtp_prct_mean)
replace wtp_ter = 2 if wtp_prct_mean>33  & wtp_prct_mean<=66    & !missing(wtp_prct_mean)
replace wtp_ter = 3 if wtp_prct_mean>66                         & !missing(wtp_prct_mean)

* WTPn (% of price): same cutoffs
gen wtpn_ter = .
replace wtpn_ter = 1 if wtpn_prct_mean<=33                       & !missing(wtpn_prct_mean)
replace wtpn_ter = 2 if wtpn_prct_mean>33 & wtpn_prct_mean<=66   & !missing(wtpn_prct_mean)
replace wtpn_ter = 3 if wtpn_prct_mean>66                        & !missing(wtpn_prct_mean)

tab wtk_ter
tab wtp_ter
tab wtpn_ter

* ---------- WTK ----------
preserve
collapse (mean) m_inst=inst_mean (semean) se_inst=inst_mean ///
         (mean) m_cogn=cogn_mean (semean) se_cogn=cogn_mean ///
         (mean) m_aff=aff_mean   (semean) se_aff=aff_mean   ///
         if !missing(wtk_ter), by(wtk_ter)

gen id=_n
reshape long m_ se_, i(id) j(chan) string
drop id
gen cha = 1 if chan=="inst"
replace cha = 2 if chan=="cogn"
replace cha = 3 if chan=="aff"
gen xpos = cha + (wtk_ter-2)*0.25
gen lo = m_ - 1.96*se_
gen hi = m_ + 1.96*se_

twoway ///
    (bar m_ xpos if wtk_ter==1, barwidth(0.22) color(navy)) ///
    (bar m_ xpos if wtk_ter==2, barwidth(0.22) color(maroon)) ///
    (bar m_ xpos if wtk_ter==3, barwidth(0.22) color(dkgreen)) ///
    (rcap hi lo xpos, lcolor(gs6)) ///
    , legend(order(1 "Low WTK" 2 "Mid WTK" 3 "High WTK") rows(1) position(6)) ///
    xlabel(1 "Instrumental" 2 "Cognitive" 3 "Affective", noticks) ///
    xtitle("") ytitle("Mean value (1-7)") title("")
graph export "cond_wtk.png", replace width(2600)
restore

* ---------- WTP ----------
preserve
collapse (mean) m_inst=inst_mean (semean) se_inst=inst_mean ///
         (mean) m_cogn=cogn_mean (semean) se_cogn=cogn_mean ///
         (mean) m_aff=aff_mean   (semean) se_aff=aff_mean   ///
         if !missing(wtp_ter), by(wtp_ter)
gen id=_n
reshape long m_ se_, i(id) j(chan) string
drop id
gen cha = 1 if chan=="inst"
replace cha = 2 if chan=="cogn"
replace cha = 3 if chan=="aff"
gen xpos = cha + (wtp_ter-2)*0.25
gen lo = m_ - 1.96*se_
gen hi = m_ + 1.96*se_

twoway ///
    (bar m_ xpos if wtp_ter==1, barwidth(0.22) color(navy)) ///
    (bar m_ xpos if wtp_ter==2, barwidth(0.22) color(maroon)) ///
    (bar m_ xpos if wtp_ter==3, barwidth(0.22) color(dkgreen)) ///
    (rcap hi lo xpos, lcolor(gs6)) ///
    , legend(order(1 "Low WTP" 2 "Mid WTP" 3 "High WTP") rows(1) position(6)) ///
    xlabel(1 "Instrumental" 2 "Cognitive" 3 "Affective", noticks) ///
    xtitle("") ytitle("Mean value (1-7)") title("")
graph export "cond_wtp.png", replace width(2600)
restore

* ---------- WTPn ----------
preserve
collapse (mean) m_inst=inst_mean (semean) se_inst=inst_mean ///
         (mean) m_cogn=cogn_mean (semean) se_cogn=cogn_mean ///
         (mean) m_aff=aff_mean   (semean) se_aff=aff_mean   ///
         if !missing(wtpn_ter), by(wtpn_ter)
gen id=_n
reshape long m_ se_, i(id) j(chan) string
drop id
gen cha = 1 if chan=="inst"
replace cha = 2 if chan=="cogn"
replace cha = 3 if chan=="aff"
gen xpos = cha + (wtpn_ter-2)*0.25
gen lo = m_ - 1.96*se_
gen hi = m_ + 1.96*se_

twoway ///
    (bar m_ xpos if wtpn_ter==1, barwidth(0.22) color(navy)) ///
    (bar m_ xpos if wtpn_ter==2, barwidth(0.22) color(maroon)) ///
    (bar m_ xpos if wtpn_ter==3, barwidth(0.22) color(dkgreen)) ///
    (rcap hi lo xpos, lcolor(gs6)) ///
    , legend(order(1 "Low WTPn" 2 "Mid WTPn" 3 "High WTPn") rows(1) position(6)) ///
    xlabel(1 "Instrumental" 2 "Cognitive" 3 "Affective", noticks) ///
    xtitle("") ytitle("Mean value (1-7)") title("")
graph export "cond_wtpn.png", replace width(2600)
restore

* --- same numbers to Excel, one sheet per outcome ---
foreach o in wtk wtp wtpn {
    preserve
    collapse (mean) inst_mean cogn_mean aff_mean ///
             (semean) se_inst=inst_mean se_cogn=cogn_mean se_aff=aff_mean ///
             (count) n=inst_mean if !missing(`o'_ter), by(`o'_ter)
    rename `o'_ter tercile
    order tercile n inst_mean se_inst cogn_mean se_cogn aff_mean se_aff
    export excel using "conditional_means.xlsx", sheet("`o'") sheetreplace firstrow(variables)
    restore
}