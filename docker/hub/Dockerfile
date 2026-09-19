FROM nginx:alpine

COPY docker/hub/default.conf /etc/nginx/conf.d/default.conf
COPY docker/hub/index.html /usr/share/nginx/html/index.html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
