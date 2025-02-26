// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import {Socket} from "phoenix"

// And connect to the path in "lib/dice_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.
// Cast window as any so TS doesn't complain about the userToken prop
let socket = new Socket("/socket", {params: {token: (window as any).userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/dice_web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/dice_web/templates/layout/app.html.heex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/dice_web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

const url = new URL(window.location.href);
const id = url.pathname.split("/").pop()

let channel = socket.channel(`room:${id}`, {})
let chatInput = document.querySelector<HTMLInputElement>("#chat-input")
let messagesContainer = document.querySelector<HTMLDivElement>("#messages")
let logContainer = document.querySelector<HTMLDivElement>("#logContainer")


const pingButton = document.querySelector("#ping")

pingButton?.addEventListener("click", () => {
  const res = channel.push("ping", {text: "This is a response"})
  channel.push("roll_dice", {})
  
  console.log(res)
})

chatInput?.addEventListener("keydown", (e: KeyboardEvent) => {
  if (e.key === "Enter") {
    channel.push("new_msg_created", {body: chatInput.value})
    chatInput.value = ""
  }
})

channel.on("new_msg_send", (payload) => {
  let message = document.createElement("p")
  message.innerText = `${Date()} - ${payload.body}`

  messagesContainer?.appendChild(message)
})

channel.on("player_joined", (payload) => {
  console.log(payload)
})  

channel.on("player-rolled", (payload) => {
  const log = document.createElement('p')
  log.innerText = `Player ${payload.player_id} has rolled.`
  logContainer?.append(log)
})  

channel.on("player-bid", (payload) => {
  console.log(`Player ${payload.player_id} has bid. \n ${payload.amount} ${payload.die_value}(s)`)
})  

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
