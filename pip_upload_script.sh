#!/bin/bash

# 네임스페이스 및 라벨 선택자 설정
NAMESPACE="runway"
LABEL_SELECTOR="app.kubernetes.io/instance=pypiserver,app.kubernetes.io/name=pypiserver"

# 로컬 디렉토리 및 업로드 대상 경로 설정
LOCAL_DIR="/home/donghwan/packages_to_upload"
REMOTE_DIR="/data/packages"

# 라벨에 해당하는 첫 번째 Pod 이름 추출
POD_NAME=$(kubectl get pod -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o jsonpath='{.items[0].metadata.name}')

# Pod가 없을 경우 오류 처리
if [ -z "$POD_NAME" ]; then
  echo "[ERROR] No pod found with label $LABEL_SELECTOR in namespace $NAMESPACE"
  exit 1
fi

echo "[INFO] Using Pod: $POD_NAME"

# 로컬 디렉토리의 모든 파일을 Pod 내부로 복사
kubectl cp "$LOCAL_DIR/." "$NAMESPACE/$POD_NAME:$REMOTE_DIR"

echo "[INFO] Upload complete to $POD_NAME:$REMOTE_DIR"

