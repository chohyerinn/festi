# festi! 인프라 구축 프로젝트

## 시연 영상

![festi demo](docs/images/festi-demo.gif)

Naver Cloud Platform 기반으로 구축한 축제/공연 커뮤니티 웹 서비스입니다.  
웹 애플리케이션은 Apache + PHP로 동작하고, 데이터는 Cloud DB for MySQL에 저장됩니다. 사용자는 Public Application Load Balancer를 통해 접속하며, 웹 서버는 사설 네트워크로 DB와 통신합니다.

## 1. 프로젝트 목표

- 공인 주소로 접속 가능한 PHP 웹 서비스 구축
- 게시글, 댓글, 좋아요, 관심 축제, 방문 상태 등 사용자 기능 구현
- 공공데이터포털 TourAPI 기반 축제/공연 데이터 연동
- Object Storage를 활용한 이미지 업로드 구조 구성
- Load Balancer와 Auto Scaling을 활용한 확장 가능한 웹 서버 구조 설계
- Cloud DB for MySQL을 private subnet에 배치하여 DB 직접 노출 방지

## 2. 주요 기능

| 기능 | 설명 |
|---|---|
| 축제/공연 목록 | 공공데이터 API로 수집한 축제 데이터를 웹에서 조회 |
| 축제 상세 | 상세 정보, 댓글, 좋아요, 관심 있어요, 다녀왔어요 상태 관리 |
| 커뮤니티 게시판 | 글 작성, 조회, 수정, 삭제 |
| 댓글/대댓글 | 게시글 및 축제 상세에서 댓글 작성 |
| 이미지 업로드 | 게시글 이미지를 Object Storage에 저장하고 DB에는 URL 저장 |
| 로그인 | 사용자별 댓글, 좋아요, 관심 축제 기록 관리 |
| 마이페이지 | 사용자가 누른 좋아요, 관심 축제, 작성 글/댓글 확인 |

## 3. 인프라 구조

![festi infrastructure architecture](docs/images/festi-infra-architecture.png)`n`n```text
Users
  |
  | HTTP 80
  v
Public Application Load Balancer
  - <public-application-load-balancer>
  - Listener: HTTP 80
  - Target Group: tg-web-80
  - Health Check: /health.php
  |
  | HTTP 80
  v
Web Servers
  - web-01
  - web-02
  - Auto Scaling Group 생성 서버
  - Apache + PHP
  |
  | MySQL 3306
  v
Cloud DB for MySQL
  - <cloud-db-instance>
  - private-db-subnet
  - public domain 미사용

Object Storage
  - 게시글 이미지 저장
  - MySQL에는 image_url만 저장
```

## 4. NCP 리소스 구성

| 구분 | 이름/값 | 설명 |
|---|---|---|
| VPC | project, 10.10.0.0/16 | 프로젝트 전용 네트워크 |
| Public LB Subnet | 10.10.1.0/24 | Public Load Balancer 배치 |
| Public Web Subnet | 10.10.4.0/24 | web-01, web-02 배치 |
| Private Web Subnet | 10.10.2.0/24 | Auto Scaling 서버 배치 실습 |
| Private DB Subnet | 10.10.3.0/24 | Cloud DB for MySQL 배치 |
| Load Balancer | <public-application-load-balancer> | 외부 접속 단일 진입점 |
| Target Group | tg-web-80 | web 서버 health check 및 라우팅 |
| Cloud DB | <cloud-db-instance> | MySQL 8.4.8 |
| Object Storage | <object-storage-bucket> | 업로드 이미지 저장 |

## 5. 보안 설계

- 사용자는 Load Balancer로만 웹 서비스에 접근합니다.
- Cloud DB는 private subnet에 배치하고 public domain을 사용하지 않습니다.
- 웹 서버에서 Cloud DB로 TCP 3306만 허용합니다.
- SSH 22번 포트는 관리자 IP만 허용합니다.
- DB 접속 정보와 Object Storage 인증키는 GitHub에 올리지 않습니다.
- GitHub에는 `config/*.masked.php` 또는 예시 설정만 포함합니다.

## 6. 검증 결과

### Apache/PHP 확인

```bash
apache2 -v
php -v
curl -I http://localhost/
curl http://localhost/health.php
```

### Cloud DB 연결 확인

```bash
php -r 'require "/var/www/html/config/db.php"; echo "PDO OK\n";'
nc -vz <cloud-db-private-domain> 3306
mysql -h <cloud-db-private-domain> -u <db_user> -p <database_name>
```

### Load Balancer Health Check

```text
Target Group: tg-web-80
Health Check URL: /health.php
Expected:
- web-01: UP / HTTP 200
- web-02: UP / HTTP 200
- Auto Scaling 서버: UP / HTTP 200 확인
```

### 부하 테스트

```bash
ab -n 1000 -c 50 http://<public-lb-domain>/
```

확인한 결과:

```text
Complete requests: 1000
Failed requests: 0
Requests per second: 168.69
```

## 7. Auto Scaling 설계

Auto Scaling은 웹 서버 수를 부하 상황에 따라 늘릴 수 있도록 구성했습니다.

| 항목 | 값 |
|---|---|
| Launch Configuration | <launch-configuration> |
| Server Image | <web-server-image> |
| Auto Scaling Group | <auto-scaling-group> |
| 최소/기대/최대 용량 | 1 / 1 / 2 |
| Health Check | Load Balancer |
| Scale Out | 서버 1대 추가 |
| Scale In | 서버 1대 반납 |
| Cooldown | 300초 |

실제 운영에서는 GitHub 또는 배포 스크립트를 사용해 새로 생성되는 서버에도 동일한 소스를 배포하는 구조로 확장할 수 있습니다.

## 8. AI 활용 기록 요약

본 프로젝트에서는 AI를 단순 코드 생성 용도로만 사용하지 않고, 오류 해결과 기능 개선 과정에 반복적으로 활용했습니다.

- Apache 500 오류 원인 분석
- PHP `require_once` 경로 오류 해결
- Cloud DB 접속 권한 오류 해결
- MySQL DDL 권한 문제 해결
- Object Storage 이미지 업로드 오류 해결
- Load Balancer Health Check 문제 해결
- Auto Scaling 서버와 Target Group 연결 구조 검토
- UI 개선 및 사용자 기능 반복 개선

자세한 기록은 [docs/ai-usage-record.md](docs/ai-usage-record.md)를 참고합니다.

## 9. 디렉터리 구조

```text
.
├── README.md
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   ├── ai-usage-record.md
│   └── troubleshooting.md
├── sql/
│   └── schema.sql
├── scripts/
│   └── verify-server.sh
└── .gitignore
```

## 10. 주의

이 저장소에는 실제 운영 비밀번호, API 인증키, Object Storage Access Key/Secret Key를 포함하지 않습니다.


