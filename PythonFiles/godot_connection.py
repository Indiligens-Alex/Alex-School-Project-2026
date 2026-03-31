import socket
from threading import Thread

class Godot_Connection: 
    ## Init - Setting up the Connection Params and creating a UDP server to talk with Godot
    def __init__(self, ip: str = "127.0.0.1", port: int  = 4242):
        self.ip = ip
        self.port = port

        self.connection_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.connection_socket.bind((ip, port))
        self.connection_socket.settimeout(0.1)

        self.godot_addr = None
        self.filter_ip: str = ""
        self.filter_port: str = ""
        self.filter_protocol: str = ""
        self.loss_percentage: float = 0.0
        self._running: bool = False

        print("Godot_Connection init called")

    def announce_to_godot(self):
        # Python sends a "hello" to Godot so Godot knows Python is alive.
        # We send to Godot's SERVER port — Godot's UDPServer is listening there.
        self.connection_socket.sendto(b"hello", (self.ip, self.port))
        print("Announced presence to Godot")

    ## Recieve the Godot Params:
    def receive_params(self):
        try:   
            data, addr = self.connection_socket.recvfrom(1024) 
            message = data.decode("utf-8")    
            self.godot_addr = addr

            for part in message.split(";"):
                key, val = part.split("=")
                if key == "ip":
                    self.filter_ip = val
                elif key == "port":
                    self.filter_port = val
                elif key == "proto":
                    self.filter_protocol = val
                elif key == "loss":
                    self.loss_percentage = float(val)

            print(f"Params received: ip={self.filter_ip} port={self.filter_port} "
                  f"proto={self.filter_protocol} loss={self.loss_percentage}")

        except socket.timeout:
            pass

    def send_packet(self, packet):
        # Send modified packet data back to Godot
        pass

    ## Running forever in a background thread, continuously polling for messages.
    ## receive_params has a 0.1s timeout, so this loop checks ~10 times/second.
    def _listen_loop(self):
        while self._running:
            self.receive_params()

    def start_listening(self):
        # Starts the background thread so Python never misses a message from Godot.
        self._running = True
        t = Thread(target=self._listen_loop, daemon=True)
        t.start()
        print("Listening for Godot messages...")

    def stop_listening(self):
        self._running = False

    def send_packet(self, data: str):
        # Sends processed packet data back to Godot.
        # godot_addr is set the first time we receive anything from Godot.
        if self.godot_addr is not None:
            self.connection_socket.sendto(data.encode("utf-8"), self.godot_addr)
        else:
            print("Can't send — Godot address unknown yet")
