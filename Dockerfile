# Use a small, official Node.js image
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# A simple Node.js web server
COPY . .
RUN echo 'const http = require("http"); \
const server = http.createServer((req, res) => { \
  res.writeHead(200, { "Content-Type": "text/plain" }); \
  res.end("Hello from my EKS App!\\n"); \
}); \
server.listen(80, () => { \
  console.log("Server running on port 80"); \
});' > index.js

EXPOSE 80
CMD [ "node", "index.js" ]