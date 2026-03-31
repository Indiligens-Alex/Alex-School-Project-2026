from godot_connection import Godot_Connection
from packet_modifier import Packet_Modifier
from packet_capture import Packet_Capture

def main():
    connection = Godot_Connection()
    # Start listening BEFORE announcing — if we announce first,
    # Godot might reply before we're listening and we'd miss it.
    connection.start_listening()

    # Now announce — Godot will detect Python and store the peer.
    connection.announce_to_godot()

    # Create the packet capturer and give it access to the connection
    # so it can read filters and send results back to Godot.
    capturer = Packet_Capture(connection = connection)

    # Run — this blocks the main thread until the capture thread finishes.
    capturer.run()

if __name__ == "__main__":
    main()