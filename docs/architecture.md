# 인프라 아키텍처

## 1. 전체 구조

본 프로젝트는 Naver Cloud Platform의 VPC 환경에서 2-tier 구조로 설계했습니다.

```text
사용자
  |
  | HTTP 80
  v
Public Application Load Balancer
  |
  | HTTP 80
  v
Web Tier
  - Apache
  - PHP
  - PHP-MySQL
  - Object Storage SDK
  |
  | MySQL 3306
  v
DB Tier
  - Cloud DB for MySQL
  - Private Subnet
```

## 2. 네트워크 구성

| 구분 | CIDR | 용도 |
|---|---:|---|
| VPC | 10.10.0.0/16 | 프로젝트 네트워크 |
| public-lb-subnet | 10.10.1.0/24 | Public Load Balancer |
| public-web-subnet | 10.10.4.0/24 | web-01, web-02 |
| private-web-subnet | 10.10.2.0/24 | Auto Scaling Web Server |
| private-db-subnet | 10.10.3.0/24 | Cloud DB for MySQL |

## 3. Load Balancer

| 항목 | 값 |
|---|---|
| 이름 | <public-application-load-balancer> |
| 유형 | Application Load Balancer |
| 네트워크 | Public |
| Listener | HTTP 80 |
| Target Group | tg-web-80 |
| Health Check | HTTP `/health.php` |
| 라우팅 방식 | Round Robin |

Load Balancer는 외부 사용자의 요청을 받아 정상 상태인 웹 서버로 분산합니다.  
웹 서버 장애 시 Health Check가 실패한 서버를 라우팅 대상에서 제외합니다.

## 4. Web Tier

| 서버 | 역할 |
|---|---|
| web-01 | 웹 애플리케이션 개발 및 기본 운영 서버 |
| web-02 | 이중화 서버 |
| asg 서버 | Auto Scaling 실습용 확장 서버 |

웹 서버에는 Apache, PHP, PHP-MySQL 모듈을 설치했습니다.  
PHP 애플리케이션은 Cloud DB와 Object Storage를 사용합니다.

## 5. DB Tier

Cloud DB for MySQL은 private-db-subnet에 배치했습니다.  
Public domain을 사용하지 않으며, 웹 서버에서만 TCP 3306으로 접근할 수 있게 제한했습니다.

```text
Web Server -> Cloud DB: TCP 3306 허용
Internet -> Cloud DB: 차단
```

## 6. Object Storage

게시글 이미지 같은 비정형 데이터는 DB에 직접 저장하지 않고 Object Storage에 저장합니다.

```text
이미지 파일 -> Object Storage
이미지 URL -> MySQL image_url 컬럼
```

이 구조는 웹 서버가 여러 대로 늘어나도 동일 이미지를 안정적으로 제공할 수 있습니다.

## 7. Auto Scaling

Auto Scaling Group은 서버 이미지 기반으로 웹 서버를 자동 생성할 수 있도록 구성했습니다.

| 항목 | 값 |
|---|---|
| Launch Configuration | <launch-configuration> |
| Image | <web-server-image> |
| 최소 용량 | 1 |
| 기대 용량 | 1 |
| 최대 용량 | 2 |
| Health Check | Load Balancer |

운영 확장 시에는 GitHub Actions, 배포 스크립트, NAS, Object Storage 등을 활용하여 새 서버에 동일 소스를 배포할 수 있습니다.
