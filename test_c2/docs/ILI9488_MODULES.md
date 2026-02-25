# ILI9488 TFT Modules

Documentation for the three modules that drive the ILI9488 TFT display and GPIO indicator on the test_c2 Nerves app.

---

## Module overview

| Module | File | Purpose |
|--------|------|--------|
| **Ili9488.Driver** | `lib/test_c2/ili9488_driver.ex` | Low-level SPI/GPIO control: open device, reset, init, set window, fill/draw rectangles. |
| **Ili9488.GPIOMonitor** | `lib/test_c2/ili9488_gpio_monitor.ex` | Background loop that reads GPIO 71 and updates the display when the value changes. |
| **Ili9488.UI** | `lib/test_c2/ili9488_ui.ex` | Screen layout: dashboard (blue background, textbox, "GPIO71" label, GPIO indicator). |

---

## Ili9488.Driver

**Role:** Hardware interface for the ILI9488 TFT over SPI and GPIO (CS, DC, RST).

**Configuration:**
- SPI device: `spidev1.0`, mode 0, 8 bits, 20 MHz
- GPIOs: CS = 114, DC = 76, RST = 74
- Resolution: 320×480, pixel format RGB666

**Main API:**

| Function | Description |
|----------|-------------|
| `start/0` | Opens SPI and GPIOs, resets and initializes the display. Returns `{:ok, devs}`. Pass `devs` into all other drawing functions. |
| `fill_blue/1` | Fills the entire screen blue. |
| `fill_color/2` | Fills the entire screen with a given RGB pixel binary (e.g. `<<r, g, b>>`). |
| `draw_rect/6` | Draws a rectangle at `(x, y)` with size `(w, h)` in the given color. |

**Internals:** Sends the ILI9488 init sequence (soft reset, exit sleep, gamma, power, MADCTL, pixel format, etc.), then uses column/page address and memory-write commands for drawing.

---

## Ili9488.GPIOMonitor

**Role:** Monitors GPIO 71 and refreshes the on-screen GPIO indicator when the value changes.

**Behavior:** Opens GPIO 71 as input, spawns a loop that reads the pin every 500 ms and, when the value differs from the last read, calls `Ili9488.UI.draw_gpio_indicator/2`.

**API:**

| Function | Description |
|----------|-------------|
| `start/1` | Takes the `devs` map from `Ili9488.Driver.start/0` and starts the monitor process. Returns the PID of the spawned process. |

---

## Ili9488.UI

**Role:** Builds the screen layout and keeps the GPIO indicator in sync with hardware.

**Behavior:**
- **`draw_dashboard/1`** – Draws the full UI: blue background, white textbox outline, "GPIO71" label (drawn with rectangles), and the initial GPIO indicator (OFF = grey).
- **`draw_gpio_indicator/2`** – Draws a small rectangle under the label: green when GPIO is high (1), grey when low (0). Called by `Ili9488.GPIOMonitor` when the pin state changes.

**Dependencies:** Uses `Ili9488.Driver` for `fill_blue/1` and `draw_rect/6`.

---

## How to run

**Prerequisites:** Nerves firmware with SPI and GPIO (e.g. BB-SPIDEV1 / zola overlay) and the ILI9488 wired to the correct pins.

### Option A – Run manually in IEx

On the device (or `iex -S mix` on host):

```elixir
# Start driver (opens SPI/GPIO, resets and inits display)
{:ok, devs} = Ili9488.Driver.start()

# Draw the dashboard (blue screen + textbox + "GPIO71" label + indicator)
Ili9488.UI.draw_dashboard(devs)

# Start GPIO monitor (polls GPIO 71 every 500 ms and updates the indicator)
Ili9488.GPIOMonitor.start(devs)
```

### Option B – One-liner

```elixir
{:ok, devs} = Ili9488.Driver.start()
Ili9488.UI.draw_dashboard(devs)
Ili9488.GPIOMonitor.start(devs)
```

### Option C – Start from application

To have the display and monitor start on boot, add a worker under `target_children()` in `lib/test_c2/application.ex` that starts the driver, draws the dashboard, then starts the GPIO monitor (e.g. a small GenServer or Task that runs the three steps above).

---

**Note:** GPIO 71 is read every 500 ms; the on-screen indicator turns **green** when high and **grey** when low.

### Testing: change GPIO 71 status manually

Start the display and monitor, then from the same IEx console open GPIO 71 as output and toggle it. The on-screen indicator updates when the monitor (polling every 500 ms) sees the change:

```elixir
# 1) Start display and monitor
{:ok, devs} = Ili9488.Driver.start()
Ili9488.UI.draw_dashboard(devs)
Ili9488.GPIOMonitor.start(devs)

# 2) Toggle GPIO 71 from the console (indicator goes green/grey)
{:ok, g} = Circuits.GPIO.open(71, :output)
Circuits.GPIO.write(g, 1)   # green
Circuits.GPIO.write(g, 0)   # grey
Circuits.GPIO.read(g)
```
