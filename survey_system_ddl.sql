PRAGMA foreign_keys = ON;

-- 1. 기사 기본정보
CREATE TABLE drivers (
    driver_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    phone           TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    shift_day       TEXT NOT NULL CHECK (shift_day IN ('월','화','수','목','금','토','일')),
    off_day         TEXT NOT NULL CHECK (off_day IN ('월','화','수','목','금','토','일')),
    childcare_day   TEXT CHECK (
        childcare_day IS NULL OR childcare_day IN ('월','화','수','목','금','토','일')
    ),
    created_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
    version         INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 활성 설문은 동시에 하나만 허용
CREATE UNIQUE INDEX ux_survey_master_active
ON survey_master(is_active)
WHERE is_active = 1;

-- 3. 설문 문항
CREATE TABLE survey_questions (
    question_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    question_text   TEXT NOT NULL,
    question_type   TEXT NOT NULL CHECK (question_type IN ('single','multi','text')),
    is_required     INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0,1)),
    created_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (survey_id) REFERENCES survey_master(survey_id) ON DELETE CASCADE,
    UNIQUE (survey_id, question_no)
);

CREATE INDEX idx_questions_survey
ON survey_questions(survey_id, question_no);

-- 4. 문항 선택지
CREATE TABLE survey_options (
    option_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id     INTEGER NOT NULL,
    option_no       INTEGER NOT NULL,
    option_text     TEXT NOT NULL,
    FOREIGN KEY (question_id) REFERENCES survey_questions(question_id) ON DELETE CASCADE,
    UNIQUE (question_id, option_no)
);

CREATE INDEX idx_options_question
ON survey_options(question_id, option_no);

-- 5. 설문 응답
CREATE TABLE survey_responses (
    response_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_id       INTEGER NOT NULL,
    driver_id       INTEGER NOT NULL,
    started_at      TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at    TEXT,
    status          TEXT NOT NULL DEFAULT 'in_progress'
                    CHECK (status IN ('in_progress','completed')),
    FOREIGN KEY (survey_id) REFERENCES survey_master(survey_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE,
    UNIQUE (survey_id, driver_id)
);

CREATE INDEX idx_responses_driver ON survey_responses(driver_id);
CREATE INDEX idx_responses_survey ON survey_responses(survey_id);

-- 6. 설문 답변
CREATE TABLE survey_answers (
    answer_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    response_id     INTEGER NOT NULL,
    question_id     INTEGER NOT NULL,
    option_id       INTEGER,
    answer_text     TEXT,
    FOREIGN KEY (response_id) REFERENCES survey_responses(response_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES survey_questions(question_id) ON DELETE CASCADE,
    FOREIGN KEY (option_id) REFERENCES survey_options(option_id) ON DELETE CASCADE
);

CREATE INDEX idx_answers_response ON survey_answers(response_id);
CREATE INDEX idx_answers_question ON survey_answers(question_id);
CREATE INDEX idx_answers_option ON survey_answers(option_id);
