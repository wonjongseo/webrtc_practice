import http from "http";
import { Server } from "socket.io";
import express from "express";
import path from "path";
const __dirname = path.resolve();
const app = express();

app.set("view engine", "pug");
app.set("views", __dirname + "/views");

app.use("/public", express.static(__dirname + "/public"));
app.get("/", (_, res) => res.render("home"));
// app.get("/*", (req, res) => res.redirect("/"));

const handleListen = () => console.log(`Listening on http://localhost:3000`);
// app.listen(3000, handleListen);
const httpServer = http.createServer(app);
const wsServer = new Server(httpServer, {
  // cors: {
  //   origin: "*", // 개발 중에는 모든 origin 허용
  //   methods: ["GET", "POST"],
  // },
});

function publicRooms() {
  const {
    sockets: {
      adapter: { sids, rooms },
    },
  } = wsServer;
  const publicRooms = [];
  rooms.forEach((_, key) => {
    if (sids.get(key) === undefined) {
      publicRooms.push(key);
    }
  });
  return publicRooms;
}

wsServer.on("connection", (socket) => {
  socket["nickname"] = "Anon";
  socket.onAny((event) => {
    console.log(`Socket Event: ${event}`);
  });
  socket.on("enter_room", (roomName, done) => {
    socket.join(roomName);
    done();
    socket.to(roomName).emit("welcome", socket.nickname);
    wsServer.sockets.emit("room_change", publicRooms());
  });
  socket.on("disconnecting", () => {
    socket.rooms.forEach((room) => socket.to(room).emit("bye", socket.nickname));
  });
  socket.on("disconnect", () => {
    wsServer.sockets.emit("room_change", publicRooms());
  });
  socket.on("new_message", (payload, done) => {
    console.log("payload: ", payload);
    console.log("socket.nickname: ", socket.nickname);
    socket.to(payload.room).emit("new_message", `${socket.nickname} : ${payload.msg}`);
    done();
  });
  socket.on("nickname", (payload) => (socket["nickname"] = payload["nickname"]));
});

httpServer.listen(3000, handleListen);
