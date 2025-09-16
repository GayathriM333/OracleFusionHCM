SELECT DISTINCT
    papf.person_number,
    ppnf.full_name AS employee_name,
    pj.name AS job_name,
    hrpf.name AS position_name,
    (SELECT user_status 
     FROM per_assignment_status_types_tl  
     WHERE assignment_status_type_id = paam.assignment_status_type_id 
       AND language = 'US') AS assignment_status,
    hle.name AS legal_employeer,
    bu.name AS business_unit,
    pd.name AS department,
    pea.email_address,
    DECODE(pea.email_type, 'W1', 'Work Email', 'H1', 'Home Email') AS email_type,
    (pa.country_code_number || '-' || pa.phone_number) AS phone_number,
    TO_CHAR(ppos.date_start, 'DD-MM-YYYY') AS hire_date,
    TO_CHAR(ppos.actual_termination_date, 'MM/DD/YYYY') AS termination_date,
    NVL2(ppos.actual_termination_date,
        (SELECT pav.action_name 
         FROM per_actions_vl pav
         WHERE pav.action_code = paam.action_code
           AND SYSDATE BETWEEN pav.start_date AND pav.end_date),
        NULL) AS termination_action,
    NVL2(ppos.actual_termination_date, parv.action_reason, '') AS termination_reason,
    TO_CHAR(pp.date_of_birth, 'DD-MM-YYYY') AS date_of_birth,
    CASE 
        WHEN pplf.sex = 'M' THEN 'Male'
        WHEN pplf.sex = 'F' THEN 'Female'
        WHEN pplf.sex = 'O' THEN 'Other'
        ELSE NULL 
    END AS gender,
    CASE 
        WHEN pplf.marital_status = 'M' THEN 'Married'
        WHEN pplf.marital_status = 'D' THEN 'Divorced'
        WHEN pplf.marital_status = 'S' THEN 'Single'
        ELSE NULL 
    END AS marital_status,
    mgr_papf.person_number AS manager_number,
    mgr_ppnf.full_name AS manager_name,
	PAWM.VALUE FTE,
	(SELECT MAX(PAWMF.VALUE)
          FROM PER_ASSIGN_WORK_MEASURES_F PAWMF
         WHERE PAWMF.ASSIGNMENT_ID(+) = PAAM.ASSIGNMENT_ID
               ----AND UPPER (TRIM(PAWMF.UNIT(+)))= UPPER(TRIM('FTE'))
               AND TRUNC (SYSDATE) BETWEEN NVL(PAWMF.EFFECTIVE_START_DATE(+),SYSDATE)
                                AND NVL(PAWMF.EFFECTIVE_END_DATE(+),SYSDATE)) --- FTE RESULT
          HEAD_COUNT,
 TO_CHAR(TO_DATE(paam.TIME_NORMAL_START, 'HH24:MI:SS'), 'HH:MI AM') AS start_time,
 TO_CHAR(TO_DATE(paam.TIME_NORMAL_FINISH, 'HH24:MI:SS'), 'HH:MI AM') AS end_time,
 paam.NORMAL_HOURS as Working_Hours,
 HAPFV.STANDARD_WORKING_HOURS || '-' || 
 (select Meaning from fnd_lookup_values 
where LOOKUP_TYPE='FREQUENCY'
and lookup_code=paam.FREQUENCY
and language='US') as STANDARD_WORKING_HOURS,
 paam.FULL_PART_TIME,
 (select rt.MEANING from hcm_lookups rt where 
 paam.PERMANENT_TEMPORARY_FLAG=rt.lookup_code(+)   AND rt.LOOKUP_TYPE(+) = 'REGULAR_TEMPORARY') as Regular_or_Temporary	,
 (SELECT MEANING FROM FND_LOOKUP_VALUES WHERE 
 LOOKUP_TYPE='ACA_COMMON_YES_NO_CHAR' AND LOOKUP_CODE=PAAM.MANAGER_FLAG AND LANGUAGE = 'US') as WORKING_AS_MANAGER,
 (SELECT  fnd.meaning
FROM fnd_lookup_values fnd 
WHERE fnd.lookup_type = 'HRX_FR_JOB_POPULATION_TYPE'
and fnd.lookup_code(+)=pjf.ATTRIBUTE_CATEGORY
  AND language = 'US') as Job_Population,
    (SELECT MEANING
         FROM HCM_LOOKUPS HC
         WHERE LOOKUP_TYPE ='EMPLOYEE_CATG'
         AND LOOKUP_CODE = PAAM.EMPLOYEE_CATEGORY )  as EMPLOYEE_CATEGORY
		, AATVL.NAME AS ABSENCE_TYPE
, TO_CHAR(APAE.START_DATE,'DD-fmMONTH-YYYY') AS ABSENCE_START_DATE
, TO_CHAR(APAE.END_DATE,'DD-fmMONTH-YYYY') AS ABSENCE_END_DATE
, APAE.DURATION AS DURATION
,cs.SALARY_AMOUNT
,TO_CHAR(cs.DATE_FROM,'DD-fmMONTH-YYYY') as start_date_A
,TO_CHAR(cs.DATE_TO,'DD-fmMONTH-YYYY') as end_date_A
,(select Meaning from fnd_lookup_values 
where LOOKUP_TYPE='HOURLY_SALARIED_CODE'
and lookup_code=paam.HOURLY_SALARIED_CODE
and language='US') as HOURLY_SALARIED
,(select Meaning from fnd_lookup_values 
where LOOKUP_TYPE='FREQUENCY'
and lookup_code=paam.FREQUENCY
and language='US') as Frequency
,HLA.LOCATION_NAME
,(select meaning from fnd_lookup_values
where lookup_type='ORA_HRX_FR_COUNTRIES'
and lookup_code=HLA.Country
AND language = 'US')
as Country
,(SELECT csbtl.salary_basis_name FROM  CMP_SALARY_BASES_TL csbtl 
       WHERE  csbtl.salary_basis_id = csbt.salary_basis_id  
       AND    csbtl.language  = 'US'  ) AS  Salary_Basis_name
,CS.ADJUSTMENT_AMOUNT
,CS.ADJUSTMENT_PERCENT

		 


FROM 
    per_all_people_f papf,
    per_person_names_f ppnf,
    per_all_assignments_m paam,
    per_jobs pj,
	per_jobs_f pjf,
    hr_all_positions_f_tl hrpf,
    hr_legal_entities hle,
    hr_all_organization_units_vl bu,
    per_departments pd,
    per_email_addresses pea,
    per_phones pa,
    per_periods_of_service ppos,
    per_action_reasons_vl parv,
    per_persons pp,
    per_people_legislative_f pplf,
    per_assignment_supervisors_f pasf,
    per_all_people_f mgr_papf,
    per_person_names_f mgr_ppnf,
	PER_ASSIGN_WORK_MEASURES_F PAWM,
	HR_ALL_POSITIONS_F_VL HAPFV,
	 (
        SELECT apae1.*
        FROM ANC_PER_ABS_ENTRIES apae1
        WHERE apae1.START_DATE = (
            SELECT MAX(apae2.START_DATE)
            FROM ANC_PER_ABS_ENTRIES apae2
            WHERE apae2.PERSON_ID = apae1.PERSON_ID
        )
    ) APAE,
	ANC_ABSENCE_TYPES_VL AATVL,
	 cmp_salary cs,
	 HR_LOCATIONS_ALL HLA
	 ,cmp_salary_v csv
	,cmp_salary_bases csbt


WHERE
    papf.person_id = ppnf.person_id
    AND ppnf.name_type = 'GLOBAL'
    AND SYSDATE BETWEEN ppnf.effective_start_date AND NVL(ppnf.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))
    AND SYSDATE BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND paam.person_id = papf.person_id
    AND paam.primary_flag = 'Y'
    AND paam.assignment_status_type = 'ACTIVE'
    AND paam.assignment_type IN ('E', 'C', 'N')
    AND SYSDATE BETWEEN paam.effective_start_date AND NVL(paam.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND paam.job_id = pj.job_id
    AND SYSDATE BETWEEN pj.effective_start_date AND NVL(pj.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND paam.position_id = hrpf.position_id
    AND hrpf.language = 'US'
    AND SYSDATE BETWEEN hrpf.effective_start_date AND NVL(hrpf.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND paam.legal_entity_id = hle.organization_id
    AND hle.classification_code = 'HCM_LEMP'
    AND hle.status = 'A'
    AND SYSDATE BETWEEN hle.effective_start_date AND NVL(hle.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND paam.business_unit_id = bu.organization_id

    AND paam.organization_id = pd.organization_id
    AND SYSDATE BETWEEN pd.effective_start_date AND NVL(pd.effective_end_date, TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND pea.person_id(+) = papf.person_id
    AND pea.email_type(+) IN ('W1','H1')

    AND pa.person_id(+) = papf.person_id
    AND pa.phone_id(+) = papf.primary_phone_id
    AND pa.phone_type(+) IN ('W1','H1')

    AND ppos.person_id(+) = papf.person_id

    AND paam.reason_code = parv.action_reason_code(+)

    AND pp.person_id(+) = papf.person_id

    AND pplf.person_id(+) = papf.person_id
    AND SYSDATE BETWEEN pplf.effective_start_date(+) AND NVL(pplf.effective_end_date(+), TO_DATE('4712-12-31','YYYY-MM-DD'))

    AND pasf.person_id(+) = papf.person_id
    AND pasf.assignment_id(+) = paam.assignment_id
    AND pasf.primary_flag(+) = 'Y'

    AND mgr_papf.person_id(+) = pasf.manager_id
    AND SYSDATE BETWEEN mgr_papf.effective_start_date(+) AND NVL(mgr_papf.effective_end_date(+), TO_DATE('4712-12-31','YYYY-MM-DD'))
    
    AND mgr_ppnf.person_id(+) = mgr_papf.person_id
    AND mgr_ppnf.name_type(+) = 'GLOBAL'
    AND SYSDATE BETWEEN mgr_ppnf.effective_start_date(+) AND NVL(mgr_ppnf.effective_end_date(+), TO_DATE('4712-12-31','YYYY-MM-DD'))
    AND SYSDATE BETWEEN pasf.effective_start_date(+) AND NVL(pasf.effective_end_date(+), TO_DATE('4712-12-31','YYYY-MM-DD'))

 
------FTE------
AND PAAM.ASSIGNMENT_ID = PAWM.ASSIGNMENT_ID(+)
 AND PAWM.UNIT(+) = 'FTE'
 

-----
 AND PAAM.POSITION_ID = HAPFV.POSITION_ID(+)
AND SYSDATE BETWEEN HAPFV.effective_start_date(+) AND NVL(HAPFV.effective_end_date(+), TO_DATE('4712-12-31','YYYY-MM-DD'))

----------------------Job
AND paam.job_id = pjf.job_id(+)
AND SYSDATE BETWEEN pjf.effective_start_date(+) AND NVL(pjf.effective_end_date(+), TO_DATE('4712-12-31','YYYY-MM-DD'))

---------------------------Absence--------------------------
--AND APAE.PERIOD_OF_SERVICE_ID = PPOS.PERIOD_OF_SERVICE_ID
AND APAE.ABSENCE_TYPE_ID  = AATVL.ABSENCE_TYPE_ID (+)
AND TRUNC(SYSDATE) BETWEEN AATVL.EFFECTIVE_START_DATE AND AATVL.EFFECTIVE_END_DATE
and papf.person_id=APAE.person_id(+)

--=========================Salary---------------=====================
AND papf.PERSON_ID=cs.PERSON_ID
and sysdate BETWEEN CS.DATE_FROM(+) AND NVL(CS.DATE_TO(+),TO_DATE('31-12-4712','DD-MM-YYYY'))
and  cs.salary_id=csv.salary_id
AND  csv.salary_basis_id=csbt.salary_basis_id
and paam.assignment_id = cs.assignment_id


--------------Locations-------------------
and paam.location_id=HLA.location_id(+)


 AND (:P_PERSON_NUMBER IS NULL OR TO_CHAR(papf.person_number) = TRIM(:P_PERSON_NUMBER))
    AND (
        (:P_DATE_START IS NULL OR :P_DATE_TO IS NULL)
        OR ppos.date_start BETWEEN :P_DATE_START AND :P_DATE_TO
    )
