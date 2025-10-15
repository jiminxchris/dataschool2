CREATE SCHEMA fms;

CREATE TABLE IF NOT EXISTS fms.chick_info (
    chick_no CHAR(8) PRIMARY KEY,
    breeds CHAR(2) NOT NULL,
    gender CHAR(1) NOT NULL,
    hatchday DATE NOT NULL,
    egg_weight SMALLINT NOT NULL,
    vaccination1 SMALLINT,
    vaccination2 SMALLINT,
    farm CHAR(1) NOT NULL
);

COMMENT ON SCHEMA fms
    IS '농장관리시스템(Farm Management System) DB';

COMMENT ON TABLE fms.chick_info
    IS '육계정보';

COMMENT ON COLUMN fms.chick_info.chick_no
    IS '육계번호';

COMMENT ON COLUMN fms.chick_info.breeds
    IS '품종';

COMMENT ON COLUMN fms.chick_info.gender
    IS '성별';

COMMENT ON COLUMN fms.chick_info.hatchday
    IS '부화일자';

COMMENT ON COLUMN fms.chick_info.egg_weight
    IS '종란무게';

COMMENT ON COLUMN fms.chick_info.vaccination1
    IS '예방접종1';

COMMENT ON COLUMN fms.chick_info.vaccination2
    IS '예방접종2';

COMMENT ON COLUMN fms.chick_info.farm
    IS '사육장';

----------------------------------------------------
CREATE TABLE IF NOT EXISTS fms.env_cond (
    farm CHAR(1) NOT NULL,
    date DATE NOT NULL,
    temp SMALLINT,
     humid SMALLINT,
    light_hr SMALLINT,
    lux SMALLINT
);

COMMENT ON TABLE fms.env_cond IS '사육환경';
COMMENT ON COLUMN fms.env_cond.farm IS '사육장';
COMMENT ON COLUMN fms.env_cond.date IS '일자';
COMMENT ON COLUMN fms.env_cond.temp IS '기온';
COMMENT ON COLUMN fms.env_cond.humid IS '습도';
COMMENT ON COLUMN fms.env_cond.light_hr IS '점등시간';
COMMENT ON COLUMN fms.env_cond.lux IS '조도';

----------------------------------------------------
CREATE TABLE IF NOT EXISTS fms.health_cond (
    chick_no CHAR(8) NOT NULL,
    check_date DATE NOT NULL,
    weight SMALLINT NOT NULL,
    body_temp NUMERIC(3,1) NOT NULL,
    breath_rate SMALLINT NOT NULL,
    feed_intake SMALLINT NOT NULL,
    diarrhea_yn CHAR(1) NOT NULL,
    note TEXT,
    FOREIGN KEY (chick_no) REFERENCES fms.chick_info (chick_no)
);

COMMENT ON TABLE fms.health_cond IS '건강상태';
COMMENT ON COLUMN fms.health_cond.chick_no IS '육계번호';
COMMENT ON COLUMN fms.health_cond.check_date IS '검사일자';
COMMENT ON COLUMN fms.health_cond.weight IS '체중';
COMMENT ON COLUMN fms.health_cond.body_temp IS '체온';
COMMENT ON COLUMN fms.health_cond.breath_rate IS '호흡수';
COMMENT ON COLUMN fms.health_cond.feed_intake IS '사료섭취량';
COMMENT ON COLUMN fms.health_cond.diarrhea_yn IS '설사여부';
COMMENT ON COLUMN fms.health_cond.note IS '노트';

----------------------------------------------------
CREATE TABLE IF NOT EXISTS fms.master_code (
    column_nm VARCHAR(15),
    type VARCHAR(10),
    code VARCHAR(10),
    code_desc VARCHAR(20)
);

COMMENT ON TABLE fms.master_code IS '마스터코드';
COMMENT ON COLUMN fms.master_code.column_nm IS '열이름';
COMMENT ON COLUMN fms.master_code.type IS '타입';
COMMENT ON COLUMN fms.master_code.code IS '코드';
COMMENT ON COLUMN fms.master_code.code_desc IS '코드의미';
----------------------------------------------------
CREATE TABLE IF NOT EXISTS fms.prod_result (
    chick_no CHAR(8) NOT NULL,
    prod_date DATE NOT NULL,
    raw_weight SMALLINT NOT NULL,
    disease_yn CHAR(1) NOT NULL,
    size_stand SMALLINT NOT NULL,
    pass_fail CHAR(1) NOT NULL,
    FOREIGN KEY (chick_no) REFERENCES fms.chick_info (chick_no)
);

COMMENT ON TABLE fms.prod_result IS '생산실적';
COMMENT ON COLUMN fms.prod_result.chick_no IS '육계번호';
COMMENT ON COLUMN fms.prod_result.prod_date IS '생산일자';
COMMENT ON COLUMN fms.prod_result.raw_weight IS '생닭중량';
COMMENT ON COLUMN fms.prod_result.disease_yn IS '질병유무';
COMMENT ON COLUMN fms.prod_result.size_stand IS '호수';
COMMENT ON COLUMN fms.prod_result.pass_fail IS '적합여부';

----------------------------------------------------
CREATE TABLE IF NOT EXISTS fms.ship_result (
    chick_no CHAR(8) NOT NULL,
    order_no CHAR(4) NOT NULL,
    customer VARCHAR(20) NOT NULL,
    due_date DATE NOT NULL,
    arrival_date DATE,
    destination VARCHAR(10) NOT NULL,
    FOREIGN KEY (chick_no) REFERENCES fms.chick_info (chick_no)
);

COMMENT ON TABLE fms.ship_result IS '출하실적';
COMMENT ON COLUMN fms.ship_result.chick_no IS '육계번호';
COMMENT ON COLUMN fms.ship_result.order_no IS '주문번호';
COMMENT ON COLUMN fms.ship_result.customer IS '고객사';
COMMENT ON COLUMN fms.ship_result.due_date IS '납품기한일';
COMMENT ON COLUMN fms.ship_result.arrival_date IS '도착일';
COMMENT ON COLUMN fms.ship_result.destination IS '도착지';

----------------------------------------------------

CREATE TABLE IF NOT EXISTS fms.unit (
    column_nm VARCHAR(15),
    unit VARCHAR(10)
);

COMMENT ON TABLE fms.unit IS '단위';
COMMENT ON COLUMN fms.unit.column_nm IS '열이름';
COMMENT ON COLUMN fms.unit.unit IS '단위';
