FROM public.ecr.aws/docker/library/node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy the application source code
COPY index.js .

EXPOSE 80
CMD [ "node", "index.js" ]
