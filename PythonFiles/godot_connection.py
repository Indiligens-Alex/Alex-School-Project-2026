import socket
from threading import Thread

class Godot_Connection: 
    ## Init - Setting up the Connection Params and creating a UDP server to talk with Godot
    def __init__(self):
        self.ip: str = "127.0.0.1"      ## The computer address
        self.python_port: int = 4243    ## Adress of which to recive data, a.k.a. adress to myself, the Python code
        self.godot_port: int = 4242     ## Adress where to send data, a.k.a. adress to Godot

        self.connection_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.connection_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.connection_socket.bind((self.ip, self.python_port))
        self.connection_socket.settimeout(0.15)

        self.filter_ip: str = "0"
        self.filter_port: str = "0"
        self.filter_protocol: str = "0"
        self.loss_percentage: float = 0.0
        self.running: bool = False

        self.godot_addr = None 

        print("Godot_Connection init called — listening on port", self.python_port)

    ## Running forever in a background thread, continuously listening to Godot and wating to recieve the Godot Params. This loop checks ~10 times/second, a 0.1s timeout.
    def start_listening_loop(self):
        while self.running:
            try:
                # This is where timeout happens if nothing is received
                data, addr = self.connection_socket.recvfrom(1024)
                message = data.decode("utf-8")
                self.godot_addr = addr  # remember who sent the packet

                print(f"RAW MESSAGE RECEIVED: {message} from address {addr}")

                for part in message.split(";"):
                    if "=" not in part:   # skip anything that isn't key=value
                        continue
                    key, val = part.split("=", 1)  # 1 = split on first = only
                    if key == "ip":
                        self.filter_ip = val
                    elif key == "port":
                        self.filter_port = val
                    elif key == "proto":
                        self.filter_protocol = val
                    elif key == "loss":
                        try:
                            self.loss_percentage = float(val)
                        except ValueError:
                            print(f"Invalid loss value received: {val}")
                
                print(  f"Params received: ip={self.filter_ip} "
                        f"port={self.filter_port} "
                        f"proto={self.filter_protocol} "
                        f"loss={self.loss_percentage}")
            except socket.timeout:
                continue ## Nothing arrived this frame, just loop again

            except Exception as e:
                print(f"Listen loop error: {type(e).__name__}: {e}")

    # def connect_to_godot(self):
    #     self.connection_socket.sendto(b"hello from python", (self.ip, self.godot_port))
    #     print(f"Connected to Godot at:  {self.ip} , {self.godot_port}")

    ## Sending some data to Godot's SERVER port. Godots' UDPServer is listening on that port.
    def send_to_godot(self, data: str):
        try:
            ## If we've already received something from Godot, reply directly to that sender
            if self.godot_addr is not None:
                self.connection_socket.sendto(data.encode("utf-8"), self.godot_addr)
                print(f"Data sent to Godot (reply): {data} -> {self.godot_addr}")
            else:
                # Fallback: send to known localhost port
                self.connection_socket.sendto(data.encode("utf-8"), (self.ip, self.godot_port))
                print(f"Data sent to Godot: {data} -> {(self.ip, self.godot_port)}")

        except Exception as e:
            print(f"Send error: {type(e).__name__}: {e}")

    ## Starts the listening procces
    def run(self):
        self.running = True
        t = Thread(target=self.start_listening_loop, daemon=True)
        t.start()

        print("Listening for Godot messages...")
        self.send_to_godot("Hello") ## Connection to Godot
        print("Message sent to godot")

        t.join() ## Makes it run in the background and not die when the main thread is gone