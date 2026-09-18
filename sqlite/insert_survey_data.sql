BEGIN TRANSACTION;

-- =========================================================
-- 기존 설문 데이터 삭제
-- ※ drivers 테이블의 기사 기본정보는 삭제하지 않습니다.
-- =========================================================

DELETE FROM survey_answers;
DELETE FROM drivers_survey_link;
DELETE FROM survey_options;
DELETE FROM survey_questions;
DELETE FROM survey_master;


-- =========================================================
-- 1. 설문 기본정보
-- =========================================================

INSERT INTO survey_master (
    survey_id,
    survey_title,
    description,
    is_active
)
VALUES (
    1,
    '휴무일 대체근무',
'
<div class="survey-intro">

    <div class="intro-header">
        <div class="intro-title-area">
            <div class="intro-title">
                대체근무 연락을 위한 사전 의향 확인
            </div>
        </div>
    </div>

    <div class="intro-purpose">
        <p>
            기사님들의 휴무일 대체근무 의향을 미리 파악하여,
            배차표 작성 과정에서 근무 공백이 발생할 경우
            먼저 연락드리기 위한 것입니다.
        </p>
    </div>

    <div class="notice-box">
        <div class="notice-title">
            꼭 확인해 주십시오
        </div>

        <div class="notice-item">
            <span class="notice-mark">✓</span>
            <span>응답은 전혀 강제되지 않습니다.</span>
        </div>

        <div class="notice-item">
            <span class="notice-mark">✓</span>
            <span>응답하지 않으셔도 아무런 불이익이 없습니다.</span>
        </div>

        <div class="notice-item">
            <span class="notice-mark">✓</span>
            <span>
                응답하지 않은 경우 대체근무를 원하지 않으시는
                것으로 이해할 수 있습니다.
            </span>
        </div>
    </div>

    <div class="privacy-box">
        <p> </p>
        <div class="privacy-title">
            🔒 응답 내용 관리
        </div>
        <p> </p>
        <p>
            본 시스템은 박원호 배차원 개인적으로 구축한 웹시스템입니다.
        </p>

        <p>
            입력하신 자료는 대체근무 연락을 위한 목적으로 직접 관리하며,
            응답 내용의 비밀을 최대한 보장합니다.
        </p>

        <p>
            본인이 원하면 언제든지 즉시 파기합니다. (직접 박원호 배차원에게 요청)
        </p>

        <p>
            기본적으로 설문은 한 번만 응할수 있으며, 
            본인이 원하면 언제든지 설문을 다시 진행하여 의사를 변경할 수 있습니다.
            (직접 박원호 배차원에게 요청)
        </p>
    </div>

    <div class="guide-box">
        <div class="guide-title">
            ✏️ 응답 방법
        </div>
        <p> </p>
        <p>
            질문에 따라 <strong>하나만 선택하는 항목</strong>과
            <strong>여러 개를 선택할 수 있는 항목</strong>이 있습니다.
        </p>

    </div>

</div>
',
    1
);


-- =========================================================
-- 2. 질문 등록
-- =========================================================

INSERT INTO survey_questions
    (survey_id, question_no, question_text, question_type, is_required)
VALUES

    (1, 1,
     '휴무일 대체근무 의향',
     'single', 1),

    (1, 2,
     '월 대체근무 희망 횟수',
     'single', 1),

    (1, 3,
     '평시 연락 가능한 시점',
     'single', 1),

    (1, 4,
     '긴급 대체근무(당일·전날) 가능 여부',
     'single', 1),

    (1, 5,
     '선호 연락방법',
     'multi', 1),

    (1, 6,
     '특별한 근무조건',
     'multi', 1),

    (1, 7,
     '추가 전달사항',
     'text', 0);


-- =========================================================
-- 3. 질문 1 선택지
-- =========================================================

INSERT INTO survey_options
    (survey_id, question_no, option_no, option_text)
VALUES
    (1, 1, 1, '적극적으로 근무하고 싶음'),
    (1, 1, 2, '가능하면 근무하고 싶음'),
    (1, 1, 3, '연락을 받아보고 결정'),
    (1, 1, 4, '가급적 휴무하고 싶음'),
    (1, 1, 5, '휴무일에는 연락을 원하지 않음');


-- =========================================================
-- 4. 질문 2 선택지
-- =========================================================

INSERT INTO survey_options
    (survey_id, question_no, option_no, option_text)
VALUES
    (1, 2, 1, '가능한 만큼 많이'),
    (1, 2, 2, '월 3~4회'),
    (1, 2, 3, '월 1~2회'),
    (1, 2, 4, '가끔'),
    (1, 2, 5, '그때그때 결정');


-- =========================================================
-- 5. 질문 3 선택지
-- =========================================================

INSERT INTO survey_options
    (survey_id, question_no, option_no, option_text)
VALUES
    (1, 3, 1, '최소 3일 전 연락 필요'),
    (1, 3, 2, '최소 2일 전 연락 필요'),
    (1, 3, 3, '전날 연락도 가능'),
    (1, 3, 4, '당일 급구 연락도 가능');


-- =========================================================
-- 6. 질문 4 선택지
-- =========================================================

INSERT INTO survey_options
    (survey_id, question_no, option_no, option_text)
VALUES
    (1, 4, 1, '가능'),
    (1, 4, 2, '상황에 따라 가능'),
    (1, 4, 3, '불가능');


-- =========================================================
-- 7. 질문 5 선택지
-- =========================================================

INSERT INTO survey_options
    (survey_id, question_no, option_no, option_text)
VALUES
    (1, 5, 1, '전화'),
    (1, 5, 2, '문자'),
    (1, 5, 3, '카카오톡'),
    (1, 5, 4, '상관없음');


-- =========================================================
-- 8. 질문 6 선택지
-- =========================================================

INSERT INTO survey_options
    (survey_id, question_no, option_no, option_text)
VALUES
    (1, 6, 1, '특별한 조건 없음'),
    (1, 6, 2, '오전 근무 선호'),
    (1, 6, 3, '오후 근무 선호'),
    (1, 6, 4, '특정 조건이 있음 (7번에 작성)');


-- =========================================================
-- 9. 현재 등록된 모든 기사에게 설문 연결
-- =========================================================

INSERT INTO drivers_survey_link (
    driver_name,
    survey_id,
    completed
)
SELECT
    name,
    1,
    0
FROM drivers;


-- =========================================================
-- 10. 최종 저장
-- =========================================================

COMMIT;

SELECT
    q.question_no AS 번호,
    q.question_text AS 질문,
    q.question_type AS 유형,
    o.option_no AS 선택번호,
    o.option_text AS 선택항목,
    CASE
        WHEN q.question_type = 'single' THEN '○'
        WHEN q.question_type = 'multi' THEN '□'
        ELSE ''
    END AS 선택표시
FROM survey_questions q
LEFT JOIN survey_options o
    ON q.survey_id = o.survey_id
   AND q.question_no = o.question_no
WHERE q.survey_id = 1
ORDER BY q.question_no, o.option_no;