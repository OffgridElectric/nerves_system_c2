defmodule Ili9488.Driver do
  import Bitwise

  @tft_cs   114
  @tft_dc   76
  @tft_rst  74
  @spi_device "spidev1.0"

  @spi_opts [mode: 0, bits_per_word: 8, speed_hz: 20_000_000]

  @width 320
  @height 480

  @cmd_column_address 0x2A
  @cmd_page_address   0x2B
  @cmd_memory_write   0x2C

  def start do
    {:ok, spi} = Circuits.SPI.open(@spi_device, @spi_opts)
    {:ok, cs}  = Circuits.GPIO.open(@tft_cs, :output)
    {:ok, dc}  = Circuits.GPIO.open(@tft_dc, :output)
    {:ok, rst} = Circuits.GPIO.open(@tft_rst, :output)

    devs = %{spi: spi, cs: cs, dc: dc, rst: rst}

    Circuits.GPIO.write(cs, 1)
    reset_display(devs)
    init_display(devs)

    {:ok, devs}
  end

  defp reset_display(devs) do
    Circuits.GPIO.write(devs.rst, 0)
    Process.sleep(50)
    Circuits.GPIO.write(devs.rst, 1)
    Process.sleep(120)
  end

  # Init sequence (gamma, power, VCOM, etc.) uses register values from ESP32
  # ILI9488 driver reference. Adjust if colours or brightness need tuning.
  defp init_display(devs) do
  # Soft Reset
  send_command(devs, 0x01)
  Process.sleep(10)

  # Exit Sleep
  send_command(devs, 0x11)
  Process.sleep(120)

  # Display inversion ON
  send_command(devs, 0x21)

  # Positive Gamma (0xE0) – 15 bytes. Values from ESP32 ILI9488 reference.
  send_command(devs, 0xE0)
  Enum.each([0x00,0x03,0x09,0x08,0x16,0x0A,0x3F,0x78,0x4C,0x09,0x0A,0x08,0x16,0x1A,0x0F],
    &send_data(devs, <<&1>>))

  # Negative Gamma (0xE1) – 15 bytes. Values from ESP32 ILI9488 reference.
  send_command(devs, 0xE1)
  Enum.each([0x00,0x16,0x19,0x03,0x0F,0x05,0x32,0x45,0x46,0x04,0x0E,0x0D,0x35,0x37,0x0F],
    &send_data(devs, <<&1>>))

  # Power control
  send_command(devs, 0xC0)
  Enum.each([0x17,0x15], &send_data(devs, <<&1>>))

  send_command(devs, 0xC1)
  send_data(devs, <<0x41>>)

  # VCOM
  send_command(devs, 0xC5)
  Enum.each([0x00,0x12,0x80], &send_data(devs, <<&1>>))

  # MADCTL
  send_command(devs, 0x36)
  send_data(devs, <<0x48>>)

  # RGB666 SPI
  send_command(devs, 0x3A)
  send_data(devs, <<0x66>>)
  Process.sleep(10)

  # Interface control
  send_command(devs, 0xB0)
  send_data(devs, <<0x00>>)

  send_command(devs, 0xB1)
  send_data(devs, <<0xA0>>)

  send_command(devs, 0xB4)
  send_data(devs, <<0x02>>)

  send_command(devs, 0xB6)
  Enum.each([0x02,0x02,0x3B], &send_data(devs, <<&1>>))

  send_command(devs, 0xB7)
  send_data(devs, <<0xC6>>)

  send_command(devs, 0xF7)
  Enum.each([0xA9,0x51,0x2C,0x82], &send_data(devs, <<&1>>))

  # Display ON
  send_command(devs, 0x29)
  Process.sleep(25)
end


  def fill_blue(devs), do: fill_color(devs, <<0, 0, 255>>)

  def fill_color(devs, pixel) do
    set_window(devs, 0, 0, @width - 1, @height - 1)
    send_command(devs, @cmd_memory_write)
    send_pixels(devs, pixel, @width * @height)
  end

  def draw_rect(devs, x, y, w, h, color) do
    set_window(devs, x, y, x + w - 1, y + h - 1)
    send_command(devs, @cmd_memory_write)
    send_pixels(devs, color, w * h)
  end

  defp set_window(devs, x1, y1, x2, y2) do
    send_command(devs, @cmd_column_address)
    send_data(devs, <<x1>>>8, x1 &&& 0xFF, x2>>>8, x2 &&& 0xFF>>)

    send_command(devs, @cmd_page_address)
    send_data(devs, <<y1>>>8, y1 &&& 0xFF, y2>>>8, y2 &&& 0xFF>>)
  end

  defp send_pixels(_devs, _pixel, 0), do: :ok
  defp send_pixels(devs, pixel, count) do
    chunk = min(count, 341)
    send_data(devs, :binary.copy(pixel, chunk))
    send_pixels(devs, pixel, count - chunk)
  end

  defp send_command(devs, cmd) do
    Circuits.GPIO.write(devs.cs, 0)
    Circuits.GPIO.write(devs.dc, 0)
    Circuits.SPI.transfer!(devs.spi, <<cmd>>)
    Circuits.GPIO.write(devs.cs, 1)
  end

  defp send_data(devs, data) do
    Circuits.GPIO.write(devs.cs, 0)
    Circuits.GPIO.write(devs.dc, 1)
    Circuits.SPI.transfer!(devs.spi, data)
    Circuits.GPIO.write(devs.cs, 1)
  end
end
