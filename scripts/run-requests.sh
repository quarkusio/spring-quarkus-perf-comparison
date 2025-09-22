#!/bin/bash -x

curl http://localhost:8080/fruits
curl http://localhost:8080/fruits/Apple
curl http://localhost:8080/fruits/Pineapple
curl -d "@fruit.json" -X POST http://localhost:8080/fruits
curl http://localhost:8080/fruits
curl http://localhost:8080/fruits/Pineapple