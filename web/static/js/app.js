import {Socket} from "deps/phoenix/web/static/js/phoenix"
import "deps/phoenix_html/web/static/js/phoenix_html"

$(() => {
  let camera_id = window.Evercam.Camera.id;

  let socket = new Socket("ws://localhost:4000/ws")

  socket.connect();

  let chan = socket.channel(`cameras:${camera_id}`, {})

  chan.join()

  chan.on("snapshot-taken", payload => {
    $("#live-player-image").attr("src", "data:image/jpeg;base64," + payload.image);
  })
})
