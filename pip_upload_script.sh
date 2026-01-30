#!/bin/bash

# 네임스페이스 및 라벨 선택자 설정
NAMESPACE="runway"
LABEL_SELECTOR="app.kubernetes.io/instance=pypiserver,app.kubernetes.io/name=pypiserver"
REMOTE_DIR="/data/packages"

# SOURCE_DIR: 인자로 지정하거나, /root/pip_runway_download의 최신 날짜 디렉토리 자동 감지
if [ -n "$1" ]; then
  LOCAL_DIR="$1"
else
  BASE_DIR="/root/pip_runway_download"
  LOCAL_DIR=$(ls -1d "$BASE_DIR"/*/ 2>/dev/null | sort -r | head -1)
  LOCAL_DIR="${LOCAL_DIR%/}"  # 후행 슬래시 제거
  if [ -z "$LOCAL_DIR" ] || [ ! -d "$LOCAL_DIR" ]; then
    echo "[ERROR] No subdirectory found in $BASE_DIR"
    exit 1
  fi
  echo "[INFO] Auto-detected source directory: $LOCAL_DIR"
fi

if [ ! -d "$LOCAL_DIR" ]; then
  echo "[ERROR] Directory not found: $LOCAL_DIR"
  exit 1
fi

# 로그 파일 설정
LOG_FILE="/root/pip_upload_script/upload_$(date +%Y%m%d_%H%M%S).log"
log() {
  echo "$1" | tee -a "$LOG_FILE"
}

# 라벨에 해당하는 첫 번째 Pod 이름 추출
POD_NAME=$(kubectl get pod -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
  log "[ERROR] No pod found with label $LABEL_SELECTOR in namespace $NAMESPACE"
  exit 1
fi

log "[INFO] Using Pod: $POD_NAME"
log "[INFO] Source: $LOCAL_DIR"
log "[INFO] Destination: $POD_NAME:$REMOTE_DIR"

# Pod에 존재하는 파일 목록 조회 (중복 스킵용)
log "[INFO] Fetching existing files from pod..."
EXISTING_FILES=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- ls "$REMOTE_DIR" 2>/dev/null)

# 로컬 파일 목록
LOCAL_FILES=("$LOCAL_DIR"/*)
TOTAL=${#LOCAL_FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
  log "[INFO] No files to upload."
  exit 0
fi

# 카운터
SUCCESS=0
SKIPPED=0
FAILED=0
FAILED_LIST=()

log "[INFO] Starting upload of $TOTAL files..."
log "---"

for i in "${!LOCAL_FILES[@]}"; do
  FILE="${LOCAL_FILES[$i]}"
  BASENAME=$(basename "$FILE")
  NUM=$((i + 1))

  # 중복 스킵
  if echo "$EXISTING_FILES" | grep -qx "$BASENAME"; then
    log "[$NUM/$TOTAL] SKIP (exists): $BASENAME"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # 파일 업로드
  if kubectl cp "$FILE" "$NAMESPACE/$POD_NAME:$REMOTE_DIR/$BASENAME"; then
    log "[$NUM/$TOTAL] OK: $BASENAME"
    SUCCESS=$((SUCCESS + 1))
  else
    log "[$NUM/$TOTAL] FAIL: $BASENAME"
    FAILED=$((FAILED + 1))
    FAILED_LIST+=("$BASENAME")
  fi
done

# 요약 리포트
log "---"
log "[SUMMARY]"
log "  Total:   $TOTAL"
log "  Success: $SUCCESS"
log "  Skipped: $SKIPPED"
log "  Failed:  $FAILED"

if [ ${#FAILED_LIST[@]} -gt 0 ]; then
  log "[FAILED FILES]"
  for f in "${FAILED_LIST[@]}"; do
    log "  - $f"
  done
fi

log "[INFO] Log saved to $LOG_FILE"
