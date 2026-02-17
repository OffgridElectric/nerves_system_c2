defmodule TestC2.LcdBacklight do
  @moduledoc """
  Turns on the LCD backlight (GPIO 116) at application boot and keeps it on.
  Runs only on device targets (e.g. C2), not on host.
  """
  use GenServer

  @gpio_backlight 116

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    case Circuits.GPIO.open(@gpio_backlight, :output) do
      {:ok, ref} ->
        Circuits.GPIO.write(ref, 1)
        {:ok, %{gpio: ref}}
      {:error, _} = err ->
        err
    end
  end
end
