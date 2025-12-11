
# 이질적 데이터가 혼재된 계층적 FANET 환경을 위한 시맨틱 인식형 SARSA 기반 적응형 DRR 스케줄링 기법

## 2. 시스템 모델
### 2.2. 데드라인 산출 공식
$$ D(p) = T_{min} + (T_{max} - T_{min}) \times \frac{p}{7} $$

## 3. 제안 방법
### 3.3. 보상 함수 (Reward Function)
$$ R_t = \alpha \cdot \text{PDR}_{high} - \beta \cdot \text{Cost}_{age} + \gamma \cdot \log(1 + \text{Thru}_{low}) $$
