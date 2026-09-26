"""
설문 관리자 기능 추가를 위한 DB 마이그레이션 스크립트.

- 기존 데이터(drivers, 기존 응답 등)는 전혀 삭제/변경하지 않습니다.
- 컬럼 추가 / 컬럼명 변경만 수행하며, 이미 적용된 항목은 건너뜁니다(여러 번 실행해도 안전).

실행 방법:
    cd baechaweb
    python migrate_001_survey_admin.py
"""
import sqlite3

DB_PATH = "./sqlite/survey.db"


def column_exists(conn, table, column):
    rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    return any(r["name"] == column for r in rows)


def main():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = OFF")  # 마이그레이션 중에는 잠시 끔

    try:
        conn.execute("BEGIN")

        # 1. survey_master: is_active -> status 컬럼명 변경
        if column_exists(conn, "survey_master", "is_active") and not column_exists(
            conn, "survey_master", "status"
        ):
            # 부분 유니크 인덱스가 걸려 있으므로 먼저 인덱스를 지운 뒤 리네임
            conn.execute("DROP INDEX IF EXISTS ux_survey_master_active")
            conn.execute("ALTER TABLE survey_master RENAME COLUMN is_active TO status")
            conn.execute(
                """
                CREATE UNIQUE INDEX ux_survey_master_active
                ON survey_master(status)
                WHERE status = 1
                """
            )
            print("[OK] survey_master.is_active -> status 로 변경")
        else:
            print("[SKIP] survey_master.status 이미 존재하거나 변경 불필요")

        # 2. survey_master: 부제목 / 타임스탬프 추가
        if not column_exists(conn, "survey_master", "survey_subtitle"):
            conn.execute("ALTER TABLE survey_master ADD COLUMN survey_subtitle TEXT")
            print("[OK] survey_master.survey_subtitle 추가")

        if not column_exists(conn, "survey_master", "created_at"):
            conn.execute("ALTER TABLE survey_master ADD COLUMN created_at DATETIME")
            conn.execute(
                "UPDATE survey_master SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL"
            )
            print("[OK] survey_master.created_at 추가")

        if not column_exists(conn, "survey_master", "updated_at"):
            conn.execute("ALTER TABLE survey_master ADD COLUMN updated_at DATETIME")
            print("[OK] survey_master.updated_at 추가")

        # 3. survey_questions: 표시 순서 컬럼 추가
        #    (question_no 자체는 survey_answers 가 참조하므로 그대로 유지합니다)
        if not column_exists(conn, "survey_questions", "sort_order"):
            conn.execute("ALTER TABLE survey_questions ADD COLUMN sort_order INTEGER")
            conn.execute(
                "UPDATE survey_questions SET sort_order = question_no * 10 WHERE sort_order IS NULL"
            )
            print("[OK] survey_questions.sort_order 추가")

        # 4. survey_options: 표시 순서 컬럼 추가
        if not column_exists(conn, "survey_options", "sort_order"):
            conn.execute("ALTER TABLE survey_options ADD COLUMN sort_order INTEGER")
            conn.execute(
                "UPDATE survey_options SET sort_order = option_no * 10 WHERE sort_order IS NULL"
            )
            print("[OK] survey_options.sort_order 추가")

        conn.commit()
        print("\n마이그레이션 완료.")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
