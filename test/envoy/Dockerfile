FROM envoyproxy/envoy:3122ee8361a3c339c906554f1bb56f68a8e692a9

RUN apt-get update && apt-get install -y software-properties-common curl
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update && apt-get install -y ruby2.4
COPY run.rb /run.rb

CMD ["ruby", "/run.rb"]
