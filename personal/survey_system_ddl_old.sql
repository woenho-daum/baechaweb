PRAGMA foreign_keys = ON;

-- 1. 기사 기본정보
CREATE TABLE drivers (
    name            TEXT PRIMARY KEY,
    phone           TEXT NOT NULL UNIQUE,
    shift_day       TEXT NOT NULL CHECK (shift_day IN ('월','화','수','목','금','토','일')),
    off_day         TEXT NOT NULL CHECK (off_day IN ('월','화','수','목','금','토','일')),
    childcare_day   TEXT CHECK (
        childcare_day IS NULL OR childcare_day IN ('월','화','수','목','금','토','일')
    ),
    CHECK (shift_day <> off_day)
);

CREATE INDEX idx_drivers_off_day ON drivers(off_day);
CREATE INDEX idx_drivers_shift_day ON drivers(shift_day);
CREATE INDEX idx_drivers_childcare_day ON drivers(childcare_day);

-- 2. 설문 마스터
CREATE TABLE survey_master (
    survey_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_title    TEXT NOT NULL,
    description     TEXT,
    is_active       INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1)),
);

-- 활성 설문은 동시에 하나만 허용
CREATE UNIQUE INDEX ux_survey_master_active
ON survey_master(is_active)
WHERE is_active = 1;

-- 3. 설문 문항
CREATE TABLE survey_questions (
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    question_text   TEXT NOT NULL,
    question_type   TEXT NOT NULL CHECK (question_type IN ('single','multi','text')),
    is_required     INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0,1)),
	PRIMARY KEY (survey_id, question_no)
    FOREIGN KEY (survey_id) REFERENCES survey_master(survey_id) ON DELETE CASCADE,
);

CREATE INDEX idx_questions_survey
ON survey_questions(survey_id, question_no);

-- 4. 문항 선택지
CREATE TABLE survey_options (
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    option_no       INTEGER NOT NULL,
    option_text     TEXT NOT NULL,
	PRIMARY KEY (survey_id,question_no, option_no)
    FOREIGN KEY (survey_id, question_no) REFERENCES survey_questions(survey_id, question_no) ON DELETE CASCADE,
);

-- 5. 설문 답변
CREATE TABLE survey_answers (
	driver_name     TEXT NOT NULL,
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    option_no       INTEGER,
    answer_text     TEXT,
	PRIMARY KEY (driver_name, survey_id, question_no, option_no)
    FOREIGN KEY (survey_id, question_no) REFERENCES survey_questions(survey_id, question_no) ON DELETE CASCADE,
    FOREIGN KEY (survey_id, question_no, option_no) REFERENCES survey_options(survey_id, question_no, option_no) ON DELETE CASCADE
);

