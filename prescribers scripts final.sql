---WHICH prescriber had the highest total number of claims over all drugs---
SELECT npi, SUM(total_claim_count), nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
FROM prescription 
INNER JOIN prescriber 
USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name,specialty_description, npi
ORDER BY SUM(total_claim_count) DESC NULLS LAST
LIMIT 1;

--- ANSWER is NPI #1881634483, Bruce Pendley and claim count is 99,707---

---2a---
SELECT SUM(prescription.total_claim_count) AS total_claims, prescriber.specialty_description
FROM prescription 
INNER JOIN prescriber 
USING (NPI)
GROUP BY prescriber.specialty_description 
ORDER BY total_claims DESC NULLS LAST
LIMIT 1;
--ANSWER is Family Practice--

---2b---
SELECT specialty_description
FROM prescription 
INNER JOIN prescriber 
USING (NPI)
INNER JOIN drug
USING (drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC NULLS LAST
LIMIT 1;
--ANSWER is Nurse Practitioner at 900,845--

--2c--
SELECT specialty_description
FROM prescriber
LEFT JOIN prescription 
USING (npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL
-- Answer is 15--

--3a--
SELECT SUM(p.total_drug_cost), generic_name
FROM drug AS d
INNER JOIN prescription AS p
USING (drug_name)
GROUP BY d.generic_name
ORDER by SUM(p.total_drug_cost) DESC NULLS LAST
LIMIT 1;
--ANSWER is Insulin Glargine 104,264,066--

--3b--
SELECT ROUND(SUM(total_drug_cost/total_day_supply), 2) AS cost_day, d.generic_name
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
GROUP BY  d.generic_name
ORDER BY cost_day DESC;
-- Ledipasvir 88,270--

--OR--
SELECT ROUND(total_drug_cost/total_day_supply, 2) AS cost_day, d.generic_name
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
GROUP BY cost_day, d.generic_name
ORDER BY cost_day DESC;
--IMMUN GLOB 7,141--

--4a--
SELECT  opioid_drug_flag, antibiotic_drug_flag, drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_type DESC NULLS LAST;

--4b--
SELECT  SUM(p.total_drug_cost::money) AS total_cost,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug AS d
INNER JOIN prescription AS p
USING (drug_name)
GROUP BY drug_type
ORDER BY total_cost;
--ANSWER is 3 rows--

--5a--
SELECT *
FROM cbsa
WHERE cbsaname ILIKE '%, TN%';
--ANSWER is 33 or 56 depending on WILDCARD--
--OR--
SELECT COUNT(cbsa)
FROM cbsa AS c
INNER JOIN fips_county AS f
USING (fipscounty)
WHERE f.state = 'TN'
-- 10 or 42 whether us you use DISTINCT)--

--5b--
SELECT SUM(p.population), c.cbsaname
FROM cbsa AS c
INNER JOIN population AS p
USING( fipscounty)
GROUP BY  c.cbsaname 
ORDER BY SUM(p.population) DESC;
--ANSWER is NASH - MAX and Morristown - MIN--

--5c--
SELECT county, population
FROM population
FULL JOIN cbsa
USING (fipscounty)
FULL JOIN fips_county
USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC NULLS LAST
--2034 Rows--

--6a--
SELECT total_claim_count, drug_name
FROM prescription as P
WHERE total_claim_count >= 3000;
--ANSWER 9 rows--

--6b--
SELECT total_claim_count, drug_name, opioid_drug_flag
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
WHERE total_claim_count >= 3000;
--9 rows--

--6c--
SELECT total_claim_count, drug_name, opioid_drug_flag, nppes_provider_first_name, nppes_provider_last_org_name
FROM prescription AS p
INNER JOIN drug AS d
USING (drug_name)
INNER JOIN prescriber AS s
USING(npi)
WHERE total_claim_count >= 3000;
--9 Rows--

--7a--
SELECT *
FROM prescriber AS p
CROSS JOIN drug AS d
WHERE p.specialty_description = 'Pain Management' AND p.nppes_provider_city = 'NASHVILLE' AND d.opioid_drug_flag = 'Y';
--ANSWER is 637 rows--

--7b--
SELECT p.npi, d.drug_name, SUM(pp.total_claim_count)
FROM prescriber AS p
CROSS JOIN drug AS d
LEFT JOIN prescription AS pp
USING (npi, drug_name)
WHERE p.specialty_description = 'Pain Management' AND p.nppes_provider_city = 'NASHVILLE' AND d.opioid_drug_flag = 'Y'
GROUP BY p.npi,  d.drug_name
ORDER BY SUM(pp.total_claim_count) DESC NULLS LAST;
-- 637 Rows--

--7c--
SELECT p.npi, COALESCE(SUM(total_claim_count),0) AS total_claim, d.drug_name
FROM prescriber AS p
CROSS JOIN drug AS d
LEFT JOIN prescription AS pp
USING (npi, drug_name)
WHERE p.specialty_description = 'Pain Management' AND p.nppes_provider_city = 'NASHVILLE' AND d.opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY total_claim DESC
