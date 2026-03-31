from pydivert import *
import os; import logging; import socket
from threading import Thread
from time import sleep

## Connection settings
ip: str = "127.0.0.1"
port: int = 4242

## Modification parameters
filter_ip: int
filter_port: int
filter_protocol: str
loss_percentage: float

## Program exit time, cuz it frigging crashes my Parsec
exit_time: int = 3

## Log file number, cuz log_file() gets called when a packet is captured and so it gets counted globally
log_num: int = 1
LOG_FOLDER = r"D:\Projects\Game Projects\Godot Projects\School-Project\PythonFiles\Logs"

def del_logs(): 
    for i in os.listdir(LOG_FOLDER):
        full_path = os.path.join(LOG_FOLDER, i)
        if os.path.exists(full_path):
           os.remove(full_path)

def log_files(data: str):
    global log_num
    ## Set the log name and formatm then the other settings
    log_path = os.path.join(LOG_FOLDER, f"captr_pckt_{log_num}.log")
    with open(log_path, "w", encoding="utf-8") as f:
        f.write(data)
    print("GET LOGGED B*TCH ", log_num, "\n")
    log_num += 1

## TODO Do modifications to the packet here
def modify_packet(packet: Packet):
    return packet

def send_mod_pack_to_godot(packet: Packet):
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

def capture_packets():
    with WinDivert("true") as wdiv:
        for packet in wdiv:
            modified_packet: Packet
            try:
                if (packet.udp is not None) and (packet.dst_port == 4242 or packet.src_port == 4242):
                    continue
                # log_files(str(packet))
                modified_packet = modify_packet(packet) ## Modifies the packet with the given settings
                send_mod_pack_to_godot(modified_packet) ## Sends the modified packet to godot
                wdiv.send(modified_packet) ## This injects the packet into the netwrok
                sleep(.5) 

            except Exception as e:
                print(f"Capture error: {e}")

def run_program():
    ## Deletes the prevous logged packets 
    del_logs()

    ## Connect to Godot
    connection_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    connection_socket.bind((ip, port))
    connection_socket.settimeout(0.1)

    ## Recieve_godot_params:
    global filter_ip, filter_port, filter_protocol, loss_percentage
    data, addr = connection_socket.recvfrom(1024)  
    message = data.decode("utf-8")
    try:
        data, addr = connection_socket.recvfrom(1024)  # buffer size
        message = data.decode("utf-8")  # message should be string like "ip=1.2.3.4;port=80;proto=udp;loss=10.0"
        for part in message.split(";"):
            key, val = part.split("=")
            if key == "ip":
                filter_ip = val
            elif key == "port":
                filter_port = val
            elif key == "proto":
                filter_protocol = val
            elif key == "loss":
                loss_percentage = float(val)
        print(f"Received params from Godot: {filter_ip}, {filter_port}, {filter_protocol}, {loss_percentage}")
    except socket.timeout:
        pass  # no data received this frame

    t = Thread(target=capture_packets, daemon=True)
    t.start()   
    sleep(exit_time)

run_program()