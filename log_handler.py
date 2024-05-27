import logging
from logging.handlers import RotatingFileHandler
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization

logger = logging.getLogger('5651_logger')
logger.setLevel(logging.INFO)
handler = RotatingFileHandler('/usr/local/captive-portal/5651_logs.log', maxBytes=2000000, backupCount=10)
formatter = logging.Formatter('%(asctime)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

def log_event(message):
    logger.info(message)

def sign_log_file(private_key_path, log_file_path, signature_path):
    with open(log_file_path, 'rb') as log_file:
        log_data = log_file.read()

    with open(private_key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
        )

    signature = private_key.sign(
        log_data,
        padding.PKCS1v15(),
        hashes.SHA256()
    )

    with open(signature_path, 'wb') as sig_file:
        sig_file.write(signature)
