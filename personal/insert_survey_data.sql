-- ============================================================
-- 휴무일 대체근무 연락 등록 시스템
-- 설문 DB 전체 초기화 + 기본 조사표 생성
--
-- 주의:
-- 1. drivers 테이블과 기사 데이터는 삭제하지 않음
-- 2. 기존 설문/응답 데이터는 모두 삭제됨
-- 3. 최초 조사표를 survey_id = 1 로 생성
-- ============================================================


-- ============================================================
-- 0. 외래키 일시 해제
-- ============================================================

PRAGMA foreign_keys = OFF;


-- ============================================================
-- 1. 기존 설문 데이터 삭제
--    자식 테이블부터 삭제
-- ============================================================

DROP TABLE IF EXISTS survey_answers;
DROP TABLE IF EXISTS survey_options;
DROP TABLE IF EXISTS survey_questions;
DROP TABLE IF EXISTS drivers_survey_link;
DROP TABLE IF EXISTS survey_master;


-- ============================================================
-- 2. 기존 인덱스 제거
-- ============================================================

DROP INDEX IF EXISTS ux_survey_master_active;
DROP INDEX IF EXISTS idx_sdl_survey_id;
DROP INDEX IF EXISTS idx_questions_survey;


-- ============================================================
-- 3. 설문 마스터
-- ============================================================

CREATE TABLE survey_master (
    survey_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    survey_title    TEXT NOT NULL,
    description     TEXT,
    is_active       INTEGER NOT NULL DEFAULT 0
                    CHECK (is_active IN (0,1))
);


-- 활성 조사표는 동시에 하나만 허용
CREATE UNIQUE INDEX ux_survey_master_active
ON survey_master(is_active)
WHERE is_active = 1;


-- ============================================================
-- 4. 기사 ↔ 조사표 연결
-- ============================================================

CREATE TABLE drivers_survey_link (
    driver_name     TEXT NOT NULL,
    survey_id       INTEGER NOT NULL,
    completed       INTEGER NOT NULL DEFAULT 0
                    CHECK (completed IN (0,1)),
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (driver_name, survey_id),

    FOREIGN KEY (driver_name)
        REFERENCES drivers(name)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (survey_id)
        REFERENCES survey_master(survey_id)
        ON DELETE CASCADE
);


CREATE INDEX idx_sdl_survey_id
ON drivers_survey_link(survey_id);


-- ============================================================
-- 5. 설문 문항
-- ============================================================

CREATE TABLE survey_questions (
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,
    question_text   TEXT NOT NULL,

    -- single : 하나 선택
    -- multi  : 여러 개 선택
    -- text   : 직접 입력
    question_type   TEXT NOT NULL
                    CHECK (question_type IN ('single','multi','text')),

    is_required     INTEGER NOT NULL DEFAULT 1
                    CHECK (is_required IN (0,1)),

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

    PRIMARY KEY (
        survey_id,
        question_no,
        option_no
    ),

    FOREIGN KEY (
        survey_id,
        question_no
    )
        REFERENCES survey_questions(
            survey_id,
            question_no
        )
        ON DELETE CASCADE
);


-- ============================================================
-- 7. 설문 답변
-- ============================================================

CREATE TABLE survey_answers (
    driver_name     TEXT NOT NULL,
    survey_id       INTEGER NOT NULL,
    question_no     INTEGER NOT NULL,

    -- single / multi 질문에서 사용
    option_no       INTEGER,

    -- text 질문에서 사용
    answer_text     TEXT,

    PRIMARY KEY (
        driver_name,
        survey_id,
        question_no,
        option_no
    ),

    FOREIGN KEY (driver_name)
        REFERENCES drivers(name)
        ON DELETE CASCADE,

    FOREIGN KEY (
        survey_id,
        question_no
    )
        REFERENCES survey_questions(
            survey_id,
            question_no
        )
        ON DELETE CASCADE,

    FOREIGN KEY (
        survey_id,
        question_no,
        option_no
    )
        REFERENCES survey_options(
            survey_id,
            question_no,
            option_no
        )
        ON DELETE CASCADE
);


-- ============================================================
-- 8. 조사표 생성
-- ============================================================

INSERT INTO survey_master (
    survey_id,
    survey_title,
    description,
    is_active
)
VALUES (
    1,
    '휴무일 대체근무 연락 등록',
    '휴무일 대체근무 가능 여부와 연락방법 등의 선호사항을 등록합니다.',
    1
);


-- ============================================================
-- 9. 조사 문항 등록
-- ============================================================

INSERT INTO survey_questions
(
    survey_id,
    question_no,
    question_text,
    question_type,
    is_required
)
VALUES
(
    1,
    1,
    '휴무일에 대체근무 연락을 받아볼 의향이 있습니까?',
    'single',
    1
),
(
    1,
    2,
    '한 달에 대체근무를 어느 정도 하고 싶습니까?',
    'single',
    1
),
(
    1,
    3,
    '대체근무 요청은 언제까지 연락받는 것이 좋습니까?',
    'multi',
    1
),
(
    1,
    4,
    '대체근무 연락은 어떤 방법을 선호합니까?',
    'multi',
    1
),
(
    1,
    5,
    '대체근무 시 특별히 선호하는 조건이 있습니까?',
    'multi',
    1
),
(
    1,
    6,
    '추가로 전달하고 싶은 내용이 있습니까?',
    'text',
    0
);


-- ============================================================
-- 10. 문항 1 선택지
-- ============================================================

INSERT INTO survey_options
(
    survey_id,
    question_no,
    option_no,
    option_text
)
VALUES
(1, 1, 1, '적극적으로 근무하고 싶음'),
(1, 1, 2, '가능하면 근무하고 싶음'),
(1, 1, 3, '연락을 받아보고 결정'),
(1, 1, 4, '가급적 휴무하고 싶음'),
(1, 1, 5, '휴무일에는 연락을 원하지 않음');


-- ============================================================
-- 11. 문항 2 선택지
-- ============================================================

INSERT INTO survey_options
(
    survey_id,
    question_no,
    option_no,
    option_text
)
VALUES
(1, 2, 1, '가능한 만큼 많이'),
(1, 2, 2, '월 3~4회'),
(1, 2, 3, '월 1~2회'),
(1, 2, 4, '가끔'),
(1, 2, 5, '그때그때 결정');


-- ============================================================
-- 12. 문항 3 선택지
-- ============================================================

INSERT INTO survey_options
(
    survey_id,
    question_no,
    option_no,
    option_text
)
VALUES
(1, 3, 1, '3일 전'),
(1, 3, 2, '2일 전'),
(1, 3, 3, '전날'),
(1, 3, 4, '당일'),
(1, 3, 5, '갑작스러운 연락도 가능');


-- ============================================================
-- 13. 문항 4 선택지
-- ============================================================

INSERT INTO survey_options
(
    survey_id,
    question_no,
    option_no,
    option_text
)
VALUES
(1, 4, 1, '전화'),
(1, 4, 2, '문자'),
(1, 4, 3, '카카오톡'),
(1, 4, 4, '상관없음');


-- ============================================================
-- 14. 문항 5 선택지
-- ============================================================

INSERT INTO survey_options
(
    survey_id,
    question_no,
    option_no,
    option_text
)
VALUES
(1, 5, 1, '특별한 조건 없음'),
(1, 5, 2, '오전 근무 선호'),
(1, 5, 3, '오후 근무 선호'),
(1, 5, 4, '특정 조건이 있음');


-- ============================================================
-- 15. 현재 등록된 모든 기사를 조사표에 연결
-- ============================================================

INSERT INTO drivers_survey_link
(
    driver_name,
    survey_id,
    completed
)
SELECT
    name,
    1,
    0
FROM drivers;


-- ============================================================
-- 16. 외래키 다시 활성화
-- ============================================================

PRAGMA foreign_keys = ON;


-- ============================================================
-- 17. 정상적으로 생성되었는지 확인
-- ============================================================

SELECT
    survey_id,
    survey_title,
    description,
    is_active
FROM survey_master;


SELECT
    survey_id,
    question_no,
    question_text,
    question_type,
    is_required
FROM survey_questions
ORDER BY survey_id, question_no;


SELECT
    survey_id,
    question_no,
    option_no,
    option_text
FROM survey_options
ORDER BY survey_id, question_no, option_no;


SELECT
    COUNT(*) AS total_drivers
FROM drivers_survey_link
WHERE survey_id = 1;


-- ============================================================
-- 끝
-- ============================================================