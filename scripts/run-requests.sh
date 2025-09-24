#!/bin/bash -x

curl -i http://localhost:8080/fruits
echo
curl -i http://localhost:8080/fruits/Apple
echo
curl -i http://localhost:8080/fruits/Pineapple
echo
curl -i -d "@fruit.json" -H "Content-Type: application/json" -X POST http://localhost:8080/fruits
echo
curl -i http://localhost:8080/fruits
echo
curl -i http://localhost:8080/fruits/Pineapple
echo