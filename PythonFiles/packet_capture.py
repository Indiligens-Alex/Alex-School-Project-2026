import random
import time
import os
from threading import Thread
from pydivert import WinDivert
from godot_connection import Godot_Connection


class PacketCapture:
    def __init__(self, connection: Godot_Connection):
        self.connection = connection
        self.wdiv = None
        self.capture_thread = None
        self.log_num: int = 1
        self.LOG_FOLDER = os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "Logs"
        )

        ## Statistics
        self.total_captured: int = 0
        self.total_dropped: int = 0
        self.total_delayed: int = 0
        self.total_passed: int = 0

        os.makedirs(self.LOG_FOLDER, exist_ok=True)

    ## ——— Internal helpers ———

    def _del_logs(self):
        """Delete all previous log files."""
        for file_name in os.listdir(self.LOG_FOLDER):
            full_path = os.path.join(self.LOG_FOLDER, file_name)
            if os.path.isfile(full_path):
                os.remove(full_path)

    def _log_to_file(self, action: str, packet_info: str):
        """Write one log entry to a numbered .log file."""
        log_path = os.path.join(self.LOG_FOLDER, f"packet_{self.log_num}.log")
        with open(log_path, "w", encoding="utf-8") as f:
            f.write(f"[{action}] {packet_info}\n")
        self.log_num += 1

    def _packet_matches_filter(self, packet) -> bool:
        """Check if a packet matches the user's filter criteria.
        Filters with value '0' or empty are treated as 'match all'."""
        conn = self.connection

        ## Interface IP filter
        if conn.iface_ip and conn.iface_ip != "0":
            src = str(packet.src_addr) if packet.src_addr else ""
            dst = str(packet.dst_addr) if packet.dst_addr else ""
            if conn.iface_ip != src and conn.iface_ip != dst:
                return False

        ## IP filter
        if conn.filter_ip and conn.filter_ip != "0":
            src = str(packet.src_addr) if packet.src_addr else ""
            dst = str(packet.dst_addr) if packet.dst_addr else ""
            if conn.filter_ip != src and conn.filter_ip != dst:
                return False

        ## Port filter
        if conn.filter_port and conn.filter_port != "0":
            try:
                target_port = int(conn.filter_port)
                src_port = packet.src_port if packet.src_port else 0
                dst_port = packet.dst_port if packet.dst_port else 0
                if target_port != src_port and target_port != dst_port:
                    return False
            except ValueError:
                pass

        ## Protocol filter
        if conn.filter_protocol and conn.filter_protocol != "0":
            proto = conn.filter_protocol.lower()
            if proto == "tcp" and not packet.tcp:
                return False
            elif proto == "udp" and not packet.udp:
                return False
            elif proto == "icmp" and not packet.icmp:
                return False

        return True

    def _get_packet_info(self, packet) -> str:
        """Build a human-readable packet summary string."""
        if packet.tcp:
            proto = "TCP"
        elif packet.udp:
            proto = "UDP"
        elif packet.icmp:
            proto = "ICMP"
        else:
            proto = "OTHER"

        src_addr = str(packet.src_addr) if packet.src_addr else "?"
        dst_addr = str(packet.dst_addr) if packet.dst_addr else "?"
        src_port = packet.src_port if packet.src_port else 0
        dst_port = packet.dst_port if packet.dst_port else 0

        return f"proto={proto};src={src_addr}:{src_port};dst={dst_addr}:{dst_port}"

    def _delayed_send(self, packet, delay_seconds: float):
        """Sleep then re-inject a packet (runs in its own thread)."""
        try:
            time.sleep(delay_seconds)
            if self.wdiv:
                self.wdiv.send(packet)
        except Exception as e:
            print(f"Delayed send error: {e}")

    ## ——— Main capture loop ———

    def _capture_loop(self):
        """Main capture loop — runs in a background thread.
        Uses WinDivert to intercept packets, applies errors, sends logs to Godot."""

        ## WinDivert filter: capture everything except our own Godot<->Python ports
        wdiv_filter = "not udp or (udp.SrcPort != 4242 and udp.DstPort != 4242 and udp.SrcPort != 4243 and udp.DstPort != 4243)"

        print(f"Opening WinDivert with filter: {wdiv_filter}")

        try:
            self.wdiv = WinDivert(wdiv_filter)
            self.wdiv.open()
        except Exception as e:
            print(f"Failed to open WinDivert: {e}")
            self.connection.simulation_running = False
            self.connection.send_to_godot(
                "error=Failed to start capture. Run as Administrator.")
            return

        print("Capture loop started")
        self.connection.send_to_godot("status=running")

        try:
            while self.connection.simulation_running:
                try:
                    packet = self.wdiv.recv()
                except Exception:
                    ## If simulation was stopped, the handle was closed — exit cleanly
                    if not self.connection.simulation_running:
                        break
                    raise

                self.total_captured += 1

                ## If packet doesn't match user filters, pass through immediately
                if not self._packet_matches_filter(packet):
                    self.wdiv.send(packet)
                    continue

                packet_info = self._get_packet_info(packet)

                ## === PACKET LOSS ===
                loss = self.connection.loss_percentage
                if loss > 0 and random.random() * 100 < loss:
                    self.total_dropped += 1
                    self._log_to_file("DROPPED", packet_info)
                    self.connection.send_to_godot(f"log=DROPPED;{packet_info}")
                    ## Don't re-inject = packet is dropped
                    continue

                ## === LATENCY + JITTER ===
                latency = self.connection.latency_ms
                jitter = self.connection.jitter_ms
                delay_ms = latency
                if jitter > 0:
                    delay_ms += random.uniform(-jitter, jitter)
                delay_ms = max(0.0, delay_ms)
                delay_s = delay_ms / 1000.0

                if delay_s > 0.001:  ## More than 1ms of delay
                    self.total_delayed += 1
                    delay_display = round(delay_ms)
                    self._log_to_file(
                        "DELAYED", f"{packet_info};delay={delay_display}ms")
                    
                    self.connection.send_to_godot(
                        f"log=DELAYED;{packet_info};delay={delay_display}")
                    
                    ## Re-inject after delay in a separate thread
                    Thread( target=self._delayed_send,
                            args=(packet, delay_s),
                            daemon=True,).start()
                
                else:
                    ## No delay — pass through immediately
                    self.total_passed += 1
                    self._log_to_file("PASSED", packet_info)
                    self.connection.send_to_godot(f"log=PASSED;{packet_info}")
                    self.wdiv.send(packet)

        except Exception as e:
            print(f"Capture loop error: {type(e).__name__}: {e}")
        finally:
            try:
                if self.wdiv:
                    self.wdiv.close()
            except Exception:
                pass
            self.wdiv = None

            ## Send final statistics to Godot
            stats_msg = (
                f"stats=total:{self.total_captured};"
                f"dropped:{self.total_dropped};"
                f"delayed:{self.total_delayed};"
                f"passed:{self.total_passed}")
            
            self.connection.send_to_godot(stats_msg)
            self.connection.send_to_godot("status=stopped")
            print(f"Capture loop ended. {stats_msg}")

    ## ——— Public API ———

    def start(self):
        """Start the packet capture in a background thread."""
        self._del_logs()
        self.log_num = 1
        self.total_captured = 0
        self.total_dropped = 0
        self.total_delayed = 0
        self.total_passed = 0

        self.capture_thread = Thread(target=self._capture_loop, daemon=True)
        self.capture_thread.start()
        print("Capture thread started")

    def stop(self):
        """Stop the capture by closing the WinDivert handle."""
        print("Stopping capture...")
        self.connection.simulation_running = False
        if self.wdiv:
            try:
                self.wdiv.close()
            except Exception:
                pass