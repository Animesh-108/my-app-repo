const http = require("http");

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from index.js! This is the v1 baseline.\n");
});

server.listen(80, () => {
  console.log("Server running on port 80");
});
