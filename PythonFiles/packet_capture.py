from pydivert import WinDivert, Packet
from threading import Thread; from time import sleep; import os
from godot_connection import Godot_Connection

class Packet_Capture:
    def __init__(self, connection: Godot_Connection):
        self.connection = connection  
        self.log_num: int = 1
        self.LOG_FOLDER = r"D:\Projects\Game Projects\Godot Projects\School-Project\PythonFiles\Logs"

    def del_logs(self):
        for file_name in os.listdir(self.LOG_FOLDER):
            full_path = os.path.join(self.LOG_FOLDER, file_name)
            if os.path.exists(full_path):
                os.remove(full_path)

    def log_files(self, data: str):
        ## Set the log name and formatm then the other settings
        log_path = os.path.join(self.LOG_FOLDER, f"captr_pckt_{self.log_num}.log")
        with open(log_path, "w", encoding="utf-8") as f:
            f.write(data)
        print("GET LOGGED B*TCH ", self.log_num)
        self.log_num += 1

    def capture_packets(self, amount: int):
        with WinDivert("true") as wdiv:
            for i in range(amount):
                try:
                    packet: Packet = next(wdiv)

                    if (packet.udp is not None) and (
                        packet.dst_port in (4242, 4243) or 
                        packet.src_port in (4242, 4243)):
                        continue

                    self.log_files(str(packet))
                    wdiv.send(packet) ## This injects the packet into the netwrok
                    print(f"Captured packet {i + 1} of {amount}")
                    print("Exited loop\n")

                except Exception as e:
                    print(f"Capture error: {e}")
                    break

    def run(self):
        self.del_logs()
        t = Thread(target=self.capture_packets, args=(2,), daemon=True)
        t.start()
        t.join()