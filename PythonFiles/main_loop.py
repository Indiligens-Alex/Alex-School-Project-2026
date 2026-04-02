import sys
import os
import ctypes
from godot_connection import Godot_Connection
from packet_capture import PacketCapture


def is_admin() -> bool:
    """Check if the current process has Administrator privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False


def run_as_admin():
    """Re-launch this script with Administrator privileges (triggers UAC prompt)."""
    script = os.path.abspath(sys.argv[0])
    ## ShellExecuteW with "runas" verb triggers the UAC elevation prompt
    ctypes.windll.shell32.ShellExecuteW(
        None, "runas", sys.executable, f'"{script}"', None, 1
    )


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
    if not is_admin():
        print("Not running as Administrator — requesting elevation...")
        run_as_admin()
        sys.exit(0)  ## Exit the non-admin copy; the elevated one will take over
    print("Running as Administrator ✓")
    main()