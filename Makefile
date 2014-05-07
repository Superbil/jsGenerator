JSONS += json/*
OUTPUT = output

test:
	@for f in $(JSONS); do \
		echo "Building $$f" ;\
		./jsg.ls -o $(OUTPUT) -j $$f ;\
	done;
