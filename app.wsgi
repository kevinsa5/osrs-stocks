import sys
sys.path.insert(0, "/root/osrs-stocks")

import logging, sys
logging.basicConfig(stream=sys.stderr)


from flask_app import app as application
