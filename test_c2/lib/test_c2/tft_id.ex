defmodule TFTTest do
  import Bitwise   # for <<< and |||

  @spi_opts [mode: 0, bits_per_word: 8, speed_hz: 1_000_000]
  # For C2 V2  spidev1.0
  @tft_cs   114  # Chip Select GPIO
  @tft_dc   76   # Data/Command GPIO
  @tft_rst  74   # Reset GPIO
  @spi_device "spidev1.0"

  def start do
    # Open SPI
    {:ok, spi} = Circuits.SPI.open(@spi_device, @spi_opts)

    # Setup GPIOs
    {:ok, cs}  = Circuits.GPIO.open(@tft_cs, :output)
    {:ok, dc}  = Circuits.GPIO.open(@tft_dc, :output)
    {:ok, rst} = Circuits.GPIO.open(@tft_rst, :output)

    # Reset sequence
    Circuits.GPIO.write(cs, 1)   # deselect at idle
    Circuits.GPIO.write(dc, 1)
    Circuits.GPIO.write(rst, 0)
    Process.sleep(20)
    Circuits.GPIO.write(rst, 1)
    Process.sleep(150)

    IO.puts("Reading ILI9488 registers...")

    id         = tft_read_register(spi, cs, dc, 0x04, 3)
    status     = tft_read_register(spi, cs, dc, 0x09, 4)
    power_mode = tft_read_register(spi, cs, dc, 0x0A, 1)
    madctl     = tft_read_register(spi, cs, dc, 0x0B, 1)
    pixel_fmt  = tft_read_register(spi, cs, dc, 0x0C, 1)

    IO.puts("Display ID (0x04): 0x#{Integer.to_string(id, 16)}")
    IO.puts("Display Status (0x09): 0x#{Integer.to_string(status, 16)}")
    IO.puts("Power Mode (0x0A): 0x#{Integer.to_string(power_mode, 16)}")
    IO.puts("MADCTL (0x0B): 0x#{Integer.to_string(madctl, 16)}")
    IO.puts("Pixel Format (0x0C): 0x#{Integer.to_string(pixel_fmt, 16)}")

    set_rotation(spi, cs, dc, 0x28)
    Process.sleep(1000)

    madctl2 = tft_read_register(spi, cs, dc, 0x0B, 1)
    IO.puts("MADCTL (0x0B): 0x#{Integer.to_string(madctl2, 16)}")
  end

  defp tft_read_register(spi, cs, dc, reg, bytes_to_read) do
    Circuits.GPIO.write(cs, 0)
    Circuits.GPIO.write(dc, 0)
    Circuits.SPI.transfer(spi, <<reg>>)

    Circuits.GPIO.write(dc, 1)
    Circuits.SPI.transfer(spi, <<0x00>>) # Dummy read

    result =
      for _ <- 1..bytes_to_read, reduce: 0 do
        acc ->
          {:ok, <<val>>} = Circuits.SPI.transfer(spi, <<0x00>>)
          (acc <<< 8) ||| val
      end

    Circuits.GPIO.write(cs, 1)
    result
  end

  defp set_rotation(spi, cs, dc, rotation) do
    Circuits.GPIO.write(cs, 0)
    Circuits.GPIO.write(dc, 0)
    Circuits.SPI.transfer(spi, <<0x36>>)  # MADCTL command
    Circuits.GPIO.write(dc, 1)
    Circuits.SPI.transfer(spi, <<rotation>>)
    Circuits.GPIO.write(cs, 1)
  end
end
