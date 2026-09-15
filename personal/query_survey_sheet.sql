WITH base AS (
    SELECT
        m.survey_id,
        m.survey_title,
        m.description,
        m.is_active,

        q.question_no,
        q.question_text,
        q.question_type,
        q.is_required,

        o.option_no,
        o.option_text,

        ROW_NUMBER() OVER (
            PARTITION BY m.survey_id
            ORDER BY q.question_no, o.option_no
        ) AS survey_rn,

        ROW_NUMBER() OVER (
            PARTITION BY m.survey_id, q.question_no
            ORDER BY o.option_no
        ) AS question_rn

    FROM survey_master AS m

    LEFT JOIN survey_questions AS q
        ON m.survey_id = q.survey_id

    LEFT JOIN survey_options AS o
        ON q.survey_id = o.survey_id
        AND q.question_no = o.question_no

    WHERE m.survey_id = 1
)

SELECT

    -- 설문 Master
    CASE
        WHEN survey_rn = 1 THEN survey_id
    END AS 설문ID,

    CASE
        WHEN survey_rn = 1 THEN survey_title
    END AS 설문제목,

    CASE
        WHEN survey_rn = 1 THEN description
    END AS 설명,

    CASE
        WHEN survey_rn = 1 THEN
            CASE
                WHEN is_active = 1 THEN '활성'
                ELSE '비활성'
            END
    END AS 상태,

    -- 질문
    CASE
        WHEN question_rn = 1 THEN question_no
    END AS 질문번호,

    CASE
        WHEN question_rn = 1 THEN question_text
    END AS 질문내용,

    CASE
        WHEN question_rn = 1 THEN
            CASE
                WHEN question_type = 'single' THEN '단일선택'
                WHEN question_type = 'multi'  THEN '복수선택'
                WHEN question_type = 'text'   THEN '주관식'
                ELSE question_type
            END
    END AS 질문유형,

    CASE
        WHEN question_rn = 1 THEN
            CASE
                WHEN is_required = 1 THEN '필수'
                ELSE '선택'
            END
    END AS 필수여부,

    -- 옵션
    option_no AS 옵션번호,
    option_text AS 옵션내용

FROM base

ORDER BY
    question_no,
    option_no;