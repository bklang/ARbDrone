ARbDrone
========

Ruby Library for the Parrot AR.Drone
------------------------------------

ARbDrone is a native Ruby implementation of the protocols necessary to control
the [Parrot AR.Drone](http://ardrone.parrot.com/).

This library is brand new and will take some time to mature.  Current work
is focused around the flight control commands and navdata.  Video support
is not likely to appear for some time.


Tools for Debugging
-------------------

During the development of this library it became necessary to reverse engineer
parts of the AR.Drone protocol, particularly the parts whose documentation
was lacking.  I have included a tool that can read PCAP-format network traces
and print the activities sent to the drone as well as the navdata received
from the drone.  Here's an example from a very short flight (note the crash
right at the end :)

```
$ bundle exec bin/pcap-trace.rb ~/ardrone-3.pcap 
AT*PMODE=1,2
AT*MISC=2,2,20,2000,3000
Steering Progressive: Phi: 0% Theta: 0% Yaw: 0% Gaz: 0%
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_id to -all
-----------
vision is now 1
altitude is now 1
command is now 1
navdata_bootstrap is now 1
pic_version is now 1
atcodec_thread_on is now 1
navdata_thread_on is now 1
video_thread_on is now 1
acq_thread_on is now 1
com_watchdog is now 1
-----------
Control: ack
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: get_cfg
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: custom_cfg_get
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_id to 4fe688f8
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_id to 4fe688f8
-----------
command is now 1
-----------
Control: ack
-----------
command is now 0
-----------
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:application_id to 9a760c9b
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:application_id to 9a760c9b
-----------
command is now 1
-----------
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:application_id to 9a760c9b
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_desc to Session 4fe688f8
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Control: get_cfg
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Control: custom_cfg_get
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_id to 4fe688f8
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:application_id to 9a760c9b
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_desc to Session 4fe688f8
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Control: get_cfg
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting general:navdata_demo to FALSE
-----------
navdata_bootstrap is now 0
-----------
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
Communications watchdog reset
-----------
command is now 0
com_watchdog is now 0
-----------
Control: ack
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting custom:session_id to 4fe688f8
Communications watchdog reset
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Activating configuration for session "4fe688f8", user "00000000" and application "9a760c9b"
Setting general:navdata_demo to FALSE
-----------
command is now 1
-----------
Control: ack
Control: ack
Control: ack
-----------
command is now 0
-----------
Control: ack
Control: ack
Steering Progressive: Phi: 0% Theta: 0% Yaw: 0% Gaz: 0%
-----------
flying is now 1
user_feedback_start is now 1
-----------
Steering Progressive: Phi: 0% Theta: 0% Yaw: 0% Gaz: 0%
Found invalid options id: 0x66
Found invalid options id: 0x95
Found invalid options id: 0x5a
Found invalid options id: 0x17
Found invalid options id: 0x77
Found invalid options id: 0x21
Found invalid options id: 0x81
Found invalid options id: 0x60
Found invalid options id: 0x6f
Found invalid options id: 0x70
Found invalid options id: 0x74
Found invalid options id: 0x7d
Found invalid options id: 0x84
Steering Progressive: Phi: 3% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 19% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 32% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 40% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 48% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 55% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 65% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 71% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 76% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 77% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 79% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 74% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 69% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 53% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 37% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 0% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -19% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -43% Theta: 0% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -98% Theta: -23% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -39% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -40% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -37% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -34% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -31% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -30% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -100% Theta: -28% Yaw: 0% Gaz: 0%
-----------
flying is now 0
user_feedback_start is now 0
cutout is now 1
emergency is now 1
-----------
Steering Progressive: Phi: -100% Theta: -25% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: -74% Theta: -2% Yaw: 0% Gaz: 0%
Steering Progressive: Phi: 0% Theta: 0% Yaw: 0% Gaz: 0%
-----------
angles_out_of_range is now 1
-----------
-----------
timer_elapsed is now 1
-----------
```
Note the "Invalid Options ID" messages were from a single corrupt UDP
packet that was received during flight.
