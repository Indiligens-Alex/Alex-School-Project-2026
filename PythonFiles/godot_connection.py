import socket
import time
from threading import Thread


class Godot_Connection:
    ## Init - Setting up the Connection Params and creating a UDP server to talk with Godot
    def __init__(self):
        self.ip: str = "127.0.0.1"
        self.python_port: int = 4243
        self.godot_port: int = 4242

        self.connection_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.connection_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.connection_socket.bind((self.ip, self.python_port))
        self.connection_socket.settimeout(0.15)

        ## Filter parameters (updated in real-time from Godot)
        self.filter_ip: str = "0"
        self.filter_port: str = "0"
        self.filter_protocol: str = "0"
        self.iface_ip: str = "0"

        ## Error simulation parameters
        self.loss_percentage: float = 0.0
        self.latency_ms: float = 0.0
        self.jitter_ms: float = 0.0

        ## State
        self.simulation_running: bool = False
        self.running: bool = False
        self.godot_addr = None
        self.capturer = None  ## Reference to PacketCapture, set by main_loop

        print("Godot_Connection init — listening on port", self.python_port)

    ## Running forever in a background thread, continuously listening to Godot
    ## Params are updated in real-time as Godot sends them (no "send" button needed)
    def start_listening_loop(self):
        while self.running:
            try:
                data, addr = self.connection_socket.recvfrom(4096)
                message = data.decode("utf-8")
                self.godot_addr = addr

                for part in message.split(";"):
                    if "=" not in part:
                        continue
                    key, val = part.split("=", 1)

                    if key == "ip":
                        self.filter_ip = val
                    elif key == "port":
                        self.filter_port = val
                    elif key == "proto":
                        self.filter_protocol = val
                    elif key == "iface_ip":
                        self.iface_ip = val
                    elif key == "loss":
                        try:
                            self.loss_percentage = float(val)
                        except ValueError:
                            print(f"Invalid loss value: {val}")
                    elif key == "latency":
                        try:
                            self.latency_ms = float(val)
                        except ValueError:
                            print(f"Invalid latency value: {val}")
                    elif key == "jitter":
                        try:
                            self.jitter_ms = float(val)
                        except ValueError:
                            print(f"Invalid jitter value: {val}")
                    elif key == "cmd":
                        self._handle_command(val)

            except socket.timeout:
                continue
            except ConnectionResetError:
                # Godot UDP port unreachable (Godot is not running). Suppress spam.
                continue
            except Exception as e:
                print(f"Listen error: {type(e).__name__}: {e}")

    ## Handle start/stop commands from Godot
    def _handle_command(self, command: str):
        if command == "start" and not self.simulation_running:
            print(">>> STARTING SIMULATION")
            self.simulation_running = True
            if self.capturer:
                self.capturer.start()
        elif command == "stop" and self.simulation_running:
            print(">>> STOPPING SIMULATION")
            if self.capturer:
                self.capturer.stop()
            self.simulation_running = False
            
            self.send_interfaces()
            self.send_active_connections()

    ## Sending data to Godot's UDP server
    def send_to_godot(self, data: str):
        try:
            if self.godot_addr is not None:
                self.connection_socket.sendto(data.encode("utf-8"), self.godot_addr)
            else:
                self.connection_socket.sendto(
                    data.encode("utf-8"), (self.ip, self.godot_port))
        except Exception as e:
            print(f"Send error: {type(e).__name__}: {e}")

    ## Query network interfaces using psutil and send the list to Godot
    def send_interfaces(self):
        try:
            import psutil

            ifaces = psutil.net_if_addrs()
            stats = psutil.net_if_stats()
            parts = []
            for name, addrs in ifaces.items():
                if name in stats and not stats[name].isup:
                    continue
                for addr in addrs:
                    if addr.family.name == "AF_INET":  ## IPv4 only
                        if addr.address == "127.0.0.1" or addr.address.startswith("169.254."):
                            continue
                        parts.append(f"{name}|{addr.address}")
                        break
            if parts:
                msg = "ifaces=" + ",".join(parts)
                self.send_to_godot(msg)
                print(f"Sent interfaces: {msg}")
        except ImportError:
            print("psutil not available — skipping interface listing")
        except Exception as e:
            print(f"Interface listing error: {e}")

    ## Query active network connections and send to Godot
    def send_active_connections(self):
        try:
            import psutil
            import socket
            
            conns_set = set()
            for conn in psutil.net_connections(kind='all'):
                # type is socket.SOCK_STREAM (TCP) or socket.SOCK_DGRAM (UDP)
                proto = "TCP" if conn.type == socket.SOCK_STREAM else ("UDP" if conn.type == socket.SOCK_DGRAM else "OTHER")
                
                if conn.laddr:
                    conns_set.add(f"{conn.laddr.ip},{conn.laddr.port},{proto}")
                if conn.raddr:
                    conns_set.add(f"{conn.raddr.ip},{conn.raddr.port},{proto}")
            
            conns_list = list(conns_set)[:200] # clamp size to prevent massive UDP packets
            if conns_list:
                msg = "conns=" + "|".join(conns_list)
                self.send_to_godot(msg)
        except ImportError:
            pass
        except Exception as e:
            print(f"Active connections error: {e}")

    def connections_poll_loop(self):
        while self.running:
            self.send_active_connections()
            time.sleep(3.0)

    ## Starts the listening process (non-blocking — returns the thread)
    def run(self):
        self.running = True
        t = Thread(target=self.start_listening_loop, daemon=True)
        t.start()

        t_conns = Thread(target=self.connections_poll_loop, daemon=True)
        t_conns.start()

        print("Listening for Godot messages...")
        self.send_to_godot("hello")

        ## Send available interfaces after a brief delay to let Godot connect
        time.sleep(0.5)
        self.send_interfaces()
        
        self.send_active_connections()

        return t  ## Return thread so main_loop can join it