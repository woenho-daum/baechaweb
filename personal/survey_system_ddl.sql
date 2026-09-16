
-- ============================================================
-- 1. 기사 기본정보
-- 이름은 항상 중복되지 않는다는 전제
-- ============================================================
/*
DROP TABLE IF EXISTS drivers; -- 이 데이타는 create_survey_db.py 에서 디비도 테이블도 만들고 자료도 넣는다

CREATE TABLE drivers (
    name            TEXT PRIMARY KEY,
    phone           TEXT NOT NULL UNIQUE,
    shift_day       TEXT NOT NULL CHECK (shift_day IN ('월','화','수','목','금','토','일')),
    off_day         TEXT NOT NULL CHECK (off_day IN ('월','화','수','목','금','토','일')),
    childcare_day   TEXT CHECK (
        childcare_day IS NULL OR childcare_day IN ('월','화','수','목','금','토','일')
    ),
	childcare_start TEXT NULL CHECK (
		childcare_start IS NULL OR (
			length(childcare_start) = 10 AND 
			strftime('%Y-%m-%d', childcare_start) = childcare_start
		)
	),
	childcare_end   TEXT NULL CHECK (
		childcare_end IS NULL OR (
			length(childcare_end) = 10 AND 
			strftime('%Y-%m-%d', childcare_end) = childcare_end
		)
	),
    CHECK (shift_day <> off_day)
);

CREATE INDEX idx_drivers_off_day ON drivers(off_day);
CREATE INDEX idx_drivers_shift_day ON drivers(shift_day);
CREATE INDEX idx_drivers_childcare_day ON drivers(childcare_day);
*/


-- ============================================================
-- 0. 사전 작업 (외래키 제약조건 임시 해제)
-- ============================================================
PRAGMA foreign_keys = OFF;

-- ============================================================
-- 1. 기존 인덱스 삭제 (Schema 캐시 충돌 방지)
-- ============================================================
DROP INDEX IF EXISTS ux_survey_master_active;
DROP INDEX IF EXISTS idx_sdl_survey_id;
DROP INDEX IF EXISTS idx_questions_survey;

-- ============================================================
-- 2. 기존 테이블 삭제 (자식 테이블 -> 부모 테이블 순서)
-- ============================================================
DROP TABLE IF EXISTS survey_answers;
DROP TABLE IF EXISTS survey_options;
DROP TABLE IF EXISTS survey_questions;
DROP TABLE IF EXISTS drivers_survey_link;
DROP TABLE IF EXISTS survey_master;

-- ============================================================
-- 3. 설문 마스터
-- ============================================================
CREATE TABLE survey_master (
    survey_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_title    TEXT NOT NULL,
    description     TEXT,
    is_active       INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1))
);

-- 활성 설문은 동시에 하나만 허용 (부분 유니크 인덱스)
CREATE UNIQUE INDEX ux_survey_master_active
ON survey_master(is_active)
WHERE is_active = 1;

-- ============================================================
-- 4. 기사 기본정보와 설문 마스터 링크 테이블
-- ============================================================
CREATE TABLE drivers_survey_link (
    driver_name    TEXT NOT NULL,
    survey_id      INTEGER NOT NULL,
    completed      INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0,1)),
    answer_date    DATETIME NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (driver_name, survey_id),
    
    FOREIGN KEY (driver_name) 
        REFERENCES drivers (name) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
        
    FOREIGN KEY (survey_id) 
        REFERENCES survey_master (survey_id) 
        ON DELETE CASCADE
);

-- 설문별 기사 목록 조회를 위한 인덱스 (테이블명 match: drivers_survey_link)
CREATE INDEX idx_sdl_survey_id ON drivers_survey_link (survey_id);

-- ============================================================
-- 5. 설문 문항
-- ============================================================
CREATE TABLE survey_questions (
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    question_text   TEXT NOT NULL,
    question_type   TEXT NOT NULL CHECK (question_type IN ('single','multi','text')),
    is_required     INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0,1)),
    PRIMARY KEY (survey_id, question_no),
    FOREIGN KEY (survey_id)
        REFERENCES survey_master(survey_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_questions_survey
ON survey_questions(survey_id, question_no);

-- ============================================================
-- 6. 문항 선택지
-- ============================================================
CREATE TABLE survey_options (
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    option_no       INTEGER NOT NULL,
    option_text     TEXT NOT NULL,
    PRIMARY KEY (survey_id, question_no, option_no),
    FOREIGN KEY (survey_id, question_no)
        REFERENCES survey_questions(survey_id, question_no)
        ON DELETE CASCADE
);

-- ============================================================
-- 7. 설문 답변
-- ============================================================
CREATE TABLE survey_answers (
    driver_name     TEXT NOT NULL,
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    option_no       INTEGER,
    answer_text     TEXT,
    PRIMARY KEY (driver_name, survey_id, question_no, option_no),
    FOREIGN KEY (driver_name)
        REFERENCES drivers(name)
        ON DELETE CASCADE,
    FOREIGN KEY (survey_id, question_no)
        REFERENCES survey_questions(survey_id, question_no)
        ON DELETE CASCADE,
    FOREIGN KEY (survey_id, question_no, option_no)
        REFERENCES survey_options(survey_id, question_no, option_no)
        ON DELETE CASCADE
);

-- ============================================================
-- 8. 외래키 제약조건 재활성화
-- ============================================================
PRAGMA foreign_keys = ON;
