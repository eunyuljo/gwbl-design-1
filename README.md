# GWLB with Appliance VPC — Terraform

CloudFormation 4개 스택(GWLB VPC + Consumer VPC x3)을 단일 Terraform 구성으로 마이그레이션한 코드입니다.

## Architecture

```
                     ┌──────────────────────────────┐
                     │    GWLB VPC (10.254.0.0/16)  │
                     │                              │
                     │  Appliance x4 → GWLB → TG   │
                     │         VPC Endpoint Service  │
                     └──────────────┬───────────────┘
                 ┌──────────────────┼──────────────────┐
                 │                  │                   │
        ┌────────┴───┐    ┌────────┴───┐    ┌──────────┴─┐
        │   VPC01    │    │   VPC02    │    │   VPC03    │
        │10.1.0.0/16 │    │10.2.0.0/16 │    │10.3.0.0/16 │
        │            │    │            │    │            │
        │ GWLB EP x2 │    │ GWLB EP x2 │    │ GWLB EP x2 │
        │ Private x4 │    │ Private x4 │    │ Private x4 │
        │ SSM EP x2  │    │ SSM EP x2  │    │ SSM EP x2  │
        └────────────┘    └────────────┘    └────────────┘
```

### Traffic Flow

- **Outbound**: Private EC2 → GWLB Endpoint → GWLB → Appliance(검사) → GWLB → GWLB Endpoint → IGW → Internet
- **Inbound**: Internet → IGW → (IGW Ingress RT) → GWLB Endpoint → GWLB → Appliance(검사) → GWLB → GWLB Endpoint → Private EC2

## File Structure

```
├── versions.tf          # Provider / Terraform 버전
├── variables.tf         # 공통 변수 (region, AZ, instance_type, tags)
├── locals.tf            # VPC별 차이값 map (CIDR, IP 등)
├── data.tf              # AMI SSM parameter, region
├── vpc.tf               # GWLB VPC + Consumer VPC x3 (terraform-aws-modules/vpc/aws ~> 6.6)
├── gwlb.tf              # GWLB, Target Group, Listener, Endpoint Service
├── endpoints.tf         # GWLB Endpoints, IGW Ingress RT, SSM Interface Endpoints
├── iam.tf               # Appliance IAM + Consumer SSM IAM
├── security_groups.tf   # Appliance SG, Private EC2 SG, SSM SG (terraform-aws-modules/security-group/aws ~> 5.3)
├── ec2.tf               # Appliance x4 + Private x12 instances
├── outputs.tf           # 전체 outputs
└── scripts/
    ├── appliance_userdata.sh   # Appliance: httpd + iptables hairpin
    └── webserver_userdata.sh   # Webserver: httpd + ec2meta-webpage
```

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS credentials configured (`aws configure` or environment variables)

## Usage

```bash
# 초기화
terraform init

# 변경사항 확인
terraform plan

# 배포
terraform apply

# 삭제
terraform destroy
```

## Configuration

모든 VPC별 설정값은 `locals.tf`에서 관리합니다.

### GWLB VPC

| Item | Value |
|---|---|
| VPC CIDR | 10.254.0.0/16 |
| Public Subnet A | 10.254.11.0/24 (ap-northeast-2a) |
| Public Subnet B | 10.254.12.0/24 (ap-northeast-2b) |
| Appliance Instances | 4 (2 per AZ) |

### Consumer VPCs

| Item | VPC01 | VPC02 | VPC03 |
|---|---|---|---|
| VPC CIDR | 10.1.0.0/16 | 10.2.0.0/16 | 10.3.0.0/16 |
| Public Subnets | 10.1.11-12.0/24 | 10.2.11-12.0/24 | 10.3.11-12.0/24 |
| Private Subnets | 10.1.21-22.0/24 | 10.2.21-22.0/24 | 10.3.21-22.0/24 |
| Private Instances | 4 (2 per AZ) | 4 (2 per AZ) | 4 (2 per AZ) |

### Variables

| Variable | Default | Description |
|---|---|---|
| `aws_region` | ap-northeast-2 | AWS region |
| `availability_zones` | [ap-northeast-2a, 2b] | AZ list |
| `instance_type` | t3.small | EC2 instance type |
| `common_tags` | Environment=lab, ManagedBy=terraform | Common tags |

## Modules Used

| Module | Version | Source |
|---|---|---|
| VPC | ~> 6.6 | terraform-aws-modules/vpc/aws |
| Security Group | ~> 5.3 | terraform-aws-modules/security-group/aws |

GWLB, VPC Endpoint Service, GWLB Endpoint 등 공식 모듈이 없는 리소스는 raw resource를 사용합니다.

## Improvements over Original CFN

- **단일 구성**: 4개 CFN 스택 → 1개 Terraform 디렉토리
- **중복 제거**: Consumer VPC 3개 → `for_each` + `locals` map
- **EBS 암호화**: `encrypted = true` 추가
- **IAM 정책**: deprecated `AmazonEC2RoleforSSM` → `AmazonSSMManagedInstanceCore`
- **IMDSv2**: UserData에서 token 기반 메타데이터 접근
