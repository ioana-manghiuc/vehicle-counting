from collections import defaultdict
from typing import Dict, List, Tuple, Set
import logging

logger = logging.getLogger("vehicle_counter")


class VehicleCounter:
    """
    Tracks vehicles crossing directional lines.
    Each direction has two lines: entry (isEntry=true) and exit (isEntry=false).
    A vehicle is counted only after crossing entry first, then exit.
    """
    CLASS_MAPPING = {
        0: 'bikes',     
        1: 'buses',     
        2: 'cars',       
        3: 'trucks',     
    }
    
    def __init__(self, directions: List[Dict], frame_w: int, frame_h: int):
        """
        Args:
            directions: List of direction configs from frontend
                Each has: id, from, to, color, lines
                Each line has: x1, y1, x2, y2, isEntry (normalized 0-1)
            frame_w: Video frame width
            frame_h: Video frame height
        """
        self.frame_w = frame_w
        self.frame_h = frame_h
        self.directions = self._parse_directions(directions)
        
        self.vehicle_state: Dict[str, Dict[int, str]] = {
            d['id']: {} for d in self.directions
        }
        
        self.counts: Dict[str, Dict[str, int]] = {
            d['id']: {'bikes': 0, 'cars': 0, 'buses': 0, 'trucks': 0}
            for d in self.directions
        }
        
        logger.info(f"VehicleCounter initialized with {len(self.directions)} directions")
    
    def _parse_directions(self, directions: List[Dict]) -> List[Dict]:
        """Convert normalized coordinates to pixel coordinates and separate entry/exit lines."""
        parsed = []
        
        for d in directions:
            entry_line = None
            exit_line = None
            
            for line in d['lines']:
                line_px = {
                    'x1': line['x1'] * self.frame_w,
                    'y1': line['y1'] * self.frame_h,
                    'x2': line['x2'] * self.frame_w,
                    'y2': line['y2'] * self.frame_h,
                }
                
                if line['isEntry']:
                    entry_line = line_px
                else:
                    exit_line = line_px
            
            if entry_line and exit_line:
                parsed.append({
                    'id': d['id'],
                    'from': d['from'],
                    'to': d['to'],
                    'entry_line': entry_line,
                    'exit_line': exit_line,
                })
                logger.info(f"Direction {d['from']} - {d['to']}: entry={entry_line}, exit={exit_line}")
            else:
                logger.warning(f"Direction {d.get('id')} missing entry or exit line, skipping")
        
        return parsed
    
    def update(self, detections: List[Dict]):
        """
        Update vehicle states based on current frame detections.
        Hybrid approach: on first sighting, record initial side relative to each line.
        On subsequent frames, use segment intersection to detect crossings.
        Fallback: if detection briefly drops and reappears past a line,
        count based on side-change relative to the line.
        
        Args:
            detections: List of {track_id: int, cx: float, cy: float, class_id: int}
        """
        for detection in detections:
            track_id = detection['track_id']
            cx = detection['cx']
            cy = detection['cy']
            class_id = detection['class_id']
            prev = getattr(self, '_prev_positions', {}).get(track_id)
            
            for direction in self.directions:
                dir_id = direction['id']
                current_state = self.vehicle_state[dir_id].get(track_id)
                
                if current_state is None:
                    entry_side = self._get_side_of_line(cx, cy, direction['entry_line'])
                    if entry_side is not None:
                        self.vehicle_state[dir_id][track_id] = {'entry_side': entry_side, 'phase': 'tracking_entry'}
                
                elif isinstance(current_state, dict) and current_state.get('phase') == 'tracking_entry':
                    crossed = False

                    if prev is not None and self._segments_intersect(prev, (cx, cy), direction['entry_line']):
                        crossed = True
                    else:
                        prev_side = current_state.get('entry_side')
                        cur_side = self._get_side_of_line(cx, cy, direction['entry_line'])
                        if prev_side is not None and cur_side is not None and prev_side != cur_side:
                            crossed = True
                    if crossed:
                        self.vehicle_state[dir_id][track_id] = {'phase': 'tracking_exit', 'exit_side': None}
                        logger.debug(f"Vehicle {track_id} crossed ENTRY for direction {dir_id}")
                    else:
                        entry_side = self._get_side_of_line(cx, cy, direction['entry_line'])
                        if entry_side is not None:
                            self.vehicle_state[dir_id][track_id]['entry_side'] = entry_side
                
                elif isinstance(current_state, dict) and current_state.get('phase') == 'tracking_exit':
                    crossed = False
                    if prev is not None and self._segments_intersect(prev, (cx, cy), direction['exit_line']):
                        crossed = True
                    else:
                        prev_exit_side = current_state.get('exit_side')
                        cur_exit_side = self._get_side_of_line(cx, cy, direction['exit_line'])
                        if prev_exit_side is not None and cur_exit_side is not None and prev_exit_side != cur_exit_side:
                            crossed = True
                    if crossed:
                        self.vehicle_state[dir_id][track_id] = 'exit'
                        category = self.CLASS_MAPPING.get(class_id, 'cars')
                        self.counts[dir_id][category] += 1
                        logger.info(
                            f"Vehicle {track_id} ({category}) counted for {direction['from']} - {direction['to']} "
                            f"(Total {category}: {self.counts[dir_id][category]})"
                        )
                    else:
                        cur_exit_side = self._get_side_of_line(cx, cy, direction['exit_line'])
                        if cur_exit_side is not None:
                            self.vehicle_state[dir_id][track_id]['exit_side'] = cur_exit_side
        
        if not hasattr(self, '_prev_positions'):
            self._prev_positions = {}
        for d in detections:
            self._prev_positions[d['track_id']] = (d['cx'], d['cy'])
    
    def _get_side_of_line(self, cx: float, cy: float, line: Dict) -> int:
        """
        Determine which side of a line a point is on using cross product.
        Returns: 1 for one side, -1 for the other, None if on the line (threshold).
        """
        x1, y1 = line['x1'], line['y1']
        x2, y2 = line['x2'], line['y2']
        
        cross = (x2 - x1) * (cy - y1) - (y2 - y1) * (cx - x1)
        
        threshold = 5
        if abs(cross) < threshold:
            return None
        
        return 1 if cross > 0 else -1
    
    def _segments_intersect(self, p1: Tuple[float, float], p2: Tuple[float, float], line: Dict) -> bool:
        """Check if segment p1->p2 intersects the line segment (x1,y1)-(x2,y2)."""
        q1 = (line['x1'], line['y1'])
        q2 = (line['x2'], line['y2'])
        

        def orient(a, b, c):
            return (b[1] - a[1]) * (c[0] - b[0]) - (b[0] - a[0]) * (c[1] - b[1])

        def on_segment(a, b, c):
            return min(a[0], b[0]) <= c[0] <= max(a[0], b[0]) and \
                    min(a[1], b[1]) <= c[1] <= max(a[1], b[1])

        o1 = orient(p1, p2, q1)
        o2 = orient(p1, p2, q2)
        o3 = orient(q1, q2, p1)
        o4 = orient(q1, q2, p2)

        if o1 * o2 < 0 and o3 * o4 < 0:
            return True

        if o1 == 0 and on_segment(p1, p2, q1):
            return True
        if o2 == 0 and on_segment(p1, p2, q2):
            return True
        if o3 == 0 and on_segment(q1, q2, p1):
            return True
        if o4 == 0 and on_segment(q1, q2, p2):
            return True

        return False
    
    def get_results(self) -> Dict:
        """Return final counting results."""
        results = {}
        
        for direction in self.directions:
            dir_id = direction['id']
            results[f"{direction['from']} - {direction['to']}"] = {
                'bikes': self.counts[dir_id]['bikes'],
                'cars': self.counts[dir_id]['cars'],
                'buses': self.counts[dir_id]['buses'],
                'trucks': self.counts[dir_id]['trucks'],
                'total': sum(self.counts[dir_id].values()),
            }
        
        return results
