# TestC2

**TODO: Add description**

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/supported-targets.html

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix burn`

## Boot behavior

On device boot, the **LCD backlight** (GPIO 116) is set as output and driven high so the display is lit. This is done by `TestC2.LcdBacklight` (`lib/test_c2/lcd_backlight.ex`), started automatically by the application supervisor (targets only, not host).

## ILI9488 TFT modules

Three modules drive the ILI9488 TFT display and a GPIO indicator:

- **Ili9488.Driver** (`lib/test_c2/ili9488_driver.ex`) – SPI/GPIO setup, reset, init, and drawing (fill, rectangles).
- **Ili9488.GPIOMonitor** (`lib/test_c2/ili9488_gpio_monitor.ex`) – Monitors GPIO 71 and updates the on-screen indicator.
- **Ili9488.UI** (`lib/test_c2/ili9488_ui.ex`) – Draws the dashboard (blue background, textbox, "GPIO71" label, GPIO indicator).

Full documentation: [docs/ILI9488_MODULES.md](docs/ILI9488_MODULES.md)

### How to run (IEx)

On device (or `iex -S mix` on host):

```elixir
{:ok, devs} = Ili9488.Driver.start()
Ili9488.UI.draw_dashboard(devs)
Ili9488.GPIOMonitor.start(devs)
```

GPIO 71 is read every 500 ms; the indicator turns green when high and grey when low.

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Elixir Slack #nerves channel: https://elixir-slack.community/
  * Elixir Discord #nerves channel: https://discord.gg/elixir
  * Source: https://github.com/nerves-project/nerves
