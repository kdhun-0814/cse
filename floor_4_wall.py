import math
import json

# ==========================================
# 1. 데이터 입력 (주신 데이터 변환)
# ==========================================

# 3D 높이 설정 (Z축) - 벽 높이의 중간값
Z_HEIGHT = 15

# 좌표값 도우미 (Vector라는 글자를 튜플로 인식하게 함)
def Vector(v):
    return (v[0], v[1]) # x, y만 사용

# 1-1. 외벽 데이터 (Polygon Points)
outer_wall_points = [
    Vector((-200.0, -200.0, 0.0)), Vector((-300.0, -100.0, 0.0)),
    Vector((-200.0, 0.0, 0.0)), Vector((-250.0, 50.0, 0.0)), 
    Vector((-100.0, 200.0, 0.0)), Vector((300.0, 200.0, 0.0)),
    Vector((300.0, 0.0, 0.0)), Vector((0.0, 0.0, 0.0)),
    Vector((-200.0, -200.0, 0.0)) # 닫힌 도형을 위해 시작점 반복
]

# 1-2. 내벽 데이터 (Line Segments)
inner_walls_raw = [
    [Vector((-240.0, -160.0, 0)), Vector((-140.0, -60.0, 0))],
    [Vector((-45.0, 35.0, 0)), Vector((-30.0, 50.0, 0))],
    [Vector((-45.0, 35.0, 0)), Vector((-30.0, 20.0, 0))],
    [Vector((-15.0, 20.0, 0)), Vector((-30.0, 20.0, 0))],
    [Vector((-15.0, 20.0, 0)), Vector((-15.0, -5.0, 0))],
    [Vector((-10.0, -10.0, 0)), Vector((-15.0, -5.0, 0))],
    [Vector((-55.0, -55.0, 0)), Vector((-80.0, -30.0, 0))],
    [Vector((-40.0, 10.0, 0)), Vector((-125.0, -75.0, 0))],
    [Vector((-40.0, 10.0, 0)), Vector((-15.0, 10.0, 0))],
    [Vector((-40.0, 10.0, 0)), Vector((-55.0, 25.0, 0))],
    [Vector((-120.0, -40.0, 0)), Vector((-55.0, 25.0, 0))],
    [Vector((-105.0, -55.0, 0)), Vector((-120.0, -40.0, 0))],
    [Vector((-70.0, -20.0, 0)), Vector((-85.0, -5.0, 0))],
    [Vector((300.0, 50.0, 0)), Vector((-30.0, 50.0, 0))],
    [Vector((-260.0, -140.0, 0)), Vector((-160.0, -40.0, 0))],
    [Vector((-140.0, -20.0, 0)), Vector((-50.0, 70.0, 0))],
    [Vector((300.0, 70.0, 0)), Vector((160.0, 70.0, 0))],
    [Vector((140.0, 70.0, 0)), Vector((-30.0, 70.0, 0))],
    [Vector((-160.0, -40.0, 0)), Vector((-200.0, 0.0, 0))],
    [Vector((-140.0, -20.0, 0)), Vector((-180.0, 20.0, 0))],
    [Vector((-80.0, 120.0, 0)), Vector((-180.0, 20.0, 0))],
    [Vector((-80.0, 120.0, 0)), Vector((-50.0, 120.0, 0))],
    [Vector((-50.0, 70.0, 0)), Vector((-50.0, 120.0, 0))],
    [Vector((-30.0, 70.0, 0)), Vector((-30.0, 120.0, 0))],
    [Vector((140, 120.0, 0)), Vector((-30.0, 120.0, 0))],
    [Vector((140, 120.0, 0)), Vector((140.0, 70.0, 0))],
    [Vector((160.0, 120.0, 0)), Vector((160.0, 70.0, 0))],
    [Vector((160.0, 120.0, 0)), Vector((300.0, 120.0, 0))],
    [Vector((-80.0, 140.0, 0)), Vector((-210.0, 10.0, 0))],
    [Vector((-80.0, 140.0, 0)), Vector((250.0, 140.0, 0))],
    [Vector((250.0, 200.0, 0)), Vector((250.0, 140.0, 0))],
    [Vector((260.0, 170.0, 0)), Vector((260.0, 120.0, 0))],
    [Vector((260.0, 145.0, 0)), Vector((300.0, 145.0, 0))],
    [Vector((-50.0, 200.0, 0)), Vector((-50.0, 140.0, 0))],
    [Vector((100.0, 200.0, 0)), Vector((100.0, 140.0, 0))],
    [Vector((-140.0, 160.0, 0)), Vector((-100.0, 120.0, 0))],
    [Vector((-140.0, -60.0, 0)), Vector((-100.0, -100.0, 0))],
    [Vector((-160.0, -80.0, 0)), Vector((-120.0, -120.0, 0))],
    [Vector((170.0, 50.0, 0)), Vector((170.0, 0.0, 0))],
    [Vector((130.0, 50.0, 0)), Vector((130.0, 0.0, 0))],
    [Vector((100.0, 50.0, 0)), Vector((100.0, 0.0, 0))],
    [Vector((70.0, 50.0, 0)), Vector((70.0, 0.0, 0))],
    [Vector((20.0, 50.0, 0)), Vector((20.0, 0.0, 0))],
    [Vector((250.0, 170.0, 0)), Vector((300.0, 170.0, 0))],
]

# 1-3. 방 데이터 (이름: 좌표)
rooms = {
    "401": (60, 95), "402": (225, 95), "403": (235, 25), "405": (175, 170),
    "406": (25, 170), "408": (-170, 90), "409": (-230, -70), "410": (-180, -140),
    "계단_1": (-130, -90), "화장실(남)": (-45, -20), "화장실(여)": (-90, -65),
    "장애인화장실(남)": (-65, 0), "장애인화장실(여)": (-95, -30),
    "EV": (45, 25), "화물EV": (85, 25), "계단_2": (115, 25), "계단_3": (275, 185),
    "화장실2(남)": (280, 155), "화장실2(여)": (280, 135)
}

# 1-4. [중요] 경로 설정
EV_START = (45.0, 25.0)    # EV 중심
GATEWAY_NODE = (45.0, 60.0) # ★ 지정하신 특정 좌표 (진입로)

# 복도 뼈대 노드 (자동 연결을 돕기 위해 주요 지점 수동 추가)
# 팁: 방들이 모여있는 곳 근처의 빈 공간 좌표들입니다.
hallway_nodes = [
    (45, 60),     # GATEWAY와 동일 (연결점)
    (-36,60), #1차 꺽임
    (-58.81,40.38),
    (-35.52,16),
    (-27.9512,15.06),
    (-139.7,-39.96),
    (-194.5,15.93),
    (-76.24,130.8),
    (-40,130),
    (150,130),
    (254.2,131),
    (254.2,157),
    (-200.225,-98.44),
    (-205,-106.9),
    (-145.9,65.14),
    (24.92,131),
    (60,60),
    (-75.88,20),
    (-109.7,-12.12),
    (-139,-39.28),
    (-123,-56.18),
    (225.3,61),
    (235,61),
    (150,60),
    (175,130)
          
]

# ==========================================
# 2. 벽 데이터 통합 (충돌 체크용)
# ==========================================
all_walls = []

# 외벽을 선분으로 변환 (점 -> 선)
for i in range(len(outer_wall_points) - 1):
    all_walls.append([outer_wall_points[i], outer_wall_points[i+1]])

# 내벽 추가
all_walls.extend(inner_walls_raw)

# ==========================================
# 3. 알고리즘 (선분 교차 판별)
# ==========================================
def ccw(p1, p2, p3):
    val = (p2[0] - p1[0]) * (p3[1] - p1[1]) - (p2[1] - p1[1]) * (p3[0] - p1[0])
    if val > 0: return 1
    elif val < 0: return -1
    else: return 0

def is_intersect(p1, p2, p3, p4):
    res1 = ccw(p1, p2, p3) * ccw(p1, p2, p4)
    res2 = ccw(p3, p4, p1) * ccw(p3, p4, p2)
    
    if res1 == 0 and res2 == 0:
        if p1 > p2: p1, p2 = p2, p1
        if p3 > p4: p3, p4 = p4, p3
        return not (p2 < p3 or p4 < p1)
    
    return res1 <= 0 and res2 <= 0

def check_path_clear(start, end, walls):
    # 시작점과 끝점이 너무 가까우면(같은 점이면) True
    if math.dist(start, end) < 1.0: return True
    
    for w_start, w_end in walls:
        if is_intersect(start, end, w_start, w_end):
            return False 
    return True

# ==========================================
# 4. 노드 및 엣지 생성 로직
# ==========================================
nodes = []
edges = []
node_id_counter = 0

# --- [Stage 1] EV -> Gateway 강제 연결 ---
# 1. EV Node
nodes.append({"id": node_id_counter, "type": "start", "name": "EV", "x": EV_START[0], "y": EV_START[1], "z": Z_HEIGHT})
ev_id = node_id_counter
node_id_counter += 1

# 2. Gateway Node (지정 좌표 45, 65)
nodes.append({"id": node_id_counter, "type": "gateway", "name": "GATEWAY", "x": GATEWAY_NODE[0], "y": GATEWAY_NODE[1], "z": Z_HEIGHT})
gateway_id = node_id_counter
node_id_counter += 1

# 3. 강제 연결 (벽 검사 없이)
edges.append({"from": ev_id, "to": gateway_id})


# --- [Stage 2] 복도 노드 생성 및 연결 ---
hallway_ids = [gateway_id] # 게이트웨이도 복도의 일부로 포함

for i, h_pos in enumerate(hallway_nodes):
    # 게이트웨이 좌표와 같으면 중복 생성 방지
    if h_pos == GATEWAY_NODE: continue
    
    nodes.append({"id": node_id_counter, "type": "hallway", "x": h_pos[0], "y": h_pos[1], "z": Z_HEIGHT})
    hallway_ids.append(node_id_counter)
    node_id_counter += 1

# 복도 노드끼리 서로 연결 (가능한 경우)
for i in range(len(hallway_ids)):
    for j in range(i + 1, len(hallway_ids)):
        n1 = nodes[hallway_ids[i]]
        n2 = nodes[hallway_ids[j]]
        p1, p2 = (n1['x'], n1['y']), (n2['x'], n2['y'])
        
        # 거리가 200 이하이고 벽이 없으면 연결 (너무 멀면 연결 X)
        if math.dist(p1, p2) < 200 and check_path_clear(p1, p2, all_walls):
            edges.append({"from": hallway_ids[i], "to": hallway_ids[j]})


# --- [Stage 3] 방 연결 ---
for name, pos in rooms.items():
    if name == "EV": continue # EV는 이미 처리함

    # 방 노드 생성
    nodes.append({"id": node_id_counter, "type": "room", "name": name, "x": pos[0], "y": pos[1], "z": Z_HEIGHT})
    room_node_id = node_id_counter
    node_id_counter += 1
    
    # 가장 가까운 '복도(Gateway 포함)' 노드 찾기
    best_dist = float('inf')
    best_target_id = -1
    
    for h_id in hallway_ids:
        h_node = nodes[h_id]
        h_pos = (h_node['x'], h_node['y'])
        dist = math.dist(pos, h_pos)
        
        # 거리 가깝고 벽 안 뚫는지 확인
        if dist < best_dist:
            if check_path_clear(pos, h_pos, all_walls):
                best_dist = dist
                best_target_id = h_id
    
    # 연결
    if best_target_id != -1:
        edges.append({"from": room_node_id, "to": best_target_id})
    else:
        # 연결 실패 시 강제로 Gateway와 연결해두고 나중에 수정할 수 있게 함 (선택사항)
        pass

# ==========================================
# 5. 결과 출력 (JSON)
# ==========================================
output_data = {"nodes": nodes, "edges": edges}
print(json.dumps(output_data, indent=2, ensure_ascii=False))

# 파일로 저장 코드 (필요시 주석 해제)
# with open("floor_4_path.json", "w", encoding='utf-8') as f:
#     json.dump(output_data, f, indent=2, ensure_ascii=False)