from pydivert import *
import logging
import os
import socket

ip = "127.0.0.1"
port = 4242

curr_packet
def log_file(data=""):
    logger = logging.getLogger(__name__)
    # Check if the file exists for overwriting it
    if os.path.exists("captr_pckt.log"):
        os.remove("captr_pckt.log")
    # Configure logging with a custom format
    logging.basicConfig(filename="captr_pckt.log", level=logging.DEBUG, filemode="w", format="%(asctime)s - %(levelname)s - %(message)s")
    # Log a message
    logger.debug(data)

def filter_packet(packet):
    new_ip = input()
    new_port = input()
    new_protocol = input()
    filtered_packet = packet
    return filtered_packet

def packet_loss_percantage(packet):
    percantage
    filtered_packet = packet
    return filtered_packet

def capture_packets():
    with WinDivert() as wdiv:
        for packet in wdiv:
            print(f"From Packet_capture.py \n{packet}")
            curr_packet = packet
            # wdiv.send(filtered_packet) ## This injects the packet into the netwrok
            log_file(str(filtered_packet))
            break
            time.sleep(1) 

def talk_to_godot():
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.settimeout(.2)

    ## Sends data to Godot
    client_socket.sendto(
        "Hello from Python!".encode(), ## This is the data that is being sent
        (ip, port))  ## This is the destinataion, aka Godot

    data, (recv_ip, recv_port) = client_socket.recvfrom(1024)
    print(f"Received: '{data.decode()}' {recv_ip}:{recv_port}")

talk_to_godot()



from threading import Thread
from time import sleep
t = Thread(target=capture_packets, daemon=True)
t.start()
exit_timer = 1
sleep(exit_timer)