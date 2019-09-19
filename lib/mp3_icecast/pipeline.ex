defmodule Mp3Icecast.Pipeline do
  use Membrane.Pipeline

  def handle_init(path_to_mp3) do
    children = [
      # Stream from file
      file_src: %Membrane.Element.File.Source{location: path_to_mp3},
      # Decode frames
      decoder: Membrane.Element.Mad.Decoder,
      # Convert Raw :s24le to Raw :s16le
      converter: %Membrane.Element.FFmpeg.SWResample.Converter{
        output_caps: %Membrane.Caps.Audio.Raw{
          format: :s16le,
          sample_rate: 48000,
          channels: 2
        }
      },
      lame: Membrane.Element.Lame.Encoder,
      # Stream data into PortAudio to play it on speakers.
      sink: %Membrane.Element.Shout.Sink{
        host: "localhost",
        port: 8000,
        password: "hackme",
        mount: "/stream",
        ringbuffer_size: 20
      }
    ]

    # Map that describes how we want data to flow
    # It is formated as such
    # {:child, :output_pad} => {:another_child, :input_pad}

    links = %{
      {:file_src, :output} => {:decoder, :input},
      {:decoder, :output} => {:lame, :input},
      {:lame, :output} => {:converter, :input},
      {:converter, :output} => {:sink, :input}
    }

    spec = %Membrane.Pipeline.Spec{
      children: children,
      links: links
    }

    {{:ok, spec}, %{}}
  end
end
