from godot_connection import Godot_Connection
from packet_modifier import Packet_Modifier
from packet_capture import Packet_Capture

def main():
    connection = Godot_Connection()
    connection.run()    ## Start listening for a Godot responce

# def call():
    ## Create the packet capturer and give it access to the connection
    # capturer = Packet_Capture(connection = connection)
    ## Run — this blocks the main thread until the capture thread finishes.
    # capturer.run()

if __name__ == "__main__":
    main()