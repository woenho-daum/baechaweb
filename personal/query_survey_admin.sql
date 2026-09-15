-- ============================================================
-- 전체 조사 결과 조회
-- 기사 1명 = 1행
-- ============================================================

WITH answer_summary AS (
    SELECT
        a.driver_name,
        a.survey_id,
        a.question_no,

        GROUP_CONCAT(o.option_text, ', ') AS selected_options,

        MAX(a.answer_text) AS answer_text

    FROM survey_answers AS a

    LEFT JOIN survey_options AS o
        ON a.survey_id = o.survey_id
        AND a.question_no = o.question_no
        AND a.option_no = o.option_no

    WHERE a.survey_id = 1

    GROUP BY
        a.driver_name,
        a.survey_id,
        a.question_no
)

SELECT
    d.name AS 기사명,
    d.phone AS 전화번호,
    d.shift_day AS 근무요일,
    d.off_day AS 휴무요일,

    d.childcare_day AS 자녀돌봄요일,
    d.childcare_start AS 자녀돌봄시작일,
    d.childcare_end AS 자녀돌봄종료일,

    CASE
        WHEN l.completed = 1 THEN '완료'
        ELSE '미완료'
    END AS 조사상태,

    l.created_at AS 등록일,

    q1.selected_options AS 대체근무의향,
    q2.selected_options AS 월희망횟수,
    q3.selected_options AS 연락가능시점,
    q4.selected_options AS 선호연락방법,
    q5.selected_options AS 선호근무조건,
    q6.answer_text AS 추가전달사항

FROM drivers AS d

LEFT JOIN drivers_survey_link AS l
    ON d.name = l.driver_name
    AND l.survey_id = 1

LEFT JOIN answer_summary AS q1
    ON d.name = q1.driver_name
    AND q1.survey_id = 1
    AND q1.question_no = 1

LEFT JOIN answer_summary AS q2
    ON d.name = q2.driver_name
    AND q2.survey_id = 1
    AND q2.question_no = 2

LEFT JOIN answer_summary AS q3
    ON d.name = q3.driver_name
    AND q3.survey_id = 1
    AND q3.question_no = 3

LEFT JOIN answer_summary AS q4
    ON d.name = q4.driver_name
    AND q4.survey_id = 1
    AND q4.question_no = 4

LEFT JOIN answer_summary AS q5
    ON d.name = q5.driver_name
    AND q5.survey_id = 1
    AND q5.question_no = 5

LEFT JOIN answer_summary AS q6
    ON d.name = q6.driver_name
    AND q6.survey_id = 1
    AND q6.question_no = 6

ORDER BY
    d.off_day,
    d.name;