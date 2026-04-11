# Packet Loss and Network Error Simulator
**(Симулатор на мрежови грешки и загуба на пакети)**

This repository contains a desktop application designed to simulate network errors like packet loss, latency, and jitter. It is built using **Godot 4** for the frontend Graphical User Interface (GUI) and **Python 3** for the networking backend.

## Table of Contents
1. [Project Overview](#project-overview)
2. [Core Features / Основни Характеристики](#core-features--основни-характеристики)
3. [Architecture and Workflow](#architecture-and-workflow)
4. [Godot Frontend](#godot-frontend)
5. [Python Backend & WinDivert](#python-backend--windivert)
6. [Communication Protocol](#communication-protocol)
7. [Requirements & Setup](#requirements--setup)

---

## Project Overview

The objective of this project is to create a utility that functions as a real-time network interceptor. Rather than passively analyzing traffic, it allows a user to actively inject network conditions simulating a poor connection between endpoints. This tool is invaluable for testing robust network applications, multiplayer games, and web services against unpredictable, sub-optimal infrastructure (such as fluctuating mobile networks or distant geographic servers).

---

## Core Features / Основни Характеристики

The application dynamically intercepts traffic seamlessly at the kernel level and offers the following capabilities:

* **Да прихваща мрежовия трафик (inbound/outbound) на избран мрежов интерфейс** 
  *To capture network traffic (inbound/outbound) on a selected network interface.*
* **Да позволява дефиниране на правила за филтриране на трафика (по ІР, порт, протокол), върху който да се прилагат грешките** 
  *То allow defining traffic filtering rules (by IP, port, protocol) on which to apply the errors.*
* **Да реализира симулация на "Загуба на пакети" (Packet Loss) с конфигурируем процент на вероятност** 
  *To implement a "Packet Loss" simulation with a configurable percentage probability.*
* **Да реализира симулация на "Закъснение" (Latency/Lag) с възможност за задаване на време в милисекунди** 
  *To implement a "Latency/Lag" simulation with the ability to set the time in milliseconds.*
* **Да реализира симулация на "Jitter" (вариация в закъснението)** 
  *To implement a simulation of "Jitter", a variation in delay.*
* **Да позволява стартиране и спиране на симулацията в реално време** 
  *To allow starting and stopping the simulation in real time.*
* **Да води журнал (log) на манипулираните пакети (изпуснати, забавени)** 
  *To keep a log of the manipulated packets (dropped, delayed/forgotten).*
* **Да притежава интуитивен графичен потребителски интерфейс (GUI) за настройка на параметрите** 
  *To have an intuitive graphical user interface for setting parameters.*

---

## Architecture and Workflow

The application runs dual, fully decoupled processes that talk to each other over a local UDP hook. This prevents the heavy Godot UI engine from stealing compute ticks away from the time-sensitive high-performance network interceptor natively looping in Python.

### How it Works
1. **Startup**: When the Godot app (frontend) opens, it spawns the Python script (backend) in a heavily siloed OS subprocess.
2. **Initial Handshake & Data Stream**: 
   - Godot listens on a distinct UDP server (`port 4242`). 
   - Python opens a UDP listener on `port 4243`.
   - Python immediately broadcasts a `"hello"` message, validates its active network interfaces utilizing `psutil`, and dynamically sends them to Godot.
   - Python constantly polls specific valid network endpoints dynamically (such as IP, Port, and Protocol constraints) and syncs those values to Godot.
3. **Configuration / Real-time Sync**: As the user adjusts parameters in the UI (changing dropdowns for IPs or Ports, or adjusting the packet loss sliders), Godot seamlessly buffers this string over UDP to update Python's backend variables instantaneously without requiring a simulation restart.
4. **Execution Phase**: 
   - When the user clicks **Start Simulation**, Python is issued a command flag (`cmd=start`).
   - Python leverages the `WinDivert` native binary to hook Windows OS traffic below the application layer.
   - For every packet intercepted, Python evaluates the user-defined IP/Port/Protocol filters. Traffic bypassing these filters is instantaneously re-injected.
   - If trapped by the filters, Python applies probabilistic algorithmic variations: it rolls for Packet Loss (dropping), calculates static Latency, computes a uniform distribution for Jitter variation, delays the packet in a lightweight asynchronous thread, and then injects it.
5. **Real-time Journaling**: Python sends live string updates (`log=DROPPED;...`) tracking exact packet actions back to Godot, which dynamically manages color-coded visual logging and tallies real-time statistics of manipulated vs passed streams.

---

## Godot Frontend

The frontend is constructed with **Godot 4.6** Control nodes, ensuring a robust, scalable, and responsive application window.

### UI Components (`Entities/UI/`)
- **Dynamic Interface Selector**: Populated at runtime and updated periodically by Python to track active system adapters.
- **Smart Filter Settings (`filter_settings.tscn`)**: Utilizes `OptionButton` (dropdowns) containing dynamic relationships—selecting an IP actively triggers the backend to trim the subsequent Port and Protocol options down to only valid active configurations, preventing impossible filter combinations.
- **Modifiers**: SpinBoxes and interactive Sliders for configuring Packet Loss % (`packet_loss_probability.tscn`), Latency `ms` (`latency_settings.tscn`), and Jitter variation offsets (`jitter_settings.tscn`).
- **Packet Log & Stats Panel (`packet_log_display.tscn`)**: Subscribes to Python updates to print individual packet logs (Green = PASSED, Yellow = DELAYED, Red = DROPPED) alongside categorized data tallies.

### Godot Node Scripts
- **`main.gd`**: Automates process monitoring. Unpacks dense string payloads from Python (extracting parameters via string splitting), and governs inter-component State behavior linking the network backend to UI state switches.
- **`global.gd`**: Persistent Singleton holding runtime variables and shared references strictly loaded on boot.

---

## Python Backend & WinDivert

The backend acts as the true computational "muscle" of the application, running efficiently on a pure python architecture using `pydivert` native wrapper.

### Technical Implementation (`PythonFiles/`)
- **`main_loop.py`**: The structural baseline; launches daemons and connects the socket bindings.
- **`godot_connection.py`**: Drives multidirectional communication. Runs constant background threads tracking `psutil.net_connections` to analyze all real-time IP sockets currently connected on the Windows system, clamping packet size to prevent MTU overflow, and decoding UDP instructions.
- **`packet_capture.py`**: Hosts the `PacketCapture` handler class containing the explicit WinDivert loop.

### Network API via WinDivert
**WinDivert** (Windows Packet Divert) facilitates complete kernel-level OS abstraction.
When capturing:
1. It applies a baseline filter string directly (`not udp or (udp.SrcPort != 4242...)`) to mathematically guarantee our own local UDP handshakes between Godot and Python are invisible and protected from manipulation feedback loops.
2. Evaluates the deep-packet characteristics (Extracting `src_addr`, `dst_port`, `tcp`/`udp`) natively.
3. Leverages rapid discrete `Thread()` spawning for delayed latency injections. This thread isolation ensures that massive artificially-enforced 10,000ms ping delays do not clog the main WinDivert listening queue or accidentally drop parallel rapid packets!
4. Discarded packets simply circumvent `.send(packet)` leaving them permanently lost to the network stack.

---

## Communication Protocol

The Godot and Python nodes utilize customized delimited string formats passed over UDP local sockets for blazing-fast serialization without heavy overheads like JSON.

**Godot → Python (Configuration parameters):**
```text
ip=192.168.1.1;port=443;proto=tcp;iface_ip=192.168.1.5;loss=25.5;latency=100;jitter=10
```

**Python → Godot (Data Stream & Feedback):**
```text
hello
ifaces=Wi-Fi|192.168.1.5,VirtualBox|192.168.56.1
conns=192.168.1.5,443,TCP|127.0.0.1,8000,UDP
log=DROPPED;proto=TCP;src=192.168.1.5:54321;dst=142.250.190.46:443
log=DELAYED;proto=UDP;src=10.0.0.1:80;dst=1.1.1.1:1234;delay=114
stats=total:450;dropped:112;delayed:338;passed:0
error=Failed to start capture. Run as Administrator.
```

---

## Requirements & Setup

### For the Python Backend:
1. Ensure **Python 3.7+** is successfully installed and added to `PATH`.
2. Required OS-level manipulation and network packages:
   ```bash
   pip install pydivert psutil
   ```
3. **Administrator Privileges**: Because `WinDivert` requires deploying a Windows kernel driver (`WinDivert.sys`) and hooking the OS Network Stack deep inside user-mode components, **the program must run as an Administrator**. Standard executions will result in Access Denied exceptions.

### For Godot Editor:
* No external plugins natively required. Simply open `project.godot` inside **Godot 4.6** and hit play. If running outside the editor context, assure you right-click the exported application and "Run as Administrator".
