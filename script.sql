SELECT * FROM fms.chick_info;

SELECT chick_no AS cn, breeds "품종" FROM fms.chick_info;

SELECT count(*) FROM fms.chick_info;

SELECT chick_no, hatchday, egg_weight FROM fms.chick_info ORDER BY egg_weight DESC, hatchday ASC;

SELECT chick_no, hatchday, egg_weight 
FROM fms.chick_info 
ORDER BY egg_weight DESC, hatchday ASC
LIMIT 7 OFFSET 2;

SELECT DISTINCT(egg_weight) 
FROM fms.chick_info;

SELECT chick_no, egg_weight 
FROM fms.chick_info
WHERE egg_weight > 68 or egg_weight < 63;

-- 품종이 C로 시작하는 병아리들만 필터링
SELECT chick_no, breeds 
FROM fms.chick_info
WHERE breeds LIKE 'C%';

-- 품종이 C1, D1에 속하는 병아리들만 필터링
SELECT chick_no, breeds 
FROM fms.chick_info
WHERE breeds in ('C1', 'D1');

SELECT *
FROM fms.env_cond
WHERE humid IS NULL;

SELECT *
FROM fms.health_cond
WHERE note IS NULL;

-- NULL과 ''은 다름
UPDATE fms.health_cond 
SET note=NULL
WHERE trim(note)='';


-- 출신농장, 성별, 품종 합
SELECT
farm||gender||BREEDS AS id
FROM fms.chick_info;

-- 성별 M을 'Male'로 변환해서 출력
SELECT
chick_no,REPLACE(replace(gender, 'M','Male'),'F', 'Female') "성별"
FROM fms.chick_info;

SELECT count(*) FROM fms.chick_info;
SELECT * FROM fms.chick_info;

SELECT 
sum(egg_weight),
avg(egg_weight),
min(egg_weight),
max(egg_weight)
FROM fms.chick_info;

SELECT 
breeds,avg(egg_weight)
FROM fms.chick_info
GROUP BY breeds;

-- prod_result 테이블에서 생산일자별 생닭 중량의 평균, 합계 출력
SELECT
prod_date, 
avg(raw_weight) AS total_avg, 
sum(raw_weight) total_sum
from fms.prod_result
GROUP BY prod_date
ORDER BY prod_date;

-- ship_result에서 고객사별로 출하된 마리수 출력
SELECT
*
FROM fms.ship_result;

SELECT
customer,count(chick_no)
FROM fms.ship_result
GROUP BY customer
having count(chick_no)>=10;

SELECT
arrival_date,customer
FROM fms.ship_result
WHERE arrival_date >= '2023-02-05';

SELECT
customer,count(chick_no)
FROM fms.ship_result
WHERE arrival_date >= '2023-02-05'
GROUP BY customer
having count(chick_no)>=8;

SELECT now();
SELECT current_date;
SELECT current_timestamp;
SELECT current_timestamp::Date;

SELECT 
hatchday, 
to_char(hatchday,'YYYY')
FROM fms.chick_info;

SELECT 
hatchday, 
to_char(hatchday,'Mon')
FROM fms.chick_info;

SELECT *
FROM fms.env_cond
WHERE humid IS NULL;

SELECT farm, date, 
humid, coalesce(humid, 60)
FROM fms.env_cond
WHERE date BETWEEN '2023-01-23' AND '2023-01-27';
AND farm='A';

SELECT 
chick_no,
gender,
CASE gender
	WHEN 'M' THEN '수컷'
	WHEN 'F' THEN '암컷'
	ELSE '성별미상'
END "성별"
FROM fms.chick_info;

-- 스칼라 서브쿼리
SELECT a.chick_no, 
a.breeds,
(
	SELECT b.code_desc 
	FROM fms.master_code b
	WHERE b.column_nm = 'breeds'
	AND b.code = a.breeds
)
FROM fms.chick_info a;

SELECT code, code_desc 
FROM fms.master_code
WHERE column_nm = 'breeds';

-- 인라인 뷰
SELECT 
a.chick_no, a.breeds,
b.code_desc
FROM fms.chick_info a,
(
	SELECT code, code_desc 
	FROM fms.master_code
	WHERE column_nm = 'breeds'
) b
WHERE a.breeds = b.code;

CREATE OR REPLACE VIEW fms.breeds_prod
(
prod_data, breed_nm, total_sum
)
AS SELECT
a.prod_date,
(
	SELECT m.code_desc AS breed_nm
	FROM fms.master_code m
	WHERE m.column_nm = 'breeds'
	AND m.code = b.breeds
),
sum(a.raw_weight) AS total_sum
from
fms.prod_result a,
fms.chick_info b
WHERE
a.chick_no = b.chick_no
AND a.pass_fail='P'
GROUP BY a.prod_date, b.breeds;

CREATE OR REPLACE VIEW fms.daily_shipment_summary (
    ship_date, 
    customer_nm, 
    breeds_nm, 
    total_orders, 
    total_chicks
)
AS
SELECT
    sr.arrival_date AS ship_date,  -- 도착일을 출하일로 간주
    sr.customer AS customer_nm,
    mc.code_desc AS breeds_nm,
    COUNT(DISTINCT sr.order_no) AS total_orders, -- 주문 건수
    COUNT(sr.chick_no) AS total_chicks           -- 출하된 병아리 총 개수
FROM
    fms.ship_result sr
INNER JOIN
    fms.chick_info ci ON sr.chick_no = ci.chick_no -- 육계 정보 조인
INNER JOIN
    fms.master_code mc ON ci.breeds = mc.code AND mc.column_nm = 'breeds' -- 품종명 가져오기
GROUP BY
    sr.arrival_date, sr.customer, mc.code_desc
ORDER BY
    ship_date, customer_nm;

COMMENT ON VIEW fms.daily_shipment_summary IS '일별, 고객사별, 품종별 출하 요약 정보';


-- 뷰의 전체 내용 조회 (복잡한 조인 및 집계 쿼리가 숨겨짐)
SELECT * FROM fms.daily_shipment_summary;

-- 뷰를 이용한 특정 조건 조회
SELECT 
    ship_date,
    breeds_nm,
    total_chicks
FROM 
    fms.daily_shipment_summary
WHERE 
    customer_nm = 'YESYES' 
    AND ship_date >= '2023-02-04';
