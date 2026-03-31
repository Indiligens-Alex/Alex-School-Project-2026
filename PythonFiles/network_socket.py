import socket

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

        print("Network_Socket init called")

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

            print(f"Received params from Godot: {self.filter_ip}, {self.filter_port}, {self.filter_protocol}, {self.loss_percentage}")
        
        except socket.timeout:
            print("No data from Godot yet...")
    
    def send_packet(self, packet):
        # Send modified packet data back to Godot
        pass
    
"""
    ## OLD But idk if still useful
    def connect_to_godot():

        try:
            msg = str(packet)
            client_socket.sendto(msg.encode("utf-8"), (ip, port))
            print("Message to Godot success")

        except Exception as e:
            print(f"Socket error: {e}")

        finally:
            client_socket.close()
"""
