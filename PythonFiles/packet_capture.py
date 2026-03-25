from pydivert import *

import os
import logging
import socket

from threading import Thread
from time import sleep

ip: str = "127.0.0.1"
port: int = 4242

log_num: int = 1

curr_packet: Packet

def del_logs(): 
    for i in os.listdir("D:\\Projects\\Game Projects\\Godot Projects\\School-Project\\PythonFiles\\Logs"):
        if os.path.exists("D:\\Projects\\Game Projects\\Godot Projects\\School-Project\\PythonFiles\\Logs\\"+i):
           os.remove("D:\\Projects\\Game Projects\\Godot Projects\\School-Project\\PythonFiles\\Logs\\"+i)

def log_files(data: str):
    global log_num

    logging.basicConfig(filename="D:\\Projects\\Game Projects\\Godot Projects\\School-Project\\PythonFiles\\Logs\\captr_pckt_"+str(log_num)+".log", level=logging.INFO, filemode="w",encoding="utf-8", format="%(message)s")
    logger = logging.getLogger(__name__)
    log_num += 1
    # Log the message
    logger.info(data)
    for handler in logger.handlers:
        if isinstance(handler, logging.FileHandler):
            print(f"Logging to: {handler.baseFilename}")
    print("GET LOGGED B*TCH")
    print(log_num)
    print()
    print()
    print()

def capture_packets():
    global curr_packet
    del_logs()
    with WinDivert() as wdiv:
        for packet in wdiv:
            print(f"From Packet_capture.py \n{packet}")
            curr_packet = packet
            ## TODO Apply filters and other stuff

            wdiv.send(curr_packet) ## This injects the packet into the netwrok
            log_files(str(curr_packet))
            # print(curr_packet)
            # break

def talk_to_godot():
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    client_socket.settimeout(.2)

    ## Sends data to Godot
    client_socket.sendto(
        "Hello from Python!".encode(), ## This is the data that is being sent
        (ip, port))  ## This is the destinataion, aka Godot

    data, (recv_ip, recv_port) = client_socket.recvfrom(1024)
    print(f"Received: '{data.decode()}' {recv_ip}:{recv_port}")

def filter_packet(packet):
    new_ip = input()
    new_port = input()
    new_protocol = input()
    filtered_packet = packet
    return filtered_packet

def packet_loss_percantage(packet):
    percantage = 0
    filtered_packet = packet
    return filtered_packet

# talk_to_godot()

t = Thread(target=capture_packets, daemon=True)
t.start()
exit_timer = .1
sleep(exit_timer)