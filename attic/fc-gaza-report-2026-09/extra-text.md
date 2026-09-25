# draft - monitoring nutritional status in Gaza

Katharine Sherratt, Kevin van Zandvoort, Ciara Judge, Clara Brigitta, Ciara McCarthy, Zeina Jamaluddine, Francesco Checchi \[MAY NEED UNRWA AUTHORS\]

1 Health in Humanitarian Crises Centre; 2 Centre for Mathematical Modelling of Infectious Diseases, London School of Hygiene and Tropical Medicine

## Abstract

## Background

The Gaza Strip has experienced a long-term crisis of food insecurity, impacting availability and access to adequate individual nutrition.
This crisis substantially worsened since the current war’s onset in October 2023.
Restrictions on food imports into Gaza, combined with systematic destruction of the Strip’s food-producing sectors, have curtailed food availability \[1, 2\].
Food insecurity escalated following Israel’s full border closure in March 2025.
By August 2025 an Integrated Phase Classification (IPC) analysis concluded that famine was occurring in parts of Gaza \[3\].
The situation eased after the partial October 2025 ceasefire \[4\].
However, this aggregated picture of food security obscures the complexity of individual nutritional status.

To determine famine status, the IPC’s analysis framework synthesises evidence and expert assessment on causal factors along the pathway from food insecurity to mortality.
In Gaza, empirical estimates of acute malnutrition, a central outcome in this pathway, have largely consisted of repeated, small-scale probabilistic or convenient surveys of children’s middle-upper arm circumference, a mortality-predictive index \[5, 6\].
While this single information stream provides methodological and sentinel location consistency, more might have been expected in a setting characterised by universal literacy, reasonable connectivity, mediatic resonance and numerous humanitarian actors.

Beyond its threshold-based IPC definition, famine is understood as resulting from exhausted food insecurity coping mechanisms, including adults starving themselves to feed children \[7\].
While the Gazan population experiences a double burden of malnutrition, and at the October 2023 baseline, Gaza’s adult population was mainly overweight \[8\], media stories described people losing a large percentage of their body weight over the subsequent months.
As famine unfolded in 2025, we received testimonies from humanitarian actors in Gaza that even their salaried staff, despite proximity to aid, were going hungry.
We hypothesised that trends in adult bodyweight within this occupational group could provide a useful complementary signal of food insecurity.

In July 2025, we initiated a project to monitor the nutritional status of humanitarian staff.
The project aimed to inform humanitarian decision-making, advocacy and diplomatic action.
We used simple, low-cost methods to enable staff to self-report their weight over time.
Our specific objectives were to:

Estimate average weight and body-mass index (BMI) change since pre-war (7 October 2023) levels;

Monitor the relative and absolute evolution of weight and BMI over time;

Describe differences in weight and BMI change by sex, age, governorate of residence, and responsibility for child nutrition

## Methods

We partnered with Save the Children International (SCI) and the United Nations Relief and Works Agency for Palestinian Refugees in the Near East (UNRWA).
The project relied on anonymous, opt-in participation, with light data collection and an automated data pipeline outputting real-time visualisations Staff and contractors of SCI and UNRWA’s Health Section were invited to participate.
Both agencies positioned calibrated, electronic adult weight balances in their female and male changing rooms.
They shared standardised information in Arabic and a QR code linking to a non-technical project description.
Staff used Android devices or computers to read study information, provide consent and enter data.

We designed a baseline survey to collect data on sex, age, governorate of current residence, employment status, number of dependents \<10 years old (yo), height (nearest cm) and self-recalled pre-war weight defined as prior to October 2023 (nearest 0.1 Kg).
We later added a question about chronic health conditions.
At baseline and thereafter staff were to record their weight only, measured without shoes, heavy clothing or bags.
We suggested that participants record a weekly measurement, but we did not contact participants for follow-up.
We provide both survey forms in the Supplement.

All participation was voluntary and anonymised.
Given Gaza’s data insecurity \[9\], we gave staff three options for creating an ID to link repeat measurements and IDs were encrypted at source: staff were told that researchers could not identify them.
We did not collect names or contact details.
Our data collection system enabled offline data entry.

We automated and reported real-time analysis on a public dashboard (https://cmmid.github.io/gaza-response/).
We excluded observations outside of plausible ranges (weight, 30-180kg; BMI: 10-60; daily rate of change in weight since study entry over +/-10%; age, 16-99 years; dependent children, 0-20).
We provided simple descriptive statistics and visualisations to show weight and BMI change by sex, age, governorate of residence, and responsibility for child nutrition.

\< add retrospective analysis methods \>

We collected data using Open Data Kit, with analysis in R version 4.5, and published using Quarto and Github.
We received ethics approval from the London School of Hygiene and Tropical Medicine (ref. 32766).
Decide on data availability, provide repository here.

*take from[protocol](./attic/protocol.docx)*

## Results

*see [README](README.qmd) for some initial descriptive code/plots*

## Discussion

We provided real-time information on the nutritional status of humanitarian staff in the Gaza Strip from July 2025, with the aim to inform humanitarian decision-making, advocacy, and diplomatic action.
Data were anonymised and aggregated, with visualisation of trends over time and space to illustrate conditions inside Gaza, available on a public website.
We found …

We used a rapid, low-cost study design to add information to a data-sparse crisis.
This aimed to inform humanitarian decision-making, advocacy, and diplomatic action.
We relied on voluntary participation among humanitarian aid staff, a group likely unrepresentative of the general population @cite\].
Participation depended on capacity, advocacy, and interest, and we noted relatively few participants providing follow-up measurements.

Weight measurements have been used to establish famine classifications, and in Gaza particularly among children.
Adults are typically not represented in these samples, and there has been little consistent follow up of the same participants over time.
This has made it difficult to assess whether changes are due to sampling differences or individual nutritional status over time.
In comparison with similar work…

-   WHO estimate of prevalence % underweight (BMI \<18.5 kg/m2) among adults, all occupied Palestinian territory in 2023:

    | Pop   | Crude estimate  | Age standardised |
    |-------|-----------------|------------------|
    | All   | 3.2 \[2.3-4.3\] | 2.5 \[1.8-3.4\]  |
    | Men   | 3.4 \[2.0-5.3\] | 2.8 \[1.6-4.4\]  |
    | Women | 2.9 \[1.9-4.2\] | 2.3 \[1.4-3.3\]  |

In this study, we used weight as an indicator of the nutritional and food security situation.
However, weight is only a proxy for documenting nutritional status over time @burchiFoodAvailabilityNutritional2016.
Famines have multidimensional causes and consequences @sen.
Other indicators could also include morbidity (e.g. admissions or consultations for conditions related to acute malnutrition, such as pneumonia and acute diarrhoea); relapses from malnutrition treatment, the rate of which typically indicates insufficient food at household level; incidence of from infections following trauma injuries, common in undernourished individuals; food availability in markets; and food distribution data.
…citations

We worked collaboratively across institutions to design and implement this work, with technical support in the UK led by requests from humanitarian aid organisations in Gaza.
At the same time, research across populations is both inefficient and unequal.
We were unable to assess the provide continuous maintenance that is essential for sustainable software @SSI.
This can be mitigated with core principles of equitable research partnerships: fairness, respect, honesty, and care @TRUST.
We believe it is possible for such work to empower civil society to tell its own story, not only through media, but also by supporting the systematic capture of contemporary experience.

Unpredictable crises should be met with predictable situational awareness to enable short term response and long term accountability.
We believe there is disproportionate value of information to be gained from simple and collaborative data collection.
Unconventional populations and methods, e.g. through humanitarian assistance work, can still provide public health indicators that are both available and timely @checchi2017\].
Such data can and should be made available routinely, e.g. on the United Nations data repository, HDX.
Consistency is essential, and requires shifting from intermittent reports to automated data pipelines and live visualisations.
Equally importantly, sustained data collation creates a documented trace of contemporary experience.
Ultimately, this adds to the weight of evidence from which to anchor historical accountability.

## Supplementary Information

-   Protocol

-   Snapshot of the dashboard