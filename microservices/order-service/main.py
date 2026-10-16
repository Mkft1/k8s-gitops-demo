import os
import json
import uuid
import pika
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Order Service")

class OrderRequest(BaseModel):
    item: str
    quantity: int

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "orders_app")
RABBITMQ_PASS = os.getenv("RABBITMQ_PASSWORD", "rabbit_secret_456")

def publish_to_rabbitmq(message: dict):
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        connection_attempts=3,
        retry_delay=2
    )
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    channel.queue_declare(queue='orders_queue', durable=True)
    channel.basic_publish(
        exchange='',
        routing_key='orders_queue',
        body=json.dumps(message),
        properties=pika.BasicProperties(delivery_mode=2)
    )
    connection.close()

@app.post("/api/orders", status_code=201)
def create_order(order: OrderRequest):
    if order.quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be greater than 0")
    
    order_id = str(uuid.uuid4())
    message = {
        "order_id": order_id,
        "item": order.item,
        "quantity": order.quantity
    }
    
    try:
        publish_to_rabbitmq(message)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Failed to publish to RabbitMQ: {str(e)}")
        
    return {"message": "Order accepted", "order_id": order_id}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
# CI/CD pipeline test
# CI/CD fix
# Trigger CI pipeline
