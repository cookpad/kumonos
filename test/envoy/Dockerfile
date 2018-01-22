FROM envoyproxy/envoy:5d14c9fc9bb9233656e544cd4e69e5397f98eca9

RUN apt-get update && apt-get install -y software-properties-common curl
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update && apt-get install -y ruby2.4
COPY run.rb /run.rb

CMD ["ruby", "/run.rb"]
