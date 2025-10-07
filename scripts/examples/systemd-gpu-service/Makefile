CONTAINER_NAME ?= ollama-gpu
IMAGE ?= docker.io/ollama/ollama:latest
PORT ?= 11434

.PHONY: create start stop status logs clean

create:
	podman create \
	  --name $(CONTAINER_NAME) \
	  --device nvidia.com/gpu=all \
	  -p $(PORT):$(PORT) \
	  $(IMAGE)
	podman generate systemd --new --name $(CONTAINER_NAME) --files \
	  --restart-policy=always \
	  > ~/.config/systemd/user/$(CONTAINER_NAME).service
	systemctl --user daemon-reload

start:
	systemctl --user enable --now $(CONTAINER_NAME).service

stop:
	systemctl --user stop $(CONTAINER_NAME).service

status:
	systemctl --user status $(CONTAINER_NAME).service

logs:
	podman logs -f $(CONTAINER_NAME)

clean:
	systemctl --user stop $(CONTAINER_NAME).service || true
	systemctl --user disable $(CONTAINER_NAME).service || true
	rm -f ~/.config/systemd/user/$(CONTAINER_NAME).service
	podman rm -f $(CONTAINER_NAME) || true
	systemctl --user daemon-reload
