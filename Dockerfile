FROM node:20-alpine

WORKDIR /app

COPY backend/package*.json ./backend/
WORKDIR /app/backend
RUN npm install --omit=dev

WORKDIR /app
COPY backend ./backend
COPY frontend ./frontend

EXPOSE 5000

CMD ["node", "backend/server.js"]
