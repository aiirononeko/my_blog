FROM node:12-slim
EXPOSE 8000

WORKDIR /app
COPY ./package.json .

RUN npm install --save gatsby-plugin-sharp
RUN npm install && npm cache clean --force
COPY . .

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0" ]
