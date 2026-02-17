defmodule Ili9488.GPIOMonitor do
  alias Ili9488.UI

  def start(devs) do
    {:ok, gpio} = Circuits.GPIO.open(71, :input)

    spawn(fn -> loop(devs, gpio, nil) end)
  end

  defp loop(devs, gpio, last) do
    state = Circuits.GPIO.read(gpio)

    if state != last do
      UI.draw_gpio_indicator(devs, state)
    end

    Process.sleep(500)
    loop(devs, gpio, state)
  end
end
