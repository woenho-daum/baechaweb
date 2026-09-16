WITH
/* =========================================================
   1. 설문 기본정보
   ========================================================= */
survey_info AS (
    SELECT
        survey_id,
        survey_title,
        COALESCE(description, '') AS description
    FROM survey_master
    WHERE survey_id = 1
),

/* =========================================================
   2. 각 질문을 HTML로 생성
   ========================================================= */
question_blocks AS (
    SELECT
        q.survey_id,
        q.question_no,

        '<div class="question">' ||
        '<div class="question-title">' ||
        q.question_no || '. ' ||
        q.question_text ||
        CASE
            WHEN q.is_required = 1
            THEN ' <span class="required">*</span>'
            ELSE ''
        END ||
        '</div>' ||

        CASE

            /* ---------- 단일선택 ---------- */
            WHEN q.question_type = 'single' THEN
                COALESCE(
                    (
                        SELECT GROUP_CONCAT(
                            '<div class="option">' ||
                            '<span class="option-mark">○</span>' ||
                            '<span class="option-text">' ||
                            o.option_text ||
                            '</span>' ||
                            '</div>',
                            ''
                        )
                        FROM survey_options o
                        WHERE o.survey_id = q.survey_id
                          AND o.question_no = q.question_no
                        ORDER BY o.option_no
                    ),
                    ''
                )

            /* ---------- 복수선택 ---------- */
            WHEN q.question_type = 'multi' THEN
                COALESCE(
                    (
                        SELECT GROUP_CONCAT(
                            '<div class="option">' ||
                            '<span class="option-mark">□</span>' ||
                            '<span class="option-text">' ||
                            o.option_text ||
                            '</span>' ||
                            '</div>',
                            ''
                        )
                        FROM survey_options o
                        WHERE o.survey_id = q.survey_id
                          AND o.question_no = q.question_no
                        ORDER BY o.option_no
                    ),
                    ''
                )

            /* ---------- 자유입력 ---------- */
            WHEN q.question_type = 'text' THEN
                '<div class="text-answer">' ||
                '<div class="text-line"></div>' ||
                '<div class="text-line"></div>' ||
                '<div class="text-line"></div>' ||
                '</div>'

            ELSE ''

        END ||

        '</div>' AS html

    FROM survey_questions q
    WHERE q.survey_id = 1
),

/* =========================================================
   3. 질문들을 순서대로 하나로 연결
   ========================================================= */
all_questions AS (
    SELECT
        survey_id,
        GROUP_CONCAT(
            html,
            ''
        ) AS html
    FROM question_blocks
    GROUP BY survey_id
)

/* =========================================================
   4. 최종 HTML 문서
   ========================================================= */
SELECT

    '<!DOCTYPE html>' ||

    '<html lang="ko">' ||

    '<head>' ||

    '<meta charset="UTF-8">' ||

    '<meta name="viewport" content="width=device-width, initial-scale=1.0">' ||

    '<title>' ||
    survey_info.survey_title ||
    '</title>' ||

    '<style>'

    /* ---------- 기본 ---------- */
    || 'body{' ||
        'margin:0;' ||
        'padding:20px;' ||
        'background:#f5f6f8;' ||
        'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Noto Sans KR",sans-serif;' ||
        'color:#222;' ||
    '}'

    /* ---------- 문서 ---------- */
    || '.survey{' ||
        'max-width:700px;' ||
        'margin:0 auto;' ||
        'background:#fff;' ||
        'padding:24px;' ||
        'border-radius:16px;' ||
        'box-sizing:border-box;' ||
    '}'

    /* ---------- 질문 ---------- */
    || '.question{' ||
        'margin-top:28px;' ||
    '}'

    || '.question:first-child{' ||
        'margin-top:20px;' ||
    '}'

    || '.question-title{' ||
        'font-size:18px;' ||
        'font-weight:700;' ||
        'line-height:1.5;' ||
        'margin-bottom:12px;' ||
    '}'

    || '.required{' ||
        'color:#e53935;' ||
    '}'

    /* ---------- 선택항목 ---------- */
    || '.option{' ||
        'display:flex;' ||
        'align-items:flex-start;' ||
        'gap:8px;' ||
        'padding:6px 0;' ||
        'font-size:16px;' ||
        'line-height:1.5;' ||
    '}'

    || '.option-mark{' ||
        'width:22px;' ||
        'flex-shrink:0;' ||
    '}'

    || '.option-text{' ||
        'flex:1;' ||
    '}'

    /* ---------- 자유입력 ---------- */
    || '.text-answer{' ||
        'margin-top:10px;' ||
    '}'

    || '.text-line{' ||
        'height:32px;' ||
        'border-bottom:1px solid #aaa;' ||
        'margin-bottom:8px;' ||
    '}'

    || '</style>' ||

    '</head>' ||

    '<body>' ||

    '<div class="survey">'

    /* =====================================================
       제목
       ===================================================== */
    || '<h1>' ||
       survey_info.survey_title ||
       '</h1>'

    /* =====================================================
       설문 취지 / 안내
       description에 저장된 HTML
       ===================================================== */
    || survey_info.description

    /* =====================================================
       질문 1~7
       ===================================================== */
    || COALESCE(all_questions.html, '')

    || '</div>'

    || '</body>'

    || '</html>'

    AS html_document

FROM survey_info

LEFT JOIN all_questions
    ON survey_info.survey_id = all_questions.survey_id;