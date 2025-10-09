CONTAINER_NAME ?= ollama-gpu
IMAGE ?= docker.io/ollama/ollama:latest
PORT ?= 11434

.PHONY: create start stop status logs clean

create:
	mkdir -p ~/.config/systemd/user
	docker create \
	  --name $(CONTAINER_NAME) \
	  --gpus all \
	  --restart unless-stopped \
	  -p $(PORT):$(PORT) \
	  $(IMAGE)
	cat > ~/.config/systemd/user/$(CONTAINER_NAME).service <<EOF
[Unit]
Description=Docker container $(CONTAINER_NAME)
After=default.target

[Service]
Type=simple
ExecStart=docker start -a $(CONTAINER_NAME)
ExecStop=docker stop $(CONTAINER_NAME)
Restart=always

[Install]
WantedBy=default.target
EOF
	systemctl --user daemon-reload

start:
	systemctl --user enable --now $(CONTAINER_NAME).service

stop:
	systemctl --user stop $(CONTAINER_NAME).service

status:
	systemctl --user status $(CONTAINER_NAME).service

logs:
	docker logs -f $(CONTAINER_NAME)

clean:
	systemctl --user stop $(CONTAINER_NAME).service || true
	systemctl --user disable $(CONTAINER_NAME).service || true
	rm -f ~/.config/systemd/user/$(CONTAINER_NAME).service
	docker rm -f $(CONTAINER_NAME) || true
	systemctl --user daemon-reload
