# Wavefront Routing Fabric

A cellular-automata-inspired spatial routing fabric implemented in Verilog and synthesized using OpenLane and the SKY130 PDK.

## Overview

This project explores distributed shortest-path computation using a massively parallel wavefront propagation architecture.

Each processing element (PE):
- observes neighboring costs
- computes minimum-distance propagation
- evolves synchronously across the fabric

The result is an emergent hardware routing system capable of:
- shortest-path generation
- obstacle-aware propagation
- distributed spatial computation

---

## Features

- Distributed wavefront routing
- Obstacle-aware propagation
- Cellular automata-inspired architecture
- Parallel spatial computation
- Fully synthesizable Verilog RTL
- OpenLane ASIC flow
- SKY130 physical implementation

---

## Repository Structure

- rtl/ → Verilog RTL
- testbench/ → routing simulations
- gds/ → final ASIC layouts
- animations/ → wavefront propagation GIFs
- docs/ → architectural writeups
- openlane/ → ASIC synthesis configuration

---

## Physical Design

Generated using:
- OpenLane
- SKY130 PDK
- KLayout

---

## Author

Abhinav Basu
