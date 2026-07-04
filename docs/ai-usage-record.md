# AI 활용 기록

## 1. 웹 소스 생성

AI를 활용해 PHP 기반 게시판, 댓글, 축제 API 조회, 이미지 업로드 기능의 기본 코드를 생성했습니다.  
생성된 코드는 그대로 사용하지 않고 서버 환경과 DB 구조에 맞게 수정했습니다.

## 2. 프롬프트 설계

프롬프트에는 다음 조건을 명확히 포함했습니다.

- Apache + PHP + MySQL 환경
- Cloud DB 접속 방식
- 게시글/댓글 테이블 구조
- Object Storage 이미지 업로드
- 빈 입력 및 DB 오류 처리
- 로드밸런서 Health Check 확인
- 로그인 후 사용자별 좋아요/관심 축제 관리

## 3. 생성 코드 검토 및 수정

AI가 생성한 코드는 다음 기준으로 검토했습니다.

- DB 접속 정보 분리
- SQL Injection 방지를 위한 prepared statement 사용
- 비밀번호/API Key GitHub 업로드 방지
- PHP 문법 검사 `php -l` 수행
- 실제 서버에서 `curl`, `mysql`, `nc`로 동작 검증

## 4. 오류 해결 과정

| 문제 | 원인 | 해결 |
|---|---|---|
| Apache 500 오류 | `config/db.php` 누락 | config 디렉터리 및 db.php 생성 |
| DB Access denied | DB 사용자 비밀번호/host 권한 문제 | Cloud DB User Host 및 비밀번호 재확인 |
| CREATE 권한 없음 | DB User 권한이 READ/CRUD만 있음 | Cloud DB 콘솔에서 DDL 권한 부여 |
| Object Storage 업로드 실패 | Access Key 오류 | NCP API 인증키 재발급 및 storage 설정 수정 |
| Load Balancer DOWN | Health Check URL 또는 ACG 문제 | `/health.php` 생성 및 HTTP 80 허용 |
| ASG 서버 DB 접속 실패 | 10.10.2.% host 미허용 | Cloud DB User Host에 private web subnet 추가 |

## 5. 기능 개선 반복

1. 게시판 기본 기능 생성
2. 이미지 업로드 추가
3. 이미지 수정/삭제 기능 추가
4. 축제 API 연동 추가
5. 댓글/대댓글 추가
6. 좋아요/관심 있어요/다녀왔어요 상태 추가
7. 로그인 및 마이페이지 추가
8. Load Balancer와 Auto Scaling 검증

## 6. 최종 반영 내용

AI 활용 결과는 단순 복사본이 아니라, 서버 환경에서 직접 실행하며 수정한 결과물입니다.  
오류 메시지를 기반으로 원인을 분석하고, 설정과 코드를 반복 수정해 최종 기능을 완성했습니다.
