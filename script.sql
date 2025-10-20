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


CREATE OR REPLACE FUNCTION fms.func_farm_ship_summary(farm_param varchar)
RETURNS TABLE(farm varchar, customer varchar, shipped_count BIGINT) AS $$
	SELECT 
	ci.farm,
	sr.customer,
	COUNT(*) AS shipped_count
	FROM fms.prod_result pr
	JOIN fms.chick_info ci ON pr.chick_no = ci.chick_no
	JOIN fms.ship_result sr ON pr.chick_no = sr.chick_no
	WHERE pr.pass_fail = 'P' and ci.farm = farm_param
	GROUP BY ci.farm, sr.customer; 
$$ LANGUAGE SQL;


-- 1. 농장별 고객사별로 납품 횟수 View -> 함수로(함수만들기 복습)
-- 2. 함수를 스케줄러 잡으로 등록, 파일로 저장(스케줄러 등록 복습)
-- 3. 저장된 파일의 내용확인(파일로 저장하기 도전), 분마다 저장되는 파일 구분

SELECT * FROM func_farm_ship_summary('A');

COPY(SELECT * from fms.func_farm_ship_summary('A')) TO 'C:/Users/Public/farm_ship_summary.csv' CSV HEADER;


SELECT COUNT(*)
FROM fms.chick_info
WHERE breeds = 'C1';

CREATE TABLE IF NOT EXISTS fms.prod_log (
log_id SERIAL PRIMARY KEY,
chick_no VARCHAR(20) NOT NULL,
prod_date DATE NOT NULL,
old_weight NUMERIC,
new_weight NUMERIC,
logged_at TIMESTAMP
);

-- 프로시저 만들기(변경이력관리)
-- prod_result 테이블의 닭의 무게 변경시
-- 해당 테이블의 무게를 변경하면서 prod_log 테이블에 변경이력 로그를 남긴다.
-- B2300020	2023-02-02	1500	N	12	P
CALL fms.update_and_log_prod_weight('B2300020', '2023-02-02', 1136);

 체중 업데이트
UPDATE fms.prod_result
SET  raw_weight = 1136
WHERE chick_no = 'B2300020' AND prod_date = '2023-02-02';
UPDATE fms.prod_result
SET  raw_weight = p.raw_weight
WHERE chick_no = p.chick_no AND prod_date = p.prod_date;
 로그 테이블에 기록
INSERT fms.prod_log
(chick_no,prod_date,old_weight,new_weight,logged_at)
VALUES ('B2300020','2023-02-02', 1500, 1136, now() );

CREATE OR replace PROCEDURE update_and_log_prod_weight(
	p_chick_no VARCHAR,
	p_prod_date DATE,
	p_raw_weight NUMERIC
) AS $$
declare
	old_weight NUMERIC;
	log_message TEXT;
begin
	select raw_weight into old_weight
	from fms.prod_result
	where chick_no = p_chick_no AND prod_date = p_prod_date;

	if not found then
		-- 데이터가 없는 경우의 예외처리부분
		raise WARNING '경고: 해당하는 데이타가 없습니다. chick_no: %, prod_date: %', p_chick_no, p_prod_date;
		log_message := '업데이트 대상 행 없음:' || p_chick_no || '( ' || p_prod_date || ')';
		INSERT into fms.prod_log
	(chick_no,prod_date,old_weight,new_weight,logged_at)
	VALUES (p_chick_no,p_prod_date, NULL, NULL, now() );
		return;
	end if;
	
	UPDATE fms.prod_result
	SET  raw_weight = p_raw_weight
	WHERE chick_no = p_chick_no AND prod_date = p_prod_date;

	INSERT into fms.prod_log
	(chick_no,prod_date,old_weight,new_weight,logged_at)
	VALUES (p_chick_no,p_prod_date, old_weight, p_raw_weight, now() );
end;
$$ LANGUAGE plpgsql;

CALL fms.update_and_log_prod_weight('D2300020', '2023-02-02', 1136);

-- 트리거 
-- 데이터의 변경을 감지 로그 테이블 자동 기록
-- 건강테이블에 데이터가 변경될때마다 감지하는 트리거
-- 1. 로그테이블 health_cond( 건강상태 변경 이력로그)
-- 2. 함수(로그테이블에 이력을 저장)
-- 3. 트리거로 등록

-- 1. 로그테이블
CREATE TABLE fms.health_cond_audit (
	audit_id SERIAL PRIMARY KEY,
	chick_no VARCHAR(20) NOT NULL,
	old_body_temp NUMERIC(4,1),
	new_body_temp NUMERIC(4,1),
	check_date DATE,
	modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	operation VARCHAR(10)
);

-- 2. 트리거 함수
CREATE OR REPLACE FUNCTION fms.log_health_change()
RETURNS trigger AS $$
begin
	if TG_OP = 'UPDATE' then -- OLD, NEW
		raise notice 'UPDATE 트리거 실행중: % -> %', OLD.body_temp,
		NEW.body_temp;
		insert into fms.health_cond_audit
		(chick_no, old_body_temp, new_body_temp, check_date, operation)
		values(
		OLD.chick_no,
		OLD.body_temp,
		NEW.body_temp,
		NEW.check_date,
		TG_OP
		);
	end if;
	return NEW; -- 트리거 함수에서 업데이트된 행을 그대로 반환의 이미
end;
$$ LANGUAGE plpgsql;

-- 3. 트리거 등록
CREATE OR REPLACE TRIGGER health_audit_trigger
AFTER UPDATE ON fms.health_cond
FOR EACH ROW
EXECUTE FUNCTION fms.log_health_change();

UPDATE fms.health_cond
SET body_temp = 45
WHERE chick_no ='B2310019' AND check_date = '2023-01-10';

-- 1. 환경이상 로그 테이블
CREATE TABLE fms.env_anomaly (
anomaly_id SERIAL PRIMARY KEY,
farm CHAR(1),
check_date DATE,
temp NUMERIC(3,0),
humid NUMERIC(3,0),
reason TEXT,
detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO fms.env_cond 
(farm, date, temp, humid) 
VALUES ('B', '2023-01-25', 21, 60); -- 정상 데이터

INSERT INTO fms.env_cond 
(farm, date, temp, humid) 
VALUES ('B', '2023-01-25', 21, 85);  -- 이상치 데이터 입력시

-- 2. 트리거 함수 구현 습도 값이 허용 범위(55~75)
CREATE OR REPLACE FUNCTION fms.detect_env_abnomaly()
RETURNS trigger AS $$
begin
	if new.humid > 75 or new.humid < 55 then
		insert into fms.env_anomaly
			(farm,check_date,temp,humid,reason)
			values(
			NEW.farm,
			NEW.date,
			NEW.temp,
			NEW.humid,
			case 
				when new.humid > 75 then '습도 과다'
				else '습도 부족'
			end
		);
	end if;
	return NEW; -- 트리거 함수에서 업데이트된 행을 그대로 반환의 이미
end;
$$ LANGUAGE plpgsql;

-- 3. 트리거 함수 등록
CREATE OR REPLACE TRIGGER env_abnomaly_trigger
AFTER INSERT ON fms.env_cond
FOR EACH ROW
EXECUTE FUNCTION fms.detect_env_abnomaly();

SELECT event_object_table AS table_name, trigger_name
FROM information_schema.triggers
GROUP BY table_name, trigger_name
ORDER BY table_name, trigger_name;

SELECT b.DESTINATION, sum(a.RAW_WEIGHT)
FROM fms.prod_result a
join fms.ship_result b
ON a.CHICK_NO = b.CHICK_NO
WHERE a.size_stand >= 11
GROUP BY b.DESTINATION
HAVING (sum(a.RAW_WEIGHT)/1000) >= 5
ORDER BY sum(a.RAW_WEIGHT) DESC
LIMIT 3;
