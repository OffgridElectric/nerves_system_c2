defmodule Ili9488.UI do
  alias Ili9488.Driver

  # -----------------------
  # Dashboard layout
  # -----------------------
  def draw_dashboard(devs) do
    Driver.fill_blue(devs)

    textbox(devs, 10, 70, 140, 150)

    draw_gpio71_label(devs)
    draw_gpio_indicator(devs, 0) # initial OFF state
  end

  # -----------------------
  # GPIO indicator (UNDER label)
  # -----------------------
  def draw_gpio_indicator(devs, state) do
    color =
      case state do
        1 -> <<0, 255, 0>>       # ON
        _ -> <<80, 80, 80>>      # OFF (grey)
      end

    # draw below label
    Driver.draw_rect(devs, 40, 105, 30, 30, color)
  end

  # -----------------------
  # Textbox helper
  # -----------------------
  defp textbox(devs, x, y, w, h) do
    color = <<255, 255, 255>>

    Driver.draw_rect(devs, x, y, w, 2, color)
    Driver.draw_rect(devs, x, y + h - 2, w, 2, color)
    Driver.draw_rect(devs, x, y, 2, h, color)
    Driver.draw_rect(devs, x + w - 2, y, 2, h, color)
  end

  # -----------------------
  # GPIO71 label
  # -----------------------
  defp draw_gpio71_label(devs) do
  color = <<255, 255, 255>>

  # G
  Driver.draw_rect(devs, 20, 80, 12, 2, color)
  Driver.draw_rect(devs, 20, 80, 2, 14, color)
  Driver.draw_rect(devs, 20, 92, 12, 2, color)
  Driver.draw_rect(devs, 28, 88, 4, 2, color)
  Driver.draw_rect(devs, 30, 88, 2, 6, color)

  # P
  Driver.draw_rect(devs, 38, 80, 2, 14, color)
  Driver.draw_rect(devs, 38, 80, 10, 2, color)
  Driver.draw_rect(devs, 48, 80, 2, 6, color)
  Driver.draw_rect(devs, 38, 86, 10, 2, color)

  # I
  Driver.draw_rect(devs, 56, 80, 2, 14, color)

  # O
  Driver.draw_rect(devs, 64, 80, 12, 2, color)
  Driver.draw_rect(devs, 64, 92, 12, 2, color)
  Driver.draw_rect(devs, 64, 80, 2, 14, color)
  Driver.draw_rect(devs, 74, 80, 2, 14, color)

  # 7
  Driver.draw_rect(devs, 82, 80, 12, 2, color)
  Driver.draw_rect(devs, 92, 80, 2, 14, color)

  # 1
  Driver.draw_rect(devs, 100, 80, 2, 14, color)
  end

end
