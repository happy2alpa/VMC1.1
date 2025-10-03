# 블로그 체험단 SaaS — 데이터베이스 설계

## 1. 데이터플로우 요약

### 1.1 회원가입 및 약관 동의
- Supabase Auth 계정 생성 후 `app_users`에 기본 정보(이메일, 이름, 휴대폰, 역할, 인증 방식) 저장
- `terms_acceptances`에 약관 버전과 동의 시각 기록, 이메일 검증 상태 갱신

### 1.2 인플루언서 정보 등록
- `influencer_profiles`에 생년월일 저장, 나이 정책 검증
- SNS 채널 추가·수정·삭제 시 `influencer_channels`에 유형, 채널명, URL, 검증 상태 기록

### 1.3 광고주 정보 등록
- `advertiser_profiles`에 업체명, 위치, 카테고리, 사업자등록번호, 검증 상태 저장

### 1.4 홈 및 체험단 목록 탐색
- `campaigns`에서 모집 상태가 `모집중`인 레코드를 정렬·페이징하여 리스트, 배너 데이터를 구성

### 1.5 체험단 상세 조회
- `campaigns`에서 모집 기간, 제공 혜택, 미션, 매장 정보, 모집 인원 조회
- 인플루언서 프로필 완료 여부와 중복 지원 여부 검사

### 1.6 체험단 지원
- 중복 지원 및 모집 기간 내 여부 확인
- `applications`에 각오 한마디, 방문 예정 일자, 초기 상태 `신청완료` 저장

### 1.7 내 지원 목록
- 로그인 인플루언서의 `applications`를 상태(신청완료/선정/반려) 필터로 조회해 목록 표시

### 1.8 광고주 체험단 관리
- 광고주가 `campaigns`에 신규 체험단 생성(초기 상태 `모집중`)
- 모집 종료 시 `campaigns.recruit_status`를 `모집종료`로 갱신, 선정 단계에서 선택된 `applications`를 `선정`, 나머지를 `반려`로 갱신

## 2. 데이터베이스 스키마 상세

### 2.1 테이블 정의

#### app_users
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| id | uuid | PK, Supabase Auth 연동 | 사용자 식별자 |
| email | text | UNIQUE, NOT NULL | 로그인 이메일 |
| phone | text | NOT NULL | 휴대폰 번호 |
| full_name | text | NOT NULL | 사용자 이름 |
| role | text | CHECK(role IN ('advertiser','influencer')), NOT NULL | 역할 |
| auth_method | text | CHECK(auth_method IN ('email','external')), NOT NULL | 인증 방식 |
| email_verified | boolean | DEFAULT false | 이메일 검증 여부 |
| created_at | timestamptz | DEFAULT NOW() | 생성 시각 |

#### terms_acceptances
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| id | bigserial | PK | 동의 레코드 식별자 |
| user_id | uuid | FK → app_users(id), NOT NULL | 사용자 참조 |
| terms_version | text | NOT NULL | 약관 버전 |
| consented_at | timestamptz | DEFAULT NOW(), NOT NULL | 동의 시각 |
| created_at | timestamptz | DEFAULT NOW() | 레코드 생성 시각 |

> (user_id, terms_version) UNIQUE 제약으로 중복 동의 방지

#### advertiser_profiles
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| user_id | uuid | PK, FK → app_users(id) | 광고주 사용자 FK |
| company_name | text | NOT NULL | 업체명 |
| location | text | NOT NULL | 위치 |
| category | text | NOT NULL | 카테고리 |
| business_registration_no | text | UNIQUE, NOT NULL | 사업자등록번호 |
| verification_status | text | CHECK(verification_status IN ('성공','검증대기','실패')), DEFAULT '검증대기' | 검증 상태 |
| created_at | timestamptz | DEFAULT NOW() | 레코드 생성 시각 |
| updated_at | timestamptz | DEFAULT NOW() | 업데이트 시각 |

#### influencer_profiles
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| user_id | uuid | PK, FK → app_users(id) | 인플루언서 사용자 FK |
| birth_date | date | NOT NULL | 생년월일 |
| created_at | timestamptz | DEFAULT NOW() | 레코드 생성 시각 |
| updated_at | timestamptz | DEFAULT NOW() | 업데이트 시각 |

#### influencer_channels
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| id | bigserial | PK | 채널 식별자 |
| influencer_id | uuid | FK → influencer_profiles(user_id), NOT NULL | 인플루언서 FK |
| channel_type | text | CHECK(channel_type IN ('Naver','YouTube','Instagram','Threads')), NOT NULL | 채널 유형 |
| channel_name | text | NOT NULL | 채널명 |
| channel_url | text | NOT NULL | 채널 URL |
| verification_status | text | CHECK(verification_status IN ('검증대기','검증성공','검증실패')), DEFAULT '검증대기' | 검증 상태 |
| created_at | timestamptz | DEFAULT NOW() | 레코드 생성 시각 |
| updated_at | timestamptz | DEFAULT NOW() | 업데이트 시각 |

> (influencer_id, channel_url) UNIQUE 제약으로 채널 중복 저장 방지

#### campaigns
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| id | bigserial | PK | 체험단 식별자 |
| advertiser_id | uuid | FK → advertiser_profiles(user_id), NOT NULL | 광고주 FK |
| title | text | NOT NULL | 체험단명 |
| recruit_start_date | date | NOT NULL | 모집 시작일 |
| recruit_end_date | date | NOT NULL | 모집 종료일 |
| benefits | text | NOT NULL | 제공 혜택 |
| mission | text | NOT NULL | 미션 |
| store_info | text | NOT NULL | 매장 정보 |
| max_participants | integer | CHECK(max_participants > 0), NOT NULL | 모집 인원 |
| recruit_status | text | CHECK(recruit_status IN ('모집중','모집종료','선정완료')), DEFAULT '모집중' | 모집 상태 |
| created_at | timestamptz | DEFAULT NOW() | 레코드 생성 시각 |
| updated_at | timestamptz | DEFAULT NOW() | 업데이트 시각 |

> CHECK(recruit_start_date <= recruit_end_date) 제약으로 모집 기간 유효성 보장

#### applications
| 컬럼 | 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| id | bigserial | PK | 지원 식별자 |
| campaign_id | bigint | FK → campaigns(id), NOT NULL | 체험단 FK |
| influencer_id | uuid | FK → influencer_profiles(user_id), NOT NULL | 인플루언서 FK |
| motivation | text | NOT NULL | 각오 한마디 |
| planned_visit_date | date | NOT NULL | 방문 예정 일자 |
| status | text | CHECK(status IN ('신청완료','선정','반려')), DEFAULT '신청완료' | 지원 상태 |
| created_at | timestamptz | DEFAULT NOW() | 레코드 생성 시각 |
| updated_at | timestamptz | DEFAULT NOW() | 업데이트 시각 |

> UNIQUE(campaign_id, influencer_id) 제약으로 중복 지원 차단

### 2.2 상태 전이 규칙
- `campaigns.recruit_status`: `모집중` → `모집종료` → `선정완료`
- `applications.status`: 초기 `신청완료`; 선정 시 `선정`, 미선정 시 `반려`

### 2.3 트리거 및 권장 로직
- 모든 테이블에 `updated_at` 자동 갱신 트리거 적용 권장
- `applications.planned_visit_date`가 모집 기간 내에 있는지 검증하는 도메인 트리거 고려

## 3. 관계 개요
- `app_users` 1:N `terms_acceptances`
- `app_users` 1:1 `advertiser_profiles`
- `app_users` 1:1 `influencer_profiles`
- `influencer_profiles` 1:N `influencer_channels`
- `advertiser_profiles` 1:N `campaigns`
- `influencer_profiles` 1:N `applications`
- `campaigns` 1:N `applications`

## 4. 운영 시사점
- 모집 종료와 선정 처리는 트랜잭션으로 묶어 상태 일관성 보장
- 채널 검증·사업자 검증은 백그라운드 잡 혹은 외부 API 연동으로 확장 가능
- 리뷰/리포트 등 향후 기능 확장을 위한 별도 테이블 추가 용이


## 5. ER 다이어그램
```mermaid
erDiagram
    app_users {
        uuid id PK
        text email
        text phone
        text full_name
        text role
        text auth_method
        boolean email_verified
    }
    terms_acceptances {
        bigserial id PK
        uuid user_id FK
        text terms_version
        timestamptz consented_at
    }
    advertiser_profiles {
        uuid user_id PK FK
        text company_name
        text location
        text category
        text business_registration_no
        text verification_status
    }
    influencer_profiles {
        uuid user_id PK FK
        date birth_date
    }
    influencer_channels {
        bigserial id PK
        uuid influencer_id FK
        text channel_type
        text channel_name
        text channel_url
        text verification_status
    }
    campaigns {
        bigserial id PK
        uuid advertiser_id FK
        text title
        date recruit_start_date
        date recruit_end_date
        text benefits
        text mission
        text store_info
        integer max_participants
        text recruit_status
    }
    applications {
        bigserial id PK
        bigint campaign_id FK
        uuid influencer_id FK
        text motivation
        date planned_visit_date
        text status
    }

    app_users ||--o{ terms_acceptances : "동의"
    app_users ||--|| advertiser_profiles : "광고주 프로필"
    app_users ||--|| influencer_profiles : "인플루언서 프로필"
    influencer_profiles ||--o{ influencer_channels : "채널"
    advertiser_profiles ||--o{ campaigns : "체험단"
    influencer_profiles ||--o{ applications : "지원"
    campaigns ||--o{ applications : "신청"
```
