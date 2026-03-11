from pydivert import *
import logging
import os

def log_file(data=""):
    logger = logging.getLogger(__name__)
    # Check if the file exists for overwriting it
    if os.path.exists("captr_pckt.log"):
        os.remove("captr_pckt.log")
    # Configure logging with a custom format
    logging.basicConfig(filename="captr_pckt.log", level=logging.DEBUG, filemode="w", format="%(asctime)s - %(levelname)s - %(message)s")
    # Log a message
    logger.debug(data)

with WinDivert() as wdiv:
    for packet in wdiv:
        print(packet)
        wdiv.send(packet)
        log_file(str(packet))
        break

## Old code
# from json import *
# # json_data = ""
# with WinDivert() as wdiv:
#     for packet in wdiv:
#         print(packet)
#         wdiv.send(packet)
#         json_data = dumps(str(packet), indent=4, newline="\n ")
#         if os.path.exists("captr_pckt.json"):
#             os.remove("captr_pckt.json")
#         with open("captr_pckt.json", "w", encoding="utf-8") as captr_pckt:   
#             captr_pckt.write(json_data)
#         break

