# c64-demos

A collection of programs demonstrating the basic capabilities of the Commodore 64 8-bit computer.  
This repo is primarily intended for students of my retro coding lab course, but outsiders are of course welcome.

The individual demos can be built using the Nix build system.

Currently supported are:

| Demo                | Build command                    | Target system | Description                                                                                                                                                                                                                                                                                             |
| ------------------- | -------------------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Kneedeep in 3D      | `nix build .#kneedeepin3d`       | c64           | Using sprites as canvases for 3D rendering. Showing that while 3D can be done on the Commodore 8-bit line, it is best avoided for performance reasons.                                                                                                                                                  |
| Multisprite         | `nix build .#multisprite`        | c64           | A demonstration showing how to combine multiple sprites into one character.                                                                                                                                                                                                                                      |
| Sprite multiplexing | `nix build .#spritemultiplexing` | c64           | A demonstration showing how to display more than 8 sprites at once using sprite multiplexing                                                                                                                                                                                                                     |
| Paddle smoothing    | `nix build .#paddlesmoothing`    | c64           | A demonstration of different smoothing algorithms using a paddle as input and bar graphs as displays. From left to right the bars represent. The raw paddle readout, the paddle readout scaled to fit the screen height, the paddle value after applying the simple moving average smoothing algorithm. |
| Random              | `nix build .#random`             | c64           | A visual comparison of the SID voice 3 noise output, the mid-square algorithm seeded with voice 3 noise, and a linear feedback shift register seeded with voice 3 noise. Intended as an aid to determine a suitable random number generator algorithm for your project. |

If there are problems, feel free to open issues.

Llamato / Tina
