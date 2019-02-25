all: build

build:
	docker build -t bydavy/ws .

run: kill
	docker run -h ws -p 6001:6001 -p 60000-60010:60000-60010/udp --rm -it bydavy/ws

ssh:
	mosh --no-init --ssh="ssh -o StrictHostKeyChecking=no -p 6001" root@localhost -- tmux new-session -AD -s main

kill:
	docker kill ws | true
