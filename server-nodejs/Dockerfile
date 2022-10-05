ARG ARCH=
FROM ${ARCH}node
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]


# docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 -t skyface753/skyreal .