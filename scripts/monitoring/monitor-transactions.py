import json
import requests
from datetime import datetime
import time

def send_to_logstash(transaction_data):
    headers = {'Content-Type': 'application/json'}
    data = {
        '@timestamp': datetime.utcnow().isoformat(),
        'type': 'transaction',
        'data': transaction_data
    }
    
    try:
        response = requests.post('http://localhost:5044', 
                               headers=headers,
                               data=json.dumps(data))
        return response.status_code == 200
    except Exception as e:
        print(f"Error sending data to Logstash: {e}")
        return False

def monitor_blockchain():
    while True:
        try:
            # Aquí irá la lógica para obtener las transacciones de la blockchain
            # Por ahora solo es un ejemplo
            transaction = {
                'type': 'transfer',
                'bottle_id': '123',
                'from': 'account1',
                'to': 'account2',
                'timestamp': datetime.utcnow().isoformat()
            }
            
            if send_to_logstash(transaction):
                print(f"Transaction sent successfully: {transaction['type']}")
            
            time.sleep(1)  # Esperar 1 segundo entre lecturas
            
        except Exception as e:
            print(f"Error monitoring blockchain: {e}")
            time.sleep(5)  # Esperar 5 segundos antes de reintentar

if __name__ == "__main__":
    monitor_blockchain()
