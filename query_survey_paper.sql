SELECT
    m.survey_id AS 설문ID,
    m.survey_title AS 설문제목,
    q.question_no AS 번호,
    q.question_text AS 질문,

    CASE
        WHEN q.question_type = 'single' THEN '○'
        WHEN q.question_type = 'multi'  THEN '□'
        WHEN q.question_type = 'text'   THEN ' '
    END AS 선택표시,

    o.option_text AS 선택항목

FROM survey_master AS m
JOIN survey_questions AS q
    ON m.survey_id = q.survey_id
LEFT JOIN survey_options AS o
    ON q.survey_id = o.survey_id
    AND q.question_no = o.question_no

WHERE m.survey_id = 1

ORDER BY
    q.question_no,
    o.option_no;