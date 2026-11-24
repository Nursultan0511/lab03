#!/bin/bash
# Мини chaos: 2 минутын тест, 30 с дээр сервер crash, 10 с-ийн дараа дахин асаана.
cd "$(dirname "$0")"
pkill -f "node server.js"; sleep 1
node server.js > results/server.log 2>&1 &
SRV=$!
until curl -s -m 1 -o /dev/null -X POST localhost:3000/cart/add; do sleep 0.2; done
echo "сервер бэлэн, k6 эхэллээ ($(date +%T))"
k6 run --duration 2m slo-test.js > results/chaos.txt 2>&1 &
K6=$!
sleep 30
CRASH=$(date +%s.%N)
kill -INT $SRV; wait $SRV 2>/dev/null
echo "CRASH: сервер зогслоо ($(date +%T))"
sleep 10
node server.js >> results/server.log 2>&1 &
SRV=$!
until curl -s -m 1 -o /dev/null -X POST localhost:3000/cart/add; do sleep 0.1; done
READY=$(date +%s.%N)
MTTR=$(awk -v a="$CRASH" -v b="$READY" 'BEGIN{printf "%.1f", b-a}')
echo "СЭРГЭЛТ: сервер дахин бэлэн боллоо ($(date +%T)), MTTR = ${MTTR} с"
echo "$MTTR" > results/chaos-mttr.txt
wait $K6; EC=$?; echo "k6 exit code: $EC"; echo "exit code: $EC" >> results/chaos.txt
kill -INT $SRV 2>/dev/null
