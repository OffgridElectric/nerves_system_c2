defmodule Ili9488 do
  import Bitwise

    # For C2 V2  spidev1.0
    @tft_cs   114  # Chip Select GPIO
    @tft_dc   76   # Data/Command GPIO
    @tft_rst  74   # Reset GPIO
    @spi_device "spidev1.0"

  @spi_opts [mode: 0, bits_per_word: 8, speed_hz: 1_000_000]

  @width  320
  @height 480

  # Commands
  @cmd_column_address 0x2A
  @cmd_page_address   0x2B
  @cmd_memory_write   0x2C
  @cmd_memory_access  0x36
  @cmd_pixel_format   0x3A

  # -----------------------
  # Start / init
  # -----------------------
  def start do
    {:ok, spi} = Circuits.SPI.open(@spi_device, @spi_opts)
    {:ok, cs}  = Circuits.GPIO.open(@tft_cs, :output)
    {:ok, dc}  = Circuits.GPIO.open(@tft_dc, :output)
    {:ok, rst} = Circuits.GPIO.open(@tft_rst, :output)

    devs = %{spi: spi, cs: cs, dc: dc, rst: rst}

    Circuits.GPIO.write(cs, 1)
    reset_display(devs)
    new_init_display(devs)
    {:ok, devs}
  end

  defp reset_display(devs) do
    Circuits.GPIO.write(devs.rst, 0)
    :timer.sleep(50)
    Circuits.GPIO.write(devs.rst, 1)
    :timer.sleep(120)
  end

  defp new_init_display(devs) do
  # Soft Reset
  send_command(devs, 0x01)
  :timer.sleep(10)

  # Exit Sleep
  send_command(devs, 0x11)
  :timer.sleep(120)

  # --- Positive Gamma Control ---
  send_command(devs, 0xE0)
  Enum.each([0x00,0x03,0x09,0x08,0x16,0x0A,0x3F,0x78,0x4C,0x09,0x0A,0x08,0x16,0x1A,0x0F],
    fn d -> send_data(devs, <<d>>) end)

  # --- Negative Gamma Control ---
  send_command(devs, 0xE1)
  Enum.each([0x00,0x16,0x19,0x03,0x0F,0x05,0x32,0x45,0x46,0x04,0x0E,0x0D,0x35,0x37,0x0F],
    fn d -> send_data(devs, <<d>>) end)

  # --- Power Control 1 ---
  send_command(devs, 0xC0)
  Enum.each([0x17,0x15], fn d -> send_data(devs, <<d>>) end)

  # --- Power Control 2 ---
  send_command(devs, 0xC1)
  send_data(devs, <<0x41>>)

  # --- VCOM Control ---
  send_command(devs, 0xC5)
  Enum.each([0x00,0x12,0x80], fn d -> send_data(devs, <<d>>) end)

  # --- Memory Access Control ---
  send_command(devs, 0x36)
  send_data(devs, <<0x48>>)  # MX + BGR panel

  # --- Pixel Format (18-bit SPI) ---
  send_command(devs, 0x3A)
  send_data(devs, <<0x66>>)  # RGB666, 3 bytes/pixel
  :timer.sleep(10)

  # --- Interface Mode Control ---
  send_command(devs, 0xB0)
  send_data(devs, <<0x00>>)

  # --- Frame Rate Control ---
  send_command(devs, 0xB1)
  send_data(devs, <<0xA0>>)

  # --- Display Inversion Control ---
  send_command(devs, 0xB4)
  send_data(devs, <<0x02>>)

  # --- Display Function Control ---
  send_command(devs, 0xB6)
  Enum.each([0x02,0x02,0x3B], fn d -> send_data(devs, <<d>>) end)

  # --- Entry Mode Set ---
  send_command(devs, 0xB7)
  send_data(devs, <<0xC6>>)

  # --- Adjust Control 3 ---
  send_command(devs, 0xF7)
  Enum.each([0xA9,0x51,0x2C,0x82], fn d -> send_data(devs, <<d>>) end)

  # --- Turn on display ---
  send_command(devs, 0x29)
  :timer.sleep(25)
end

  
  # -----------------------
  # Fill colors
  # -----------------------

  def fill_red(devs),   do: fill_color(devs, <<0xFF, 0x00, 0x00>>)
  def fill_green(devs), do: fill_color(devs, <<0x00, 0xFF, 0x00>>)
  def fill_blue(devs),  do: fill_color(devs, <<0x00, 0x00, 0xFF>>)
  def fill_white(devs), do: fill_color(devs, <<0xFF, 0xFF, 0xFF>>)

  defp fill_color(devs, pixel_3b) when byte_size(pixel_3b) == 3 do
    send_command(devs, @cmd_column_address)
    send_data(devs, <<0x00, 0x00, (@width-1) >>> 8, (@width-1) &&& 0xFF>>)

    send_command(devs, @cmd_page_address)
    send_data(devs, <<0x00, 0x00, (@height-1) >>> 8, (@height-1) &&& 0xFF>>)

    send_command(devs, @cmd_memory_write)

    total_pixels = @width * @height
    chunk_pixels = 341

    send_pixels(devs, pixel_3b, total_pixels, chunk_pixels)
  end

  defp send_pixels(_devs, _pixel, 0, _chunk_pixels), do: :ok
  defp send_pixels(devs, pixel, pixels_left, chunk_pixels) do
    count = min(pixels_left, chunk_pixels)
    chunk = :binary.copy(pixel, count)
    safe_send_data(devs, chunk)
    send_pixels(devs, pixel, pixels_left - count, chunk_pixels)
  end

  defp safe_send_data(devs, data) do
    try do
      send_data(devs, data)
      :ok
    rescue
      e -> {:error, e}
    end
  end

  # -----------------------
  # SPI helpers
  # -----------------------
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

  def close(devs) do
    Circuits.SPI.close(devs.spi)
    Circuits.GPIO.close(devs.cs)
    Circuits.GPIO.close(devs.dc)
    Circuits.GPIO.close(devs.rst)
  end

  # -----------------------
  # Rectangle test
  # -----------------------
  @doc """
  Draws a rectangle at (x, y) with width w and height h, color in RGB666 3 bytes.
  """
  def test_rect(devs, x, y, w, h, color_3b) when byte_size(color_3b) == 3 do
    x_end = x + w - 1
    y_end = y + h - 1

    send_command(devs, @cmd_column_address)
    send_data(devs, <<x >>> 8, x &&& 0xFF, x_end >>> 8, x_end &&& 0xFF>>)

    send_command(devs, @cmd_page_address)
    send_data(devs, <<y >>> 8, y &&& 0xFF, y_end >>> 8, y_end &&& 0xFF>>)

    send_command(devs, @cmd_memory_write)

    total_pixels = w * h
    send_data(devs, :binary.copy(color_3b, total_pixels))
  end
end
