# pip_upload_script

쿠버네티스 클러스터에서 실행 중인 `pypiserver` Pod 내부로 로컬의 패키지 파일들을 일괄 업로드하는 간단한 Bash 스크립트입니다.

## 개요
- `kubectl cp`를 사용해 로컬 디렉토리(`LOCAL_DIR`)의 모든 파일을 지정한 네임스페이스/라벨의 첫 번째 Pod로 복사합니다.
- 대상 Pod와 경로는 스크립트 내 변수를 통해 제어합니다(`NAMESPACE`, `LABEL_SELECTOR`, `REMOTE_DIR`).

## 전제 조건
- `kubectl` 설치 및 클러스터 컨텍스트/권한이 정상 구성되어 있어야 합니다.
- 업로드 대상 Pod가 다음 조건을 만족해야 합니다.
  - 네임스페이스: `NAMESPACE` (기본값: `runway`)
  - 라벨 셀렉터: `LABEL_SELECTOR` (기본값: `app.kubernetes.io/instance=pypiserver,app.kubernetes.io/name=pypiserver`)
  - 업로드 경로: `REMOTE_DIR` (기본값: `/data/packages`)
- 로컬 업로드 소스 디렉토리: `LOCAL_DIR` (기본값: `/home/donghwan/packages_to_upload`)

## 파일 구성
- `pip_upload_script.sh`: 업로드 수행 스크립트

## 설정
`pip_upload_script.sh` 상단의 변수를 환경에 맞게 수정하세요.
- `NAMESPACE`: 대상 네임스페이스
- `LABEL_SELECTOR`: 대상 Pod를 찾기 위한 라벨 쿼리
- `LOCAL_DIR`: 업로드할 파일들이 있는 로컬 디렉토리 경로
- `REMOTE_DIR`: Pod 내부 업로드 대상 디렉토리 경로

필요 시 라벨 셀렉터는 `kubectl get pods -n <ns> --show-labels`로 확인 후 조정하세요.

## 사용 방법
1) 실행 권한 부여
```
chmod +x pip_upload_script.sh
```

2) 업로드 실행
```
./pip_upload_script.sh
```

실행 시, 라벨 셀렉터에 해당하는 첫 번째 Pod 이름을 자동으로 조회하여 `LOCAL_DIR`의 모든 파일을 `REMOTE_DIR`로 복사합니다.

## 동작 설명
- Pod 조회: `kubectl get pod -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o jsonpath='{.items[0].metadata.name}'`
- 복사: `kubectl cp "$LOCAL_DIR/." "$NAMESPACE/$POD_NAME:$REMOTE_DIR"`
- Pod가 없을 경우 에러를 출력하고 종료합니다.

## 참고 및 주의사항
- 동일 파일명이 이미 존재하면 덮어쓸 수 있습니다. 운영 환경에서 주의하세요.
- `LOCAL_DIR`가 비어 있으면 아무 파일도 업로드되지 않습니다.
- 다수의 Pod가 라벨에 매칭될 경우 첫 번째 항목만 사용합니다. 필요 시 더 엄격한 라벨을 사용하거나 스크립트를 확장하세요.
- 네트워크/권한 이슈로 `kubectl cp`가 실패할 수 있습니다. `kubectl auth can-i` 명령 등으로 권한을 점검하세요.

## 문제 해결(Troubleshooting)
- "No pod found" 오류: 네임스페이스/라벨이 올바른지 확인하세요.
- Permission denied: Pod 내부 경로 쓰기 권한 및 `kubectl` RBAC 권한을 확인하세요.
- 타임아웃/네트워크 오류: 컨텍스트/네트워크 연결 상태를 확인하세요.

