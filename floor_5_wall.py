import math
import json

# ==========================================
# 1. 설정 및 데이터 입력
# ==========================================

# 3D 높이 (벽 높이 15의 절반 or 통일된 높이)
Z_HEIGHT = 15

# 좌표값 도우미
def Vector(v):
    return (v[0], v[1])

# 1-1. 외벽 데이터 (5floor.txt 기반)
outer_wall_points = [
    Vector((-200.0, -200.0, 0.0)), Vector((-300.0, -100.0, 0.0)),
    Vector((-200.0, 0.0, 0.0)), Vector((-100.0, 100.0, 0.0)),
    Vector((-50.0, 150.0, 0.0)), Vector((250.0, 150.0, 0.0)),
    Vector((250.0, 0.0, 0.0)), Vector((0.0, 0.0, 0.0)),
    Vector((-200.0, -200.0, 0.0))
]

# 1-2. 내벽 데이터 (5floor.txt 기반)
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
    [Vector((250.0, 50.0, 0)), Vector((-30.0, 50.0, 0))],
    [Vector((-260.0, -140.0, 0)), Vector((-40, 80.0, 0))],
    [Vector((250.0, 80.0, 0)), Vector((-40.0, 80.0, 0))],
    [Vector((-140.0, -60.0, 0)), Vector((-100.0, -100.0, 0))],
    [Vector((-160.0, -80.0, 0)), Vector((-120.0, -120.0, 0))],
    [Vector((170.0, 50.0, 0)), Vector((170.0, 0.0, 0))],
    [Vector((130.0, 50.0, 0)), Vector((130.0, 0.0, 0))],
    [Vector((100.0, 50.0, 0)), Vector((100.0, 0.0, 0))],
    [Vector((70.0, 50.0, 0)), Vector((70.0, 0.0, 0))],
    [Vector((20.0, 50.0, 0)), Vector((20.0, 0.0, 0))],
    [Vector((-30.0, 80.0, 0)), Vector((-30.0, 150.0, 0))],
    [Vector((110.0, 80.0, 0)), Vector((110.0, 150.0, 0))],
    [Vector((180.0, 80.0, 0)), Vector((180.0, 150.0, 0))],
    [Vector((-160.0, -40.0, 0)), Vector((-200.0, 0.0, 0))],
    [Vector((-180.0, -60.0, 0)), Vector((-220.0, -20.0, 0))],
    [Vector((-200.0, -80.0, 0)), Vector((-240.0, -40.0, 0))],
    [Vector((-220.0, -100.0, 0)), Vector((-260.0, -60.0, 0))],
    [Vector((-240.0, -120.0, 0)), Vector((-280.0, -80.0, 0))],
    [Vector((-200.0, -120.0, 0)), Vector((-160.0, -160.0, 0))],
]

# 1-3. 방 데이터 (5층 호실)
# 1-3. 방 데이터 (5층 호실 - 원본 데이터 복구)
# 1-3. 방 데이터 (5층 호실 - 5floor.txt 원본 좌표 반영)
rooms = {
    "501": (40, 115), "502": (145, 115), "503": (215, 115), "504": (210, 25),
    "학생회 사무실": (150, 25), 
    "506": (-190, -30), "507": (-210, -50), "508": (-230, -70), 
    "509": (-250, -90), "510": (-270, -110),
    "511": (-200, -160), "512": (-160, -120),
    "계단_1": (-130, -90), "화장실(남)": (-45, -20), "화장실(여)": (-90, -65),
    "장애인화장실(남)": (-65, 0), "장애인화장실(여)": (-95, -30),
    "EV": (45, 25), "화물EV": (85, 25), "계단_2": (115, 25)
}

# 1-4. [중요] 경로 설정
EV_START = (45.0, 25.0)      
GATEWAY_NODE = (45.0, 65.0) 

# 복도 뼈대 노드 (5층 고유 데이터)
hallway_nodes = [
    (45, 65),          # GATEWAY
    (-34.48, 65),
    (-58.48, 40.3),
    (-36.8, 16.91),
    (-25.97, 14.63),
    (-79, 20.33),
    (-109.8, -10.46),
    (-138.3, -40.69),
    (-124.1, -56.66),
    (-160, -59.51),
    (-180.5, -79),
    (-188.5, -88.03),
    (-199.9, -99.44),
    (-219.3, -118.3),
    (-230.1, -129.1),
    (-240.4, -139.9),
    (40, 65),
    (145, 65),
    (150, 65),
    (215, 65),
    (85, 65),
    (115, 65)
]

# ==========================================
# 2. 벽 통합 및 알고리즘 함수
# ==========================================
all_walls = []
for i in range(len(outer_wall_points) - 1):
    all_walls.append([outer_wall_points[i], outer_wall_points[i+1]])
all_walls.extend(inner_walls_raw)

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
    if math.dist(start, end) < 1.0: return True
    for w_start, w_end in walls:
        if is_intersect(start, end, w_start, w_end):
            return False 
    return True

# ==========================================
# 3. 노드/엣지 생성 로직
# ==========================================
nodes = []
edges = []
node_id_counter = 0

# [Step 1] EV -> GATEWAY
nodes.append({"id": node_id_counter, "type": "start", "name": "EV", "x": EV_START[0], "y": EV_START[1], "z": Z_HEIGHT})
ev_id = node_id_counter
node_id_counter += 1

nodes.append({"id": node_id_counter, "type": "gateway", "name": "GATEWAY", "x": GATEWAY_NODE[0], "y": GATEWAY_NODE[1], "z": Z_HEIGHT})
gateway_id = node_id_counter
node_id_counter += 1
edges.append({"from": ev_id, "to": gateway_id})

# [Step 2] 복도 노드 생성 및 연결
hallway_ids = [gateway_id] 
for i, h_pos in enumerate(hallway_nodes):
    # GATEWAY 좌표 중복 방지
    if h_pos == GATEWAY_NODE: continue
    
    nodes.append({"id": node_id_counter, "type": "hallway", "x": h_pos[0], "y": h_pos[1], "z": Z_HEIGHT})
    hallway_ids.append(node_id_counter)
    node_id_counter += 1

# 복도끼리 연결 (거리 400 이하일 때만 - 너무 멀면 연결 X)
for i in range(len(hallway_ids)):
    for j in range(i + 1, len(hallway_ids)):
        n1 = nodes[hallway_ids[i]]
        n2 = nodes[hallway_ids[j]]
        p1, p2 = (n1['x'], n1['y']), (n2['x'], n2['y'])
        
        # 거리가 적당하고 벽에 안 막히면 연결
        if math.dist(p1, p2) < 400 and check_path_clear(p1, p2, all_walls):
            edges.append({"from": hallway_ids[i], "to": hallway_ids[j]})

# [Step 3] 방 연결
for name, pos in rooms.items():
    if name == "EV": continue 
    
    nodes.append({"id": node_id_counter, "type": "room", "name": name, "x": pos[0], "y": pos[1], "z": Z_HEIGHT})
    room_node_id = node_id_counter
    node_id_counter += 1
    
    # 가장 가까운 복도 노드 찾기
    best_dist = float('inf')
    best_target_id = -1
    
    for h_id in hallway_ids:
        h_node = nodes[h_id]
        h_pos = (h_node['x'], h_node['y'])
        dist = math.dist(pos, h_pos)
        
        if dist < best_dist:
            # if check_path_clear(pos, h_pos, all_walls): # 벽 체크 해제 (방은 벽 안에 있을 수 있음)
            best_dist = dist
            best_target_id = h_id
    
    if best_target_id != -1:
        edges.append({"from": room_node_id, "to": best_target_id})

# ==========================================
# 4. JSON 출력
# ==========================================
output_data = {"nodes": nodes, "edges": edges}
print(json.dumps(output_data, indent=2, ensure_ascii=False))

# 파일 저장 코드 (필요시 사용)
# with open("floor_5_path.json", "w", encoding='utf-8') as f:
#     json.dump(output_data, f, indent=2, ensure_ascii=False)