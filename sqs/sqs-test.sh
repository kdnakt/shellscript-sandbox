#!/bin/bash

if [ "$1" = "" ]; then
  echo "Give me port of endpoint-url"
  exit 1
fi

if [ "$2" = "" ]; then
  echo "Give me queue-name"
  exit 1
fi

echo "creating queue.."
if [ "$2" = *.fifo ]; then
  echo "creating FIFO queue" 
  aws --endpoint-url http://localhost:$1 sqs create-queue --queue-name $2 --attributes FifoQueue=true
else
  echo "creating NORMAL queue"
  aws --endpoint-url http://localhost:$1 sqs create-queue --queue-name $2
fi
echo "created queue."

echo "sending messages .."
sentArray=()
for i in {1..1000}
do
  res=$(aws --endpoint-url http://localhost:$1 sqs send-message --queue-url http://localhost:$1/queue/$2 --message-body "message $i" --message-deduplication-id $i --message-group-id mygroup)
  mid=$(echo $res | jq ".MessageId")
  sentArray+=($mid)
done
echo "sent messages."
echo ""

echo "receiving messages .."
receivedArray=()
for j in {1..1000}
do
  res=$(aws --endpoint-url http://localhost:$1 sqs receive-message --queue-url http://localhost:$1/queue/$2)
  mid=$(echo $res | jq ".Messages[0].MessageId")  
  receivedArray+=($mid)
done
echo "received messages."

echo "deleting queue.."
aws --endpoint-url http://localhost:$1 sqs delete-queue --queue-url http://localhost:$1/queue/$2
echo "deleted queue."


echo "testing results.."
testResult=0
for k in {0..999}
do
  if [ ${sentArray[$k]} != ${receivedArray[$k]} ]; then
    testResult=1
    echo "WRONG ORDER"
    echo ${sentArray[$k]} ${receivedArray[$k]}
    exit 1
  fi
done
if [ $testResult = 0 ]; then
  echo "SUCCESS"
fi
