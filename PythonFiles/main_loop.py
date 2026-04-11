import sys
from godot_connection import Godot_Connection
from packet_capture import PacketCapture


def main():
    ## Create the connection to Godot (UDP server on port 4243)
    connection = Godot_Connection()

    ## Create the packet capturer and give it access to the connection
    capturer = PacketCapture(connection)
    connection.capturer = capturer  ## So connection can start/stop capture via commands

    ## Start listening for Godot messages (non-blocking, returns the thread)
    listener_thread = connection.run()

    ## Keep main thread alive until interrupted
    try:
        listener_thread.join()
    except KeyboardInterrupt:
        print("\nShutting down...")
        connection.running = False
        if connection.simulation_running:
            capturer.stop()
        sys.exit(0)

if __name__ == "__main__":
    main()