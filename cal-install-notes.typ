#import "@preview/codly:1.3.0": *

#show: codly-init
#show link: it => if type(it.dest) == str {
  text(fill: aqua.darken(20%), underline(it))
} else {
  it
}

#align(center, text(size: 2em)[Calorimeter Installation])

The general goal is to make sure we can talk with all of the components involved.
We do this mainly by making sure the optical links lock with the frontend and we can do basic slow control functions (like putting an ECON or a HGCROC into run mode.

These notes were manually written by Tom Eichlersmith on #datetime.today().display() and so could have easily gone stale.

#outline()

#let alert(body) = {
  align(center,
    box(
      width: 80%,
      inset: 0.5em,
      fill: red.lighten(80%),
      stroke: red,
      align(left, body)
    )
  )
}

= Optical Link Check

#alert[
  The DAQ server is accessible at `srv-esa-nw01` and it is *not* connected to the internet.
  I put the following in my `~/.ssh/config` file so that you can access GitHub from the DAQ server.
  #box(fill: white)[
  ```
  # proxy jump for git commands on esa daq server
  Host github.com
    ProxyJump rdsrv401
  ```
  ]
]
#codly(
  annotation-format: (x) => {},
  annotations: (
    (start: 1, end: 1, content: [N is 1 for Ecal and 2 for Hcal]),
    (start: 4, end: 4, content: [only continue if `FULLSTATUS` is good]),
    (start: 6, end: 6, content: [should say "pause for DLL config"]),
    (start: 7, end: 7, content: [may need to do twice])
  )
)
```
./pflpgbt --bw 0 /dev/datadev_N
 > OPTO
 > FULLSTATUS
 > EXIT
 > GENERAL
 > STATUS
 > STANDARD_HCAL
 > EXIT
 > I2C
 > SCAN
```
and then check that basic slow control functions.
`CONFIG.yaml` is `config/pftool/ecal-ssm-bittware-slac-lab.yaml` for Ecal and `config/path/hcal-backplane-esa.yaml` for Hcal.
```
./pftool CONFIG.yaml
 > ECON
 > STATUS
 > RUNMODE
 > EXIT
 > ROC
 > RUNMODE
```
Talking is not working if the I2C transactions fail when attempting to do these motions.

== What to do when it doesn't work
*Power Cycle*: Power off the front end, issue a `OPTO.RESET` from within `pflpgbt`, and then power the front-end back on.

*Disconnect*: Unplug the optical fiber in the alcove, issue a `OPTO.RESET` from within `pflpgbt`, and then plug the fiber back into the cassette.

*Double Check Power*: The most obvious mistake has happened a lot. For the Hcal, the LV needs to be on and it should be in Constant Voltage (CV). If the Constant Current (CC) light is flashing, then more current is being drawn that the supply's configured limit. For the Ecal, if the 3.3V input on the motherboard only gets 1.5V, the lpGBT does not recieve enough power and will not connect. Double check the correct cords are plugged into the correct ports on the DC/DC board stack in the alcove.

== Acronyms/Shortnames
- LV: Low Voltage
- HV: High Voltage
- Link 0: The zero'th indexed link of the data fibers. Labeled 1-2 on the optical fiber cassette that's in the alcove with the detectors.

== `OPTO.FULLSTATUS` Annotated
#codly(
  highlights: (
    (line: 3, start: 26, end: none, fill: green),
    (line: 4, start: 26, end: none, fill: yellow),
    (line: 6, start: 26, end: none, fill: green),
    (line: 12, start: 26, end: none, fill: green),
  )
)
```shell
Polarity -- TX: 0  RX: 0
Optical status:
  BUFFBYPASS_DONE      : 0x0001 # needs to be 1
  BUFFBYPASS_ERROR     : 0x0000 # should be 0, made due with 1
  CDR_STABLE           : 0x0001 
  READY                : 0x0001 # needs to be 1
  RX_RESETDONE         : 0x0001
  TX_RESETDONE         : 0x0001
  Optical rates:
  BX_CLK               : 37.143 MHz (0x9117)
  LCLS2_CLK            : 185.718 MHz (0x2d576)
  LINK_ERROR           : 0.000 MHz (0x0000) # should be 0
  LINK_WORD            : 37.143 MHz (0x9117)
  REF_CLK              : 297.149 MHz (0x488bd)
  RX-LINK              : 297.149 MHz (0x488bd)
  S_AXI_ACLK           : 125.000 MHz (0x1e848)
  TX_CLK               : 297.149 MHz (0x488bd)
```

= Hcal
The test installation was easy for the HCal and I expect it to be easy for the real installation as well.
I plugged in the LV and the data fiber and then opened pflpgbt to check the status.
I did not test the HV connection.

#alert[
== Biggest Concern
It didn't appear like the power supplies for the HCal are remotely-operable. *How will we power cycle the Hcal when we are not allowed inside ESA?*
]

= Ecal
Talking to the Ecal is unfortunately a bit more complicated.
*We have not talked via more than one optical link at once.*
This means do the same test above (but with the `0` changed to `1` or `2`) will not work unless we are super lucky.
We can at least make sure that all of the frontend layers are working by checking each of them on link 0.
Basically, do the same test as above (with the Ecal arguments) and just swap the data fibers for each layer into link 0 to make sure they all function individually.

#alert[
== Biggest Concern
We are able to power cycle the Ecal remotely, so the biggest concern is just getting the software/firmware to the point of support multiple-links. I'm not sure how far off it is, we prepared the software/firmware to be able to support multiple-links, so it could (hopefully) be just a few address-corrections away from working.
]

== Powering
With the Ecal LV connected to the MPOD, we are able to control it remotely using net-snmp and a python script that Matt Gignac and I have developed. #link("https://github.com/tomeichlersmith/mpod_control/")[tomeichlersmith/mpod_control]
I've already done the setup on the SLAC DAQ server, so you just need to `git clone` this repository to access the `mpod_control.py` file.

We have not even connected the Ecal HV lines to the modules. I believe it is feasible to partially disassemble the Ecal in order to connect the HV lines, but I also think we can get plenty out of this beam test without the HV connected. *Tamas -- I am leaving it up to you to decide.*
If you have time to connect the HV line and run it to the MPOD, then go for it. My priority is just being able to talk to the Ecal (or at least one Ecal layer) so we can exercise our DAQ infrastructure.

== `I2C.SCAN`
The output of `I2C.SCAN` of bus 1 is below for each layer for reference. Some motherboards are not talking to the ECON-T (24) or are missing some ROCs (right hand side), but they all are able to talk to the ECON-D.

=== L0
```
00 -- -- -- -- -- -- -- -- 08 09 0a 0b 0c 0d 0e 0f 
10 -- -- -- -- -- -- -- -- 18 19 1a 1b 1c 1d 1e 1f 
20 -- -- -- -- 24 -- -- -- 28 29 2a 2b 2c 2d 2e 2f 
30 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40 -- -- -- -- -- -- -- -- 48 49 4a 4b 4c 4d 4e 4f 
50 -- -- -- -- -- -- -- -- 58 59 5a 5b 5c 5d 5e 5f 
60 -- -- -- -- 64 -- -- -- 68 69 6a 6b 6c 6d 6e 6f 
70 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
```

=== L1
```
00 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
10 -- -- -- -- -- -- -- -- 18 19 1a 1b 1c 1d 1e 1f 
20 -- -- -- -- -- -- -- -- 28 -- -- 2b 2c -- 2e 2f 
30 -- 31 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40 -- -- -- -- -- -- -- -- 48 49 4a 4b 4c 4d 4e 4f 
50 -- -- -- -- -- -- -- -- 58 59 5a 5b 5c 5d 5e 5f 
60 -- -- -- -- 64 -- -- -- 68 69 6a 6b 6c 6d 6e 6f 
70 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
```

=== L3
```
00 -- -- -- -- -- -- -- -- 08 09 0a 0b 0c 0d 0e 0f 
10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20 -- -- -- -- -- -- -- -- 28 29 2a 2b 2c 2d 2e 2f 
30 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40 -- -- -- -- -- -- -- -- 48 49 4a 4b 4c 4d 4e 4f 
50 -- -- -- -- -- -- -- -- 58 59 5a 5b 5c 5d 5e 5f 
60 -- -- -- -- 64 -- -- -- 68 69 6a 6b 6c 6d 6e 6f 
70 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
```

