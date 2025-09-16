from web3 import Web3
import getpass
import os
import time

# account that will tx
a_1 = ""
a_1_p = getpass.getpass()
# account that will rx
a_2 = ""

# url of the chains rpc
rpc_url = ""

w3 = Web3(Web3.HTTPProvider(rpc_url))

while True:
    try:
        print("Is chain up?:", w3.is_connected())
        tx = {
            'nonce': w3.eth.get_transaction_count(a_1),
            'to': a_2,
            'value': 1,
            'gas': 2000000,
            'gasPrice': w3.to_wei(50, 'gwei'),
        }
        signed_tx = w3.eth.account.sign_transaction(tx, a_1_p)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        print(tx_hash)
        print(w3.to_hex(tx_hash))
        time.sleep(0.5)
    except UnknownError:
        print("Uknown error")
    except KeyboardInterrupt:
        clean_up()
        sys.exit()
