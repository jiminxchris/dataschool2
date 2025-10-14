CREATE TABLE user_info (
	user_id varchar(10) PRIMARY KEY,
	user_name varchar(10) NOT NULL,
	jumin_no char(13) NOT NULL,
	tel_co char(2) NOT NULL,
	tel_no char(11) NOT NULL
);

CREATE TABLE arrival (
    id VARCHAR(10) NOT NULL,
    addr_name VARCHAR(10) NOT NULL,
    addr VARCHAR(200) NOT NULL,
    CONSTRAINT arrival_user_info_fk FOREIGN KEY (id) REFERENCES user_info (user_id)
);

COMMENT ON TABLE arrival IS '배송지';
