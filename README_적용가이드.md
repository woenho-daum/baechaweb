# 설문 관리 기능 추가 - 적용 가이드

## 0. 적용 전 필수 작업

- **DB 백업**: `sqlite/survey.db` 파일을 복사해 두세요. (`cp sqlite/survey.db sqlite/survey.db.bak`)
- `pip install -r requirements.txt` 에 Flask, PyJWT 가 이미 있다는 전제입니다. 추가 설치 패키지는 없습니다.

## 1. 파일 반영 방법

아래 파일들은 **새 파일**입니다. 프로젝트에 그대로 추가하세요.

- `baechaweb/admin_auth.py`
- `baechaweb/survey_admin.py`
- `baechaweb/migrate_001_survey_admin.py`
- `templates/admin/*.html` (7개)

아래 파일들은 **기존 파일을 대체**합니다. diff를 확인하고 덮어쓰세요.

- `baechaweb/baechaweb.py` (변경점: `get_db()`에 `PRAGMA foreign_keys = ON` 추가, `entry()`가 `survey_id=1` 하드코딩 대신 `status=1`인 설문을 조회하도록 변경)
- `baechaweb/main.py` (변경점: `app.secret_key` 추가, `/admin/...` 라우트 전부 추가)

`baechaweb/__init__.py`는 이미 프로젝트에 존재할 가능성이 높습니다. 제가 드린 내용은 참고용이며,
**이미 `auth, entry, survey` 를 export 하고 있다면 그대로 두셔도 됩니다.**
(`admin_auth`, `survey_admin`은 서브모듈이라 `__init__.py` 수정 없이도 바로 import됩니다.)

⚠️ **확인 필요**: 기존 `templates/baechaweb.html`이 `survey.is_active` 를 참조하고 있다면
`survey.status`로 바꿔주세요. (컬럼명이 `is_active` → `status`로 변경되었습니다.)

## 2. DB 마이그레이션 실행

```bash
cd baechaweb
python migrate_001_survey_admin.py
```

여러 번 실행해도 안전하지만(이미 적용된 항목은 건너뜀), 실행 전 반드시 0번의 백업을 먼저 하세요.

## 3. 관리자 비밀번호 / 세션 키 설정

기본값은 개발용 placeholder이므로 실제 사용 전 환경변수로 반드시 교체하세요.

```bash
export BAECHAWEB_ADMIN_PASSWORD="원하는-관리자-비밀번호"
export BAECHAWEB_FLASK_SECRET="무작위-긴-문자열"
```

(Windows PowerShell: `$env:BAECHAWEB_ADMIN_PASSWORD="..."`)

## 4. 실행 및 확인

```bash
python main.py
```

- 관리자 화면 진입: `http://localhost:5000/admin/login`
- 로그인 후 `http://localhost:5000/admin/surveys` 에서 설문 목록 확인
- 기존 기사용 화면(`/`, `/baechaweb`, `/baechaweb/auth`, `/baechaweb/survey`)은 동작 그대로입니다.

## 5. 새 관리자 메뉴 구조 (구현된 라우트)

```
/admin/login, /admin/logout                         로그인/로그아웃
/admin/surveys                                       설문 목록
/admin/surveys/new  (GET)  /admin/surveys (POST)     새 설문 생성
/admin/surveys/<id>/edit (GET) /admin/surveys/<id> (POST)  기본정보 수정
/admin/surveys/<id>/delete (POST)                    설문 삭제(확인창 포함)
/admin/surveys/<id>/questions (GET/POST)             문항 목록/추가
/admin/surveys/<id>/questions/<no> (POST)            문항 수정
/admin/surveys/<id>/questions/<no>/delete (POST)     문항 삭제
/admin/surveys/<id>/questions/reorder (POST)         문항 순서 일괄 저장
/admin/surveys/<id>/questions/<no>/options (POST)          선택지 추가
/admin/surveys/<id>/questions/<no>/options/<no> (POST)     선택지 수정
/admin/surveys/<id>/questions/<no>/options/<no>/delete (POST)  선택지 삭제
/admin/surveys/<id>/questions/<no>/options/reorder (POST)  선택지 순서 일괄 저장
/admin/surveys/<id>/preview                          미리보기
/admin/surveys/<id>/responses                        응답 조회
```

## 6. DB 변경사항 요약

| 테이블 | 변경 | 이유 |
|---|---|---|
| survey_master | `is_active` → `status` 이름 변경 | 의미를 명확히 하고, 신규 관리자 화면과 통일 |
| survey_master | `survey_subtitle`, `created_at`, `updated_at` 추가 | 부제목/이력 관리 |
| survey_questions | `sort_order` 추가 (기존 `question_no`는 그대로 유지) | `question_no`는 `survey_answers`가 참조하므로 값 자체를 바꾸면 위험. 화면 표시 순서만 별도 컬럼으로 분리해 안전하게 재정렬 |
| survey_options | `sort_order` 추가 (기존 `option_no`는 그대로 유지) | 위와 동일한 이유 |

`survey_answers` 등 응답 관련 테이블 구조는 전혀 변경하지 않았습니다 (요구사항대로).

## 7. 주의 / 알아두면 좋은 점

- 설문을 `status=1`(진행중)으로 저장하면, 현재 등록된 전체 `drivers`가 자동으로 `drivers_survey_link`에 연결됩니다(이미 연결된 기사는 건너뜀 → 기존 응답 보존).
- `status=1`은 동시에 하나만 가능합니다(부분 유니크 인덱스). 새 설문을 진행중으로 저장하면 기존에 진행중이던 설문은 자동으로 "관리중(마감)"(2)으로 내려갑니다.
- 삭제는 CASCADE로 질문/선택지/대상자연결/응답까지 함께 삭제됩니다. 화면에서 확인창을 거치도록 이미 구현되어 있습니다.
- 관리자 인증은 간단한 비밀번호+세션 방식입니다. 계정별 로그인, 권한 분리 등이 필요해지면 별도로 확장이 필요합니다.
