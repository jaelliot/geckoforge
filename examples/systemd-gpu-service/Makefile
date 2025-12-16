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
	@{ \
		echo '[Unit]'; \
		echo 'Description=Docker container $(CONTAINER_NAME)'; \
		echo 'After=default.target'; \
		echo ''; \
		echo '[Service]'; \
		echo 'Type=simple'; \
		echo 'ExecStart=docker start -a $(CONTAINER_NAME)'; \
		echo 'ExecStop=docker stop $(CONTAINER_NAME)'; \
		echo 'Restart=always'; \
		echo ''; \
		echo '[Install]'; \
		echo 'WantedBy=default.target'; \
	} > ~/.config/systemd/user/$(CONTAINER_NAME).service
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
