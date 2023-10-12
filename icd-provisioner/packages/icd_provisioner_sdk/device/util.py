import base64
import dataclasses
import datetime
import hashlib
import re
import socket
import time
from typing import List, Tuple

import asyncssh
import cryptography.hazmat
import cryptography.x509
import dns.resolver

from .. import floapi


def device_id_look_up(device_id: str) -> List[str]:
    host_name: str = device_id_to_hostname(device_id)
    res: List[str] = list()

    try:
        item: Tuple[int, int, int, str, Tuple]
        for item in socket.getaddrinfo(f'{host_name}', None, family=socket.AF_INET):
            if item[-1][0] not in res:
                res.append(item[-1][0])
    except Exception:
        pass
    try:
        a: dns.rdtypes.IN.A
        for a in dns.resolver.query(f'{host_name}', rdtype=dns.rdatatype.A).rrset:
            if a.address not in res:
                res.append(a.address)
    except Exception:
        pass

    try:
        item: Tuple[int, int, int, str, Tuple]
        for item in socket.getaddrinfo(f'{host_name}', None, family=socket.AF_INET6):
            if item[-1][0] not in res:
                res.append(item[-1][0])
    except Exception:
        pass
    # try:
    #     aaaa: dns.rdtypes.IN.AAAA
    #     for aaaa in dns.resolver.query(f'{host_name}', rdtype=dns.rdatatype.AAAA).rrset:
    #         if aaaa.address not in res:
    #             res.append(aaaa.address)
    # except Exception:
    #     pass

    return res


def device_id_to_hostname(device_id: str) -> str:
    return f'flo-{device_id}'


def formalize_device_id(device_id: str) -> str:
    return device_id.strip().replace(':', '').replace('-', '').lower()


def is_valid_device_id(candidate: str) -> bool:
    if candidate is not None:
        return re.match('[0-9a-f]{12}$', candidate) is not None
    else:
        return candidate is not None


def make_device_register_request_data(device_id: str, sku: str = '') -> floapi.RegisterRequestData:
    ws_server_cert: WebSocketServerCertificate = make_device_websocket_server_certificate()

    return floapi.RegisterRequestData(
        device_id=device_id,
        icd_login_token=hashlib.sha1((str(time.time()) + device_id).encode()).hexdigest(),
        sku=sku,
        ssh_private_key=base64.standard_b64encode(
            asyncssh.generate_private_key('ssh-rsa').export_private_key(format_name='pkcs1-pem')).decode(),
        websocket_cert=base64.standard_b64encode(ws_server_cert.certificate).decode(),
        websocket_key=base64.standard_b64encode(ws_server_cert.private_key).decode(),
        wifi_ssid=f'Flo-{device_id[-4:]}',
        wifi_password='',
        wlan_mac_id=':'.join(device_id[i:i+2] for i in range(0, len(device_id), 2)))


def make_device_websocket_server_certificate() -> 'WebSocketServerCertificate':
    private_key: cryptography.hazmat.primitives.asymmetric.rsa.RSAPrivateKeyWithSerialization = \
        cryptography.hazmat.primitives.asymmetric.rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=cryptography.hazmat.backends.default_backend())

    subject: cryptography.x509.Name
    issuer: cryptography.x509.Name
    subject = issuer = cryptography.x509.Name([
        cryptography.x509.NameAttribute(cryptography.x509.NameOID.COUNTRY_NAME, 'US'),
        cryptography.x509.NameAttribute(cryptography.x509.NameOID.STATE_OR_PROVINCE_NAME, 'CA'),
        cryptography.x509.NameAttribute(cryptography.x509.NameOID.LOCALITY_NAME, 'Los Angeles'),
        cryptography.x509.NameAttribute(cryptography.x509.NameOID.ORGANIZATION_NAME, 'Flo Technologies, Inc'),
        cryptography.x509.NameAttribute(cryptography.x509.NameOID.ORGANIZATIONAL_UNIT_NAME, 'Engineering'),
        cryptography.x509.NameAttribute(cryptography.x509.NameOID.COMMON_NAME, 'flodevice'),
    ])
    cert: cryptography.x509.Certificate = cryptography.x509.CertificateBuilder() \
        .subject_name(subject) \
        .issuer_name(issuer) \
        .public_key(private_key.public_key()) \
        .serial_number(cryptography.x509.random_serial_number()) \
        .not_valid_before(datetime.datetime.utcnow()) \
        .not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=356*10)) \
        .sign(private_key, cryptography.hazmat.primitives.hashes.SHA256(),
              cryptography.hazmat.backends.default_backend())

    return WebSocketServerCertificate(
        certificate=cert.public_bytes(cryptography.hazmat.primitives.serialization.Encoding.PEM),
        private_key=private_key.private_bytes(
            encoding=cryptography.hazmat.primitives.serialization.Encoding.PEM,
            format=cryptography.hazmat.primitives.serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=cryptography.hazmat.primitives.serialization.NoEncryption()))


@dataclasses.dataclass
class WebSocketServerCertificate:
    certificate: bytes
    private_key: bytes
