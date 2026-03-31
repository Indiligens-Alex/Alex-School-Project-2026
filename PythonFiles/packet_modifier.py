class Packet_Modifier:
    def __init__(self):
        pass

    ## TODO Do modifications to the packet here
    def modify_packet(self, packet):
        # TODO: add filtering / packet loss / edits here
        return packet

    def send_mod_pack_to_godot(self, packet):
        """Send modified packet info to Godot."""
        # TODO: implement UDP send to Godot here
        pass