from pydivert import *

import os
import logging
import socket

from threading import Thread
from time import sleep

exit_time: int = 12

ip: str = "127.0.0.1"
port: int = 4242

log_num: int = 1

LOG_FOLDER = r"D:\Projects\Game Projects\Godot Projects\School-Project\PythonFiles\Logs"

curr_packet: Packet

def del_logs(): 
    for i in os.listdir(LOG_FOLDER):
        full_path = os.path.join(LOG_FOLDER, i)
        if os.path.exists(full_path):
           os.remove(full_path)

def log_files(data: str):
    global log_num
    ## Set the log name and formatm then the other settings
    log_path = os.path.join(LOG_FOLDER, f"captr_pckt_{log_num}.log")
    logging.basicConfig(filename=log_path, force=True, level=logging.INFO, filemode="w",encoding="utf-8", format="%(message)s")
    logger = logging.getLogger(__name__)
    
    ## Log the message
    logger.info(data)
    print("GET LOGGED B*TCH ", log_num, "\n")
    log_num += 1


def talk_to_godot(packet: Packet):
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        msg = str(packet)
        client_socket.sendto(msg.encode("utf-8"), (ip, port))
        print("Message to Godot success")

    except Exception as e:
        print(f"Socket error: {e}")

    finally:
        client_socket.close()
    """
    ## FIXME This line bellow has a problem. It explodes when it's called inside the capture packets
    print("code works here")
    data, (recv_ip, recv_port) = client_socket.recvfrom(4096)
    print("does it work here?")
    print(f"Received: '{data.decode()}' {recv_ip}:{recv_port}")
    """


def capture_packets():
    global curr_packet
    del_logs()

    with WinDivert("ip and not loopback and not (udp.DstPort == 4242 or udp.SrcPort == 4242)") as wdiv:
        for packet in wdiv:
            try:
                # print(f"From Packet_capture.py \n{packet}")
                # Sends the packet info to Godot
                talk_to_godot(curr_packet)

                log_files(str(curr_packet))

                wdiv.send(curr_packet) ## This injects the packet into the netwrok
                # print(curr_packet)
                # break
                sleep(.2) 

            except Exception as e:
                print(f"Capture error: {e}")


# def filter_packet(packet):
#     new_ip = input()
#     new_port = input()
#     new_protocol = input()
#     filtered_packet = packet
#     return filtered_packet

# def packet_loss_percantage(packet):
#     percantage = 0
#     filtered_packet = packet
#     return filtered_packet

t = Thread(target=capture_packets, daemon=True)
t.start()
sleep(exit_time)

# talk_to_godot()