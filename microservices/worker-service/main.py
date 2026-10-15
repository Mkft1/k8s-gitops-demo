import os
import pika
import psycopg2
import json
import time
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def get_db_connection():
    while True:
        try:
            conn = psycopg2.connect(
                host=os.getenv("POSTGRES_HOST"),
                port=os.getenv("POSTGRES_PORT", "5432"),
                dbname=os.getenv("POSTGRES_DB"),
                user=os.getenv("POSTGRES_USER"),
                password=os.getenv("POSTGRES_PASSWORD")
            )
            return conn
        except Exception as e:
            logging.error(f"DB connection failed: {e}. Retrying in 5s...")
            time.sleep(5)

def get_rabbit_connection():
    creds = pika.PlainCredentials(os.getenv("RABBITMQ_USER"), os.getenv("RABBITMQ_PASSWORD"))
    params = pika.ConnectionParameters(
        host=os.getenv("RABBITMQ_HOST"),
        port=int(os.getenv("RABBITMQ_PORT", "5672")),
        credentials=creds,
        heartbeat=600,
        blocked_connection_timeout=300
    )
    while True:
        try:
            return pika.BlockingConnection(params)
        except Exception as e:
            logging.error(f"RabbitMQ connection failed: {e}. Retrying in 5s...")
            time.sleep(5)

def publish_notification(ch, data):
    ch.basic_publish(
        exchange='',
        routing_key='notifications_queue',
        body=json.dumps({
            "order_id": data['order_id'],
            "item": data['item'],
            "quantity": data['quantity'],
            "status": "processed"
        }),
        properties=pika.BasicProperties(delivery_mode=2)
    )

def callback(ch, method, properties, body):
    try:
        data = json.loads(body)
        logging.info(f"Processing order: {data['order_id']}")

        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute(
                "INSERT INTO orders (id, item, quantity) VALUES (%s, %s, %s) ON CONFLICT (id) DO NOTHING",
                (data['order_id'], data['item'], data['quantity'])
            )
            conn.commit()
            logging.info(f"Saved order {data['order_id']} to database")
            publish_notification(ch, data)
            logging.info(f"Published notification event for order {data['order_id']}")
        except Exception as e:
            logging.error(f"Database error: {e}")
            conn.rollback()
        finally:
            cur.close()
            conn.close()

        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        logging.error(f"Error processing message: {e}")
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

def main():
    logging.info("Worker starting...")
    conn = get_rabbit_connection()
    channel = conn.channel()
    channel.queue_declare(queue='orders_queue', durable=True)
    channel.queue_declare(queue='notifications_queue', durable=True)
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue='orders_queue', on_message_callback=callback)

    logging.info("Waiting for messages. To exit press CTRL+C")
    channel.start_consuming()

if __name__ == "__main__":
    main()
