use FieldPunning

defmodule LiveBeatsWeb.PlayerLive do
  use LiveBeatsWeb, {:live_view, container: {:div, []}}

  alias LiveBeats.{Accounts, MediaLibrary}
  alias LiveBeats.MediaLibrary.Song
  alias LiveBeatsWeb.Presence

  on_mount({LiveBeatsWeb.UserAuth, :current_user})

  def mount(_params, _session, socket) do
    %{@:current_user} = socket.assigns

    if connected?(socket) do
      Accounts.subscribe(current_user.id)
    end

    socket =
      socket
      |> assign(
        song: nil,
        playing: false,
        profile: nil,
        current_user_id: current_user.id,
        own_profile?: false
      )
      |> switch_profile(current_user.active_profile_user_id)

    {:ok, socket, layout: false, temporary_assigns: []}
  end

  defp switch_profile(socket, nil) do
    current_user = Accounts.update_active_profile(socket.assigns.current_user, nil)

    if profile = connected?(socket) and socket.assigns.profile do
      Presence.untrack_profile_user(profile, current_user.id)
    end

    socket
    |> assign([@:current_user])
    |> assign_profile(nil)
  end

  defp switch_profile(socket, profile_user_id) do
    %{@:current_user} = socket.assigns
    profile = get_profile(profile_user_id)

    if profile && connected?(socket) do
      current_user = Accounts.update_active_profile(current_user, profile.user_id)
      # untrack last profile the user was listening
      if socket.assigns.profile do
        Presence.untrack_profile_user(socket.assigns.profile, current_user.id)
      end

      Presence.track_profile_user(profile, current_user.id)
      send(self(), :play_current)

      socket
      |> assign([@:current_user])
      |> assign_profile(profile)
    else
      assign_profile(socket, nil)
    end
  end

  defp assign_profile(socket, profile)
       when is_struct(profile, MediaLibrary.Profile) or is_nil(profile) do
    %{@:current_user, profile: prev_profile} = socket.assigns

    profile_changed? = profile_changed?(prev_profile, profile)

    if connected?(socket) and profile_changed? do
      prev_profile && MediaLibrary.unsubscribe_to_profile(prev_profile)
      profile && MediaLibrary.subscribe_to_profile(profile)
    end

    assign(socket, [
      @:profile,
      own_profile?: !!profile && MediaLibrary.owns_profile?(current_user, profile)
    ])
  end

  def handle_event("play_pause", _, socket) do
    %{@:song, @:playing, @:current_user} = socket.assigns
    song = MediaLibrary.get_song!(song.id)

    cond do
      (song && playing) and MediaLibrary.can_control_playback?(current_user, song) ->
        MediaLibrary.pause_song(song)
        {:noreply, assign(socket, playing: false)}

      song && MediaLibrary.can_control_playback?(current_user, song) ->
        MediaLibrary.play_song(song)
        {:noreply, assign(socket, playing: true)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("switch_profile", %{@"user_id"}, socket) do
    {:noreply, switch_profile(socket, user_id)}
  end

  def handle_event("next_song", _, socket) do
    %{@:song, @:current_user} = socket.assigns

    if song && MediaLibrary.can_control_playback?(current_user, song) do
      MediaLibrary.play_next_song(socket.assigns.profile)
    end

    {:noreply, socket}
  end

  def handle_event("prev_song", _, socket) do
    %{@:song, @:current_user} = socket.assigns

    if song && MediaLibrary.can_control_playback?(current_user, song) do
      MediaLibrary.play_prev_song(socket.assigns.profile)
    end

    {:noreply, socket}
  end

  def handle_event("next_song_auto", _, socket) do
    if socket.assigns.song do
      MediaLibrary.play_next_song_auto(socket.assigns.profile)
    end

    {:noreply, socket}
  end

  def handle_info(:play_current, socket) do
    {:noreply, play_current_song(socket)}
  end

  def handle_info(
        {Accounts, %Accounts.Events.ActiveProfileChanged{new_profile_user_id: user_id}},
        socket
      ) do
    if user_id do
      {:noreply, assign(socket, profile: get_profile(user_id))}
    else
      {:noreply, socket |> assign_profile(nil) |> stop_song()}
    end
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.PublicProfileUpdated{} = update}, socket) do
    %{@:current_user} = socket.assigns

    if update.profile.user_id == socket.assigns.current_user.id do
      Presence.untrack_profile_user(socket.assigns.profile, current_user.id)
      Presence.track_profile_user(update.profile, current_user.id)
    end

    {:noreply, assign_profile(socket, update.profile)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.Pause{}}, socket) do
    {:noreply, push_pause(socket)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.Play{} = play}, socket) do
    {:noreply, play_song(socket, play.song, play.elapsed)}
  end

  def handle_info({MediaLibrary, %MediaLibrary.Events.SongDeleted{@:song}}, socket) do
    if socket.assigns.song && socket.assigns.song.id == song.id do
      {:noreply, stop_song(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({MediaLibrary, _}, socket), do: {:noreply, socket}

  defp play_song(socket, %Song{} = song, elapsed) do
    socket
    |> push_play(song, elapsed)
    |> assign([@:song, playing: true, page_title: song_title(song)])
  end

  defp stop_song(socket) do
    socket
    |> push_event("stop", %{})
    |> assign(song: nil, playing: false, page_title: "Listing Songs")
  end

  defp song_title(%{@:artist, @:title}) do
    "#{title} - #{artist} (Now Playing)"
  end

  defp play_current_song(socket) do
    song = MediaLibrary.get_current_active_song(socket.assigns.profile)

    cond do
      song && MediaLibrary.playing?(song) ->
        play_song(socket, song, MediaLibrary.elapsed_playback(song))

      song && MediaLibrary.paused?(song) ->
        assign(socket, [@:song, playing: false])

      true ->
        socket
    end
  end

  defp push_play(socket, %Song{} = song, elapsed) do
    token =
      Phoenix.Token.encrypt(socket.endpoint, "file", %{
        vsn: 1,
        ip: to_string(song.server_ip),
        size: song.mp3_filesize,
        uuid: song.mp3_filename
      })

    push_event(socket, "play", %{
      @:elapsed,
      @:token,
      artist: song.artist,
      title: song.title,
      paused: Song.paused?(song),
      duration: song.duration,
      url: song.mp3_url
    })
  end

  defp push_pause(socket) do
    socket
    |> push_event("pause", %{})
    |> assign(playing: false)
  end

  defp js_play_pause(own_profile?) do
    if own_profile? do
      JS.push("play_pause")
      |> JS.dispatch("js:play_pause", to: "#audio-player")
    else
      show_modal("not-authorized")
    end
  end

  defp js_prev(own_profile?) do
    if own_profile? do
      JS.push("prev_song")
    else
      show_modal("not-authorized")
    end
  end

  defp js_next(own_profile?) do
    if own_profile? do
      JS.push("next_song")
    else
      show_modal("not-authorized")
    end
  end

  defp js_listen_now(js \\ %JS{}) do
    JS.dispatch(js, "js:listen_now", to: "#audio-player")
  end

  defp get_profile(user_id) do
    user_id && Accounts.get_user!(user_id) |> MediaLibrary.get_profile!()
  end

  defp profile_changed?(nil = _prev_profile, nil = _new_profile), do: false
  defp profile_changed?(nil = _prev_profile, %MediaLibrary.Profile{}), do: true
  defp profile_changed?(%MediaLibrary.Profile{}, nil = _new_profile), do: true

  defp profile_changed?(%MediaLibrary.Profile{} = prev, %MediaLibrary.Profile{} = new),
    do: prev.user_id != new.user_id
end
