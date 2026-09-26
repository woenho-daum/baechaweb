"""baechaweb 패키지 초기화.

기존에 이미 이 파일이 있고 아래와 동일하게 auth/entry/survey 를
export 하고 있다면 그대로 두셔도 됩니다. admin_auth, survey_admin 은
서브모듈이라 main.py에서 `from baechaweb import admin_auth, survey_admin`
형태로 바로 가져올 수 있어 여기서 별도로 적어줄 필요는 없습니다.
"""
from .baechaweb import auth, entry, get_db, survey  # noqa: F401
