"""
Firebase Management API로 p2bble-closet-map 프로젝트에
하루1분 Android 앱(com.p2bble.haru_1min)을 등록하고 google-services.json을 받는다.
사용법: python register_firebase_app.py
"""

import base64
import json
import os
import sys
import time

PROJECT_ID = "p2bble-closet-map"
PACKAGE_NAME = "com.p2bble.haru_1min"
DISPLAY_NAME = "haru_1min"
SERVICE_ACCOUNT_FILE = os.path.join(os.path.dirname(__file__), "service-account.json")
OUT_JSON = os.path.join(os.path.dirname(__file__), "android", "app", "google-services.json")


def main():
    from google.oauth2 import service_account
    from google.auth.transport.requests import AuthorizedSession

    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=["https://www.googleapis.com/auth/cloud-platform"],
    )
    session = AuthorizedSession(credentials)
    base = f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}"

    # 이미 등록돼 있는지 확인
    r = session.get(f"{base}/androidApps")
    if r.status_code != 200:
        print(f"[오류] 앱 목록 조회 실패 ({r.status_code}): {r.text}")
        sys.exit(1)
    apps = r.json().get("apps", [])
    app = next((a for a in apps if a.get("packageName") == PACKAGE_NAME), None)

    if app is None:
        print(f"[1/3] Android 앱 등록 중: {PACKAGE_NAME}")
        r = session.post(
            f"{base}/androidApps",
            json={"packageName": PACKAGE_NAME, "displayName": DISPLAY_NAME},
        )
        if r.status_code != 200:
            print(f"[오류] 앱 등록 실패 ({r.status_code}): {r.text}")
            sys.exit(1)
        # 등록은 비동기(operation) — 완료될 때까지 폴링
        for _ in range(30):
            time.sleep(2)
            r = session.get(f"{base}/androidApps")
            apps = r.json().get("apps", [])
            app = next((a for a in apps if a.get("packageName") == PACKAGE_NAME), None)
            if app:
                break
        if app is None:
            print("[오류] 등록 완료 확인 실패 — 잠시 후 다시 실행해보세요.")
            sys.exit(1)
    else:
        print(f"[1/3] 이미 등록된 앱 발견: {app['appId']}")

    app_id = app["appId"]
    print(f"      appId: {app_id}")

    # google-services.json 다운로드
    print("[2/3] google-services.json 다운로드...")
    r = session.get(f"{base}/androidApps/{app_id}/config")
    if r.status_code != 200:
        print(f"[오류] 설정 다운로드 실패 ({r.status_code}): {r.text}")
        sys.exit(1)
    cfg = r.json()
    content = base64.b64decode(cfg["configFileContents"]).decode("utf-8")
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"      저장: {OUT_JSON}")

    # firebase_options.dart 용 값 출력
    print("[3/3] firebase_options.dart 값:")
    data = json.loads(content)
    client = next(
        c for c in data["client"]
        if c["client_info"]["android_client_info"]["package_name"] == PACKAGE_NAME
    )
    print(f"      apiKey: {client['api_key'][0]['current_key']}")
    print(f"      appId: {client['client_info']['mobilesdk_app_id']}")
    print(f"      messagingSenderId: {data['project_info']['project_number']}")
    print(f"      projectId: {data['project_info']['project_id']}")
    print(f"      storageBucket: {data['project_info'].get('storage_bucket', '')}")


if __name__ == "__main__":
    main()
