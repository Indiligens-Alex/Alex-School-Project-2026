from pydivert import *
import logging
import os
import socket

ip = "127.0.0.1"
port = 4242

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
    ip = input()
    port = input()
    protocol = input()
    filtered_packet = packet
    return filtered_packet

def capture_data():
    with WinDivert() as wdiv:
        for packet in wdiv:
            filtered_packet = filter_packet(packet)
            # print(f"From Packet_capture.py \n{packet}")
            wdiv.send(filtered_packet)
            log_file(str(filtered_packet))
            break

client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client_socket.settimeout(1)

## Sends data to Godot
client_socket.sendto("Hello from Python!".encode(), (ip, port))

data, (recv_ip, recv_port) = client_socket.recvfrom(1024)
print(f"Received: '{data.decode()}' {recv_ip}:{recv_port}")

