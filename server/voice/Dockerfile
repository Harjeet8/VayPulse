FROM node:22-slim
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY index.mjs policy.mjs ./
USER node
CMD ["node", "index.mjs"]
