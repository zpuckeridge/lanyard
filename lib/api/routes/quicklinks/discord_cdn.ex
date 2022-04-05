defmodule Lanyard.Api.Quicklinks.DiscordCdn do
  alias Lanyard.Api.Util

  import Plug.Conn

  @discord_cdn "https://cdn.discordapp.com"

  def proxy_image(conn) do
    [user_id, file_type] =
      conn.request_path
      |> String.split("/")
      |> Enum.at(1)
      |> String.split(".")

    presence = Lanyard.Presence.get_pretty_presence(user_id)

    case presence do
      {:ok, p} ->
        {:ok, %HTTPoison.Response{body: b, headers: h, status_code: _status_code}} =
          get_proxied_avatar(
            user_id,
            p.discord_user.avatar,
            p.discord_user.discriminator,
            file_type
          )

        {_, content_type} =
          h
          |> List.keyfind("Content-Type", 0)

        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, b)

      error ->
        Util.respond(conn, error)
    end
  end

  defp get_proxied_avatar(id, avatar, _discriminator, file_type) when is_binary(avatar) do
    constructed_cdn_url = "#{@discord_cdn}/avatars/#{id}/#{avatar}.#{file_type}?size=1024"

    HTTPoison.get(constructed_cdn_url)
  end

  defp get_proxied_avatar(_id, avatar, discriminator, _file_type) when is_nil(avatar) do
    mod = Integer.mod(String.to_integer(discriminator), 5)
    HTTPoison.get("#{@discord_cdn}/embed/avatars/#{mod}.png")
  end
end